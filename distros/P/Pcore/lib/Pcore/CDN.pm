package Pcore::CDN;

use Pcore -class;
use Pcore::Util::Scalar qw[weaken is_ref is_plain_arrayref is_plain_coderef];
use Pcore::Util::File::Tree;
use overload '&{}' => sub ( $self, @ ) {
    sub { $self->get_url(@_) }
  },
  fallback => 1;

has native_cdn => ( init_arg => undef );
has resources  => ( init_arg => undef );    # HashRef[CodeRef]
has buckets    => ( init_arg => undef );
has locations  => ( init_arg => undef );

around new => sub ( $orig, $self, $args ) {
    $self = $self->$orig;

    $self->{native_cdn} = $args->{native_cdn};

    # resources
    if ( my $resources = $args->{resources} ) {
        for my $lib ( $resources->@* ) {
            P->class->load( $lib =~ s/-/::/smgr );

            my $cdn_resources_path = $ENV->dist($lib)->{share_dir} . '/cdn.perl';

            if ( -f $cdn_resources_path ) {
                my $cdn_resources = P->cfg->read($cdn_resources_path);

                $self->{resources}->@{ keys $cdn_resources->%* } = values $cdn_resources->%*;
            }
        }
    }

    # buckets
    while ( my ( $name, $cfg ) = each $args->{buckets}->%* ) {
        $self->{buckets}->{$name} = P->class->load( $cfg->{type}, ns => 'Pcore::CDN::Bucket' )->new($cfg);
    }

    # locations
    $self->{locations} = $args->{locations};

    return $self;
};

sub bucket ( $self, $name ) { return $self->{bucket}->{$name} }

sub get_url ( $self, $path ) {
    my $location_name;

    # extract bucket
    if ( substr( $path, 0, 1 ) eq '/' ) {
        $path = "$path" if is_ref $path;

        $location_name = substr $path, 0, index( $path, '/', 1 ) + 1, $EMPTY;
        substr $location_name, 0,  1, $EMPTY;
        substr $location_name, -1, 1, $EMPTY;
    }
    else {
        die 'Location is not specified';
    }

    my $location = $self->{locations}->{$location_name};

    die qq[Location "$location_name" is not defined] if !defined $location;

    my $bucket = $self->{buckets}->{ $location->{bucket} };

    die qq[Bucket "$location->{bucket}" is not defined] if !defined $bucket;

    return $bucket->get_url("$location->{path}/$path");
}

sub get_resources ( $self, @resources ) {
    my @res;

    for my $name (@resources) {
        my %args;

        if ( is_plain_arrayref $name) {
            ( $name, %args ) = $name->@*;
        }

        my $resource = $self->{resources}->{$name};

        die qq[CDN resource "$name" is not defined] if !defined $resource;

        push @res, $resource->( $self, $args{native_cdn} // $self->{native_cdn}, \%args );
    }

    return \@res;
}

sub get_resource_root ( $self, $name, %args ) {
    my $resource = $self->{resources}->{$name};

    die qq[CDN resource "$name" is not defined] if !defined $resource;

    return scalar $resource->( $self, $args{native_cdn} // $self->{native_cdn}, \%args );
}

sub get_script_tag ( $self, $url ) { return qq[<script src="$url" integrity="" crossorigin="anonymous"></script>] }

sub get_css_tag ( $self, $url ) { return qq[<link rel="stylesheet" href="$url" integrity="" crossorigin="anonymous" />] }

sub upload ( $self, $path, $data, @args ) {
    my $location_name;

    # extract bucket
    if ( substr( $path, 0, 1 ) eq '/' ) {
        $path = "$path" if is_ref $path;

        $location_name = substr $path, 0, index( $path, '/', 1 ) + 1, $EMPTY;
        substr $location_name, 0,  1, $EMPTY;
        substr $location_name, -1, 1, $EMPTY;
    }
    else {
        die 'Location is not specified';
    }

    my $location = $self->{locations}->{$location_name};

    die qq[Location "$location_name" is not defined] if !defined $location;

    my $bucket = $self->{buckets}->{ $location->{bucket} };

    die qq[Bucket "$location->{bucket}" is not defined] if !defined $bucket;

    return $bucket->upload( "$location->{path}/$path", $data, cache_control => $location->{cache_control}, @args );
}

sub sync ( $self, $local, $remote, @locations ) {
    $local  = $self->{buckets}->{$local}  // die qq[Bucket "$local" is not defined];
    $remote = $self->{buckets}->{$remote} // die qq[Bucket "$remote" is not defined];

    die qq[Location is not local] if !$local->{is_local};

    my $tree = Pcore::Util::File::Tree->new;

    # create tree
    for my $root ( $local->{locations}->@* ) {
        for my $location_name (@locations) {
            my $location = $self->{locations}->{$location_name};

            die qq[Location "$location_name" is not defined] if !defined $location;

            $tree->add_dir( "$root/$location->{path}", "/$location->{path}", { 'Cache-Control' => $location->{cache_control} } );
        }
    }

    return $remote->sync( [ map { $_->{path} } $self->{locations}->@{@locations} ], $tree );
}

sub get_nginx_cfg($self) {
    my @buf;

    while ( my ( $bucket_name, $bucket ) = each $self->{buckets}->%* ) {
        next if !$bucket->{is_local};

        my @cache_control = grep { $_->{bucket} eq $bucket_name && $_->{cache_control} } values $self->{locations}->%*;

        push @buf, $bucket->get_nginx_cfg( \@cache_control );
    }

    return join "\n", @buf;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 137                  | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::CDN

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
