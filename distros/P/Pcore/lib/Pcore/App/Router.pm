package Pcore::App::Router;

use Pcore -class;
use Pcore::App::Router::Request;

use overload    #
  '&{}' => sub ( $self, @ ) {
    return sub {
        return $self->run(@_);
    };
  },
  fallback => undef;

has app   => ( required => 1 );    # ConsumerOf ['Pcore::App']
has hosts => ( required => 1 );    # HashRef

has map           => ();           # HashRef, router path -> class name
has host_re       => ();           # HashRef, router path -> class name
has host_api_path => ();           # HashRef

has path_ctrl  => ();              # HashRef, router path -> sigleton cache
has class_ctrl => ();              # HashRef, class name -> sigleton cache

sub BUILD ( $self, $args ) {

    # init hosts
    $self->{hosts} //= {};

    # add default router
    $self->{hosts}->{'*'} = ref $self->{app} if !keys $self->{hosts}->%*;

    return;
}

sub init ($self) {
    my $map;

    for my $host ( keys $self->{hosts}->%* ) {
        my $ns = $self->{hosts}->{$host} // ref $self->{app};

        $map->{$host} = $self->_get_host_map( $host, $ns );
    }

    $self->{map} = $map;

    return;
}

sub _get_host_map ( $self, $host, $ns ) {
    my $index_class = "${ns}::Index";

    my $index_path = $index_class =~ s[::][/]smgr;

    my $index_module = ( $index_class =~ s[::][/]smgr ) . '.pm';

    # related to $index_path module path -> full module path mapping
    my $modules = {};

    # scan %INC
    for my $module ( keys %INC ) {
        next if substr( $module, -3 ) ne '.pm';

        # index controller
        if ( $module eq $index_module ) {
            $modules->{$module} = undef;
        }

        # non-index controller
        elsif ( index( $module, "$index_path/" ) == 0 ) {
            $modules->{$module} = undef;
        }
    }

    # scan filesystem, find and preload controllers
    for my $path ( grep { !ref } @INC ) {

        # index controller
        if ( -f "$path/$index_module" ) {
            $modules->{$index_module} = undef;
        }

        for my $file ( ( P->path("$path/$index_path")->read_dir( max_depth => 0, is_dir => 0 ) // [] )->@* ) {
            $modules->{"$index_path/$file"} = undef if $file =~ /[.]pm\z/sm;
        }
    }

    my $map;

    for my $module ( sort keys $modules->%* ) {
        my $class = P->class->load($module);

        die qq["$class" is not a consumer of "Pcore::App::Controller"] if !$class->can('does') || !$class->does('Pcore::App::Controller');

        # generate route path
        my $route = lc( $class =~ s[\A$index_class:*][/]smr );

        $route =~ s[::][/]smg;

        my $obj = $class->new( {
            app  => $self->{app},
            host => $host,
            path => $route,
        } );

        die qq[Controller path "$route" is not unique] if exists $self->{path_ctrl}->{$host}->{$route};

        $map->{ $route eq '/' ? '/' : "$route/" } = $class;

        $self->{class_ctrl}->{$class} = $self->{path_ctrl}->{$host}->{$route} = $obj;

        if ( $class->does('Pcore::App::Controller::API') ) {

            # api controller
            $self->{host_api_path}->{$host} = $obj->{path};
        }
    }

    my $re = '\A(' . ( join '|', map {quotemeta} reverse sort { length $a <=> length $b } keys $map->%* ) . ')(.*)\z';
    $self->{host_re}->{$host} = qr/$re/sm;

    return $map;
}

sub run ( $self, $req ) {

    # rebless request
    $req = bless $req, 'Pcore::App::Router::Request';

    my $env = $req->{env};

    my $host = $env->{HTTP_HOST} // '*';

    my $map = $self->{map};

    if ( !exists $map->{$host} ) {

        # use default host, if possible
        if ( exists $map->{'*'} ) {
            $host = '*';
        }

        # unknown HTTP host
        else {
            return 421;    # 421 - misdirected request
        }
    }

    my $path = P->path("/$env->{PATH_INFO}");

    $path .= '/' if $path ne '/' && !defined $path->{filename};

    if ( $path =~ $self->{host_re}->{$host} ) {

        # extend HTTP request
        $req->{app}  = $self->{app};
        $req->{host} = $host;
        $req->{path} = P->path($2) if $2 ne $EMPTY;

        my $ctrl = $self->{class_ctrl}->{ $map->{$host}->{$1} };

        return $ctrl->run($req);
    }
    else {
        return 404;
    }
}

sub get_host_api_path ( $self, $host ) {
    return if !$self->{host_api_path};

    return $self->{host_api_path}->{$host};
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Router

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
