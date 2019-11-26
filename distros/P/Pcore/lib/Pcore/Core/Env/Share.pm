package Pcore::Core::Env::Share;

use Pcore -class;
use Pcore::Util::Scalar qw[is_plain_scalarref is_plain_arrayref is_plain_hashref];

has _lib_idx  => ( init_arg => undef );    # HashRef
has _lib_path => ( init_arg => undef );    # ArrayRef

sub register_lib ( $self, $name, $path ) {
    die qq[share lib "$name" already exists] if exists $self->{_lib_idx}->{$name};

    # register lib
    $self->{_lib_idx}->{$name} = $path;

    push $self->{_lib_path}->@*, $path;

    return;
}

# get_location('/Pcore-Dist/cdn') - returns path or undef
# get_location('cdn') returns ArrayRef
sub get_location ( $self, $path ) {
    if ( substr( $path, 0, 1 ) eq '/' ) {
        my $lib = substr $path, 1, index( $path, '/', 1 ) - 1, $EMPTY;

        my $lib_path = $self->{_lib_idx}->{$lib};

        die qq[Share lib "$lib" does not exists] if !defined $lib_path;

        $path = $lib_path . substr $path, 1;

        return -d $path ? $path : undef;
    }
    else {
        my @res;

        for my $lib_path ( $self->{_lib_path}->@* ) {
            my $location = "$lib_path/$path";

            push @res, $location if -d $location;
        }

        return \@res;
    }
}

# get('/Pcore-Dist/cdn/1.txt')
# get('cdn/1.txt')
sub get ( $self, $path ) {
    my ( $root, $location );

    if ( substr( $path, 0, 1 ) eq '/' ) {
        my $lib = substr $path, 1, index( $path, '/', 1 ) - 1, $EMPTY;

        $root = $self->{_lib_idx}->{$lib};

        return if !defined $root;

        $location = $root . substr $path, 1;

        return if !-f $location;
    }
    else {
        for my $lib_path ( $self->{_lib_path}->@* ) {
            $location = "$lib_path/$path";

            if ( -f $location ) {
                $root = $lib_path;

                last;
            }
        }

        return if !defined $root;
    }

    $location = P->path($location);

    return if substr( $location, 0, 1 + length $root ) ne "$root/";

    return $location->{path};
}

sub read_cfg ( $self, $path, @args ) { return P->cfg->read( $self->get($path) // undef, @args ) }

sub write ( $self, $path, $file, @args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    die q[Path must be absolute] if substr( $path, 0, 1 ) ne '/';

    my $lib = substr $path, 1, index( $path, '/', 1 ) - 1, $EMPTY;

    my $root = $self->{_lib_idx}->{$lib};

    die qq[Share lib "$lib" does not exists] if !defined $root;

    $path = P->path("$root/$path");

    # create path
    P->file->mkpath( $path->{dirname} ) if !-d $path->{dirname};

    # create file
    if ( is_plain_scalarref $file ) {
        P->file->write_bin( $path, $file );
    }
    elsif ( is_plain_arrayref $file || is_plain_hashref $file ) {
        P->cfg->write( $path, $file, @args );
    }
    else {
        P->file->copy( $file, $path );
    }

    return $path;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Env::Share

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
