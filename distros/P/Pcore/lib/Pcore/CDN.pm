package Pcore::CDN;

use Pcore -class;
use Pcore::Util::Scalar qw[is_ref is_plain_arrayref is_plain_coderef];
use overload '&{}' => sub ( $self, @ ) {
    sub { $self->get_url(@_) }
  },
  fallback => 1;

has bucket => ( init_arg => undef );
has resources => ();    # HashRef[CodeRef]

around new => sub ( $orig, $self, $args ) {
    $self = $self->$orig;

    # load resources
    if ( my $resources = delete $args->{resources} ) {
        for my $lib ( $resources->@* ) {
            P->class->load( $lib =~ s/-/::/smgr );

            my $cdn_resources_path = $ENV->dist($lib)->{share_dir} . '/cdn-resources.perl';

            if ( -f $cdn_resources_path ) {
                my $cdn_resources = P->cfg->read($cdn_resources_path);

                $self->{resources}->@{ keys $cdn_resources->%* } = values $cdn_resources->%*;
            }
        }
    }

    # create buckets
    while ( my ( $name, $cfg ) = each $args->%* ) {

        # skip aliases
        next if !is_ref $cfg;

        $self->{bucket}->{$name} = P->class->load( $cfg->{type}, ns => 'Pcore::CDN::Bucket' )->new($cfg);

        $self->{bucket}->{default} //= $name;
    }

    # assign buckets aliases
    while ( my ( $name, $target ) = each $args->%* ) {

        # skip buckets
        next if is_ref $target;

        $self->{bucket}->{$name} = $self->{bucket}->{$target};
    }

    return $self;
};

sub bucket ( $self, $name ) { return $self->{bucket}->{$name} }

# $cdn->get_url($path);
# $cdn->get_url( $bucket_name, $path );
sub get_url ( $self, @ ) {
    my ( $bucket_name, $path ) = @_ == 2 ? ( 'default', $_[1] ) : ( $_[1], $_[2] );

    return $self->{bucket}->{ $bucket_name // 'default' }->get_url($path);
}

sub get_script_tag ( $self, @args ) { return qq[<script src="@{[ $self->get_url(@args) ]}" integrity="" crossorigin="anonymous"></script>] }

sub get_css_tag ( $self, @args ) { return qq[<link rel="stylesheet" href="@{[ $self->get_url(@args) ]}" integrity="" crossorigin="anonymous" />] }

sub get_resources ( $self, @resources ) {
    my @res;

    for my $name (@resources) {
        my $res;

        if ( is_plain_arrayref $name) {
            $res = $self->{resources}->{ $name->[0] }->( $self, $name->@[ 1 .. $name->$#* ] );
        }
        else {
            $res = $self->{resources}->{$name}->($self);
        }

        push @res, is_plain_arrayref $res ? $res->@* : $res;
    }

    return \@res;
}

# $cdn->upload( $path, $data, %args );
# $cdn->upload( $bucket_name, $path, $data, %args );
sub upload ( $self, @ ) {
    my ( $bucket_name, $path, $data, @args );

    my $cb = is_plain_coderef $_[-1] ? pop : ();

    if ( @_ % 2 ) {
        ( $bucket_name, $path, $data, @args ) = ( 'default', @_[ 1 .. $#_ ] );
    }
    else {
        ( $bucket_name, $path, $data, @args ) = @_[ 1 .. $#_ ];
    }

    return $self->{bucket}->{ $bucket_name // 'default' }->upload( $path, $data, @args, $cb || () );
}

sub sync ( $self, $local, $remote, @locations ) {
    $local = $self->{bucket}->{$local};

    my $local_locations = $local->{locations};

    my $locations;

    for my $location (@locations) {
        my $match = '';

        for my $loc_cache ( keys $local_locations->%* ) {
            $match = $loc_cache if length $loc_cache > length $match && index( $location, $loc_cache ) == 0;
        }

        $locations->{$location} = $match ? $local_locations->{$match} : undef;
    }

    return $self->{bucket}->{$remote}->sync( $local->{libs}, $locations );
}

sub get_nginx_cfg($self) {
    my @buf;

    my $processed;

    for my $bucket ( $self->{bucket}->%* ) {
        next if !$bucket->{is_local} || exists $processed->{ $bucket->{id} };

        $processed->{ $bucket->{id} } = 1;

        push @buf, $bucket->get_nginx_cfg;
    }

    return join $LF, @buf;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 112                  | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
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
