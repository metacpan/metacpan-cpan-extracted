
package Term::Size::ReadKey;

use strict;

require Exporter;

use vars qw( @ISA @EXPORT_OK $VERSION );
@ISA = qw( Exporter );
@EXPORT_OK = qw( chars pixels );

$VERSION = '0.03';

=head1 NAME

Term::Size::ReadKey - Retrieve terminal size (via Term::ReadKey)

=head1 SYNOPSIS

    use Term::Size::ReadKey;

    ($columns, $rows) = Term::Size::ReadKey::chars *STDOUT{IO};
    ($x, $y) = Term::Size::ReadKey::pixels;

=head1 DESCRIPTION

Yet another implementation of C<Term::Size>. Now using 
C<Term::ReadKey> to do the hard work.

=head2 FUNCTIONS

=over 4

=item B<chars>

    ($columns, $rows) = chars($h);
    $columns = chars($h);

C<chars> returns the terminal size in units of characters
corresponding to the given filehandle C<$h>.
If the argument is ommitted, C<*STDIN{IO}> is used.
In scalar context, it returns the terminal width.

=item B<pixels>

    ($x, $y) = pixels($h);
    $x = pixels($h);

C<pixels> returns the terminal size in units of pixels
corresponding to the given filehandle C<$h>.
If the argument is ommitted, C<*STDIN{IO}> is used.
In scalar context, it returns the terminal width.

Many systems with character-only terminals will return C<(0, 0)>.

=back

=head1 BUGS

The basic test may fail harshly when running under the
test harness. This happens with Term::ReadKey alone as
well. Term::ReadKey gets away with murder by setting
COLUMNS and LINES environment variables (which are used
as a fallback). This release also applies the same cheat.
I gotta find a more decent fix to these issues.

=head1 SEE ALSO

It all began with L<Term::Size> by Tim Goodwin. You may want to
have a look at:

    Term::Size
    Term::Size::Unix
    Term::Size::Win32
    Term::Size::Perl

You may as well be interested in what more C<Term::ReadKey> does.

    Term::ReadKey

Please reports bugs via CPAN RT, 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-Size-ReadKey

=head1 AUTHOR

A. R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by A. R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

require Term::ReadKey;


# ( row, col, x, y )
sub _winsize {
    my $h = shift || *STDIN;
    return Term::ReadKey::GetTerminalSize($h);
}

sub chars {
    my @sz = _winsize(shift);
    return @sz[0, 1] if wantarray;
    return $sz[0];
}

sub pixels {
    my @sz = _winsize(shift);
    return @sz[2, 3] if wantarray;
    return $sz[2];
}

1;
