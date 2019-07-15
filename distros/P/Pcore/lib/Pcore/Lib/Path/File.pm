package Pcore::Lib::Path::File;

use Pcore -role;
use Fcntl qw[];

# TODO
sub touch ( $self, %args ) {

    # my %args = (
    #     atime => undef,
    #     mtime => undef,
    #     mode  => q[rw-------],
    #     umask => undef,
    #     splice @_, 1,
    # );

    # $path = encode_path($path);

    if ( !-e $self ) {

        # set umask if defined
        # my $umask_guard = defined $args{umask} ? &umask( $args{umask} ) : undef;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

        # sysopen my $FH, $self->encoded, Fcntl::O_WRONLY | Fcntl::O_CREAT | Fcntl::O_APPEND, calc_chmod( $args{mode} ) or die qq[Can't touch file "$path"];

        sysopen my $fh, $self->encoded, Fcntl::O_WRONLY | Fcntl::O_CREAT | Fcntl::O_APPEND or die qq[Can't touch file "$self"];

        close $fh or die;
    }

    # set utime
    $args{atime} //= $args{mtime} // time;
    $args{mtime} //= $args{atime};
    utime $args{atime}, $args{mtime}, $self->encoded or die;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::Path::File

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
