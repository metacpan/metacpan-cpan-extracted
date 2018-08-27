package Term::Size;

use strict;
use vars qw(@EXPORT_OK @ISA $VERSION);

use DynaLoader ();
use Exporter ();

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(chars pixels);

$VERSION = '0.209';

bootstrap Term::Size $VERSION;

1;

=encoding utf8

=head1 NAME

Term::Size - Retrieve terminal size (Unix version)

=head1 SYNOPSIS

    use Term::Size;

    ($columns, $rows) = Term::Size::chars *STDOUT{IO};
    ($x, $y) = Term::Size::pixels;

=head1 DESCRIPTION

L<Term::Size> is a Perl module which provides a straightforward way to
retrieve the terminal size.

Both functions take an optional filehandle argument, which defaults to
C<*STDIN{IO}>.  They both return a list of two values, which are the
current width and height, respectively, of the terminal associated with
the specified filehandle.

C<Term::Size::chars> returns the size in units of characters, whereas
C<Term::Size::pixels> uses units of pixels.

In a scalar context, both functions return the first element of the
list, that is, the terminal width.

The functions may be imported.

If you need to pass a filehandle to either of the L<Term::Size>
functions, beware that the C<*STDOUT{IO}> syntax is only supported in
Perl 5.004 and later.  If you have an earlier version of Perl, or are
interested in backwards compatibility, use C<*STDOUT> instead.

=head1 EXAMPLES

1. Refuse to run in a too narrow window.

    use Term::Size;

    die "Need 80 column screen" if Term::Size::chars *STDOUT{IO} < 80;

2. Track window size changes.

    use Term::Size 'chars';

    my $changed = 1;

    while (1) {
            local $SIG{'WINCH'} = sub { $changed = 1 };

            if ($changed) {
                    ($cols, $rows) = chars;
                    # Redraw, or whatever.
                    $changed = 0;
            }
    }

=head1 RETURN VALUES

If there is an error, both functions return C<undef>
in scalar context, or an empty list in list context.

If the terminal size information is not available, the functions
will normally return C<(0, 0)>, but this depends on your system.  On
character only terminals, C<pixels> will normally return C<(0, 0)>.

=head1 CAVEATS

L<Term::Size> only works on Unix systems, as it relies on the
C<ioctl> function to retrieve the terminal size. If you need
terminal size in Windows, see L<Term::Size::Win32>.

Before version 0.208, C<chars> and C<pixels> used to return false on error.

=head1 SEE ALSO

L<Term::Size::Any>, L<Term::Size::Perl>, L<Term::Size::ReadKey>, L<Term::Size::Win32>.

=head1 AUTHOR

Tim Goodwin, <tim@uunet.pipex.com>, 1997-04-23.

=head1 MANTAINER

Adriano Ferreira, <ferreira@cpan.org>, 2006-05-19.

=cut
