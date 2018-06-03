package Pcore::Core::Env::Share;

use Pcore -class;
use Pcore::Util::Scalar qw[is_plain_scalarref is_plain_arrayref is_plain_hashref];

has _lib_idx  => ( is => 'ro', isa => HashRef,  init_arg => undef );
has _lib_path => ( is => 'ro', isa => ArrayRef, init_arg => undef );

sub register_lib ( $self, $name, $path ) {
    die qq[share lib "$name" already exists] if exists $self->{_lib_idx}->{$name};

    # register lib
    $self->{_lib_idx}->{$name} = $path;

    push $self->{_lib_path}->@*, $path;

    return;
}

# return undef if storage is not exists
# return $storage_path if lib is specified
# return ArrayRef[$storage_path] if lib is not specified
sub get_storage ( $self, @ ) {
    my ( $lib, $path );

    if ( @_ == 2 ) {
        $path = $_[1];
    }
    elsif ( @_ == 3 ) {
        $lib = $_[1];

        $path = $_[2];
    }

    if ($lib) {
        die qq[share lib "$lib" is not exists] if !exists $self->{_lib_idx}->{$lib};

        return -d $self->{_lib_idx}->{$lib} . $path ? $self->{_lib_idx}->{$lib} . $path : ();
    }
    else {
        my @res;

        for my $lib_path ( $self->{_lib_path}->@* ) {
            push @res, $lib_path . $path if -d $lib_path . $path;
        }

        return \@res;
    }
}

# $ENV->{share}->get( 'www', 'static/file.html' );
# $ENV->{share}->get( 'Pcore', 'www', 'static/file.html' );
sub get ( $self, @ ) {
    my ( $lib, $root, $path );

    if ( @_ == 2 ) {
        $path = $_[1];
    }
    elsif ( @_ == 3 ) {
        ( $root, $path ) = ( $_[1], $_[2] );
    }
    elsif ( @_ == 4 ) {
        ( $lib, $root, $path ) = ( $_[1], $_[2], $_[3] );
    }

    for my $lib_path ( $lib ? exists $self->{_lib_idx}->{$lib} ? $self->{_lib_idx}->{$lib} : () : $self->{_lib_path}->@* ) {
        my $root_path = $lib_path;

        $root_path .= $root if $root;

        my $real_path = Cwd::realpath("$root_path/$path");

        if ( $real_path && -f $real_path ) {

            # convert slashes
            $real_path =~ s[\\][/]smg;

            if ( substr( $real_path, 0, length $root_path ) eq $root_path ) {
                return $real_path;
            }
        }
    }

    return;
}

sub read_cfg ( $self, @args ) {
    return P->cfg->read( $self->get(@args) );
}

sub write ( $self, $lib, $path, $file ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    die qq[share lib "$lib" is not exists] if !exists $self->{_lib_idx}->{$lib};

    $path = P->path( $self->{_lib_idx}->{$lib} . $path );

    # create path
    P->file->mkpath( $path->dirname ) if !-d $path->dirname;

    # create file
    if ( is_plain_scalarref $file ) {
        P->file->write_bin( $path, $file );
    }
    elsif ( is_plain_arrayref $file || is_plain_hashref $file ) {
        P->cfg->write( $path, $file, readable => 1 );
    }
    else {
        P->file->copy( $file, $path );
    }

    return $path;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 44                   | ValuesAndExpressions::ProhibitMismatchedOperators - Mismatched operator                                        |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
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
