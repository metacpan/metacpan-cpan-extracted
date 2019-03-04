package Struct::Path::PerlStyle::Functions;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Scalar::Util qw(looks_like_number);

our @EXPORT_OK = qw(
    BACK
    back
);

# INPORTANT: upper case should be used for function names to avoid clashes
# with existing perl functions and operators.

=head1 NAME

Struct::Path::PerlStyle::Functions - Collection handy functions for
L<Struct::Path::PerlStyle> hooks.

=cut

=head1 EXPORT

Nothing is exported by default.

=head1 Functions

=head2 BACK, back

Step back count times

    BACK(3); # go back 3 steps

C<undef> returned when requested amount is greater than current step.
Lower-case 'back' is just an alias to 'BACK' for backward compatibility;
deprecated and will be removed in the future.

=cut

sub BACK {
    my $steps = defined $_[0] ? $_[0] : 1;

    return undef unless (looks_like_number $steps and int($steps) == $steps);
    return 1 if ($steps == 0);
    return undef if ($steps < 0 or $steps > @{$_{path}});

    splice @{$_{path}}, -$steps;
    splice @{$_{refs}}, -$steps;
}

*back = \&BACK; # for backward compatibility, deprecated

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-struct-path-native at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path-PerlStyle>. I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Path::PerlStyle::Functions

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path-PerlStyle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-Path-PerlStyle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-Path-PerlStyle>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-Path-PerlStyle/>

=back

=head1 SEE ALSO

L<Struct::Path>, L<Struct::Diff>, L<perldsc>, L<perldata>

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2019 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path::PerlStyle::Functions
