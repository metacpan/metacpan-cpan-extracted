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

has app       => ( required => 1 );    # ConsumerOf ['Pcore::App']
has namespace => ( required => 1 );    # HashRef

has map        => ( init_arg => undef );    # HashRef, router path -> class name
has api_path   => ( init_arg => undef );
has path_ctrl  => ( init_arg => undef );    # HashRef, router path -> sigleton cache
has class_ctrl => ( init_arg => undef );    # HashRef, class name -> sigleton cache
has path_re    => ( init_arg => undef );

sub init ( $self ) {
    $self->{namespace} //= ref $self->{app};

    my $index_class = "$self->{namespace}::Index";

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
            path => $route,
        } );

        die qq[Controller path "$route" is not unique] if exists $self->{path_ctrl}->{$route};

        $map->{ $route eq '/' ? '/' : "$route/" } = $class;

        $self->{class_ctrl}->{$class} = $self->{path_ctrl}->{$route} = $obj;

        # api controller
        if ( $class->does('Pcore::App::Controller::API') ) {
            $self->{api_path} = $obj->{path};
        }
    }

    $self->{map} = $map;

    my $re = '\A(' . ( join '|', map {quotemeta} reverse sort { length $a <=> length $b } keys $map->%* ) . ')(.*)\z';

    $self->{path_re} = qr/$re/sm;

    return;
}

sub run ( $self, $req ) {

    # rebless request
    $req = bless $req, 'Pcore::App::Router::Request';

    my $env = $req->{env};

    my $map = $self->{map};

    my $path = P->path("/$env->{PATH_INFO}");

    $path .= '/' if $path ne '/' && !defined $path->{filename};

    if ( $path =~ $self->{path_re} ) {

        # extend HTTP request
        $req->{app}  = $self->{app};
        $req->{path} = P->path($2) if $2 ne $EMPTY;

        my $ctrl = $self->{class_ctrl}->{ $map->{$1} };

        return $ctrl->run($req);
    }
    else {
        return 404;
    }
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
