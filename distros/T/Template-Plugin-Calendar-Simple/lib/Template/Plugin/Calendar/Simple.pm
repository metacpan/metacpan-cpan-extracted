package Template::Plugin::Calendar::Simple;
use strict;
use warnings FATAL => 'all';
our $VERSION = '1.04';

use Calendar::Simple;
use Template::Plugin;
use Template::Iterator;
use Template::Exception;
use base qw( Template::Plugin );

sub new {
    my ($class, $context, @args) = @_;
    my @cal = Calendar::Simple::calendar( @args );
    return bless {
        _CONTEXT => $context,
        rows     => Template::Iterator->new( [@cal] ),
        days     => [qw( Sun Mon Tue Wed Thu Fri Sat )],
    }, $class;
}

sub rows {
    my ($self) = shift;
    return $self->{rows};
}

sub days {
    my ($self, $monday_starts_week) = @_;
    my @days = @{ $self->{days} };
    push @days, shift @days if $monday_starts_week;
    return [@days];
}

1;
__END__

=head1 NAME

Template::Plugin::Calendar::Simple - Just another HTML calendar generator.

=head1 SYNOPSIS

  [% USE cal = Calendar.Simple %]

  <table border="1">
    <tr>
    [% FOREACH day = cal.days %]
      <th>[% day %]</th>
    [% END %]
    </tr>
    [% FOREACH row = cal.rows %]
    <tr>
    [% FOREACH col = row %]
      <td>[% col || '&nbsp;' %]</td>
    [% END %]
    </tr>
  [% END %]
  </table>

=head1 DESCRIPTION

Provides calendar delimiters for a Template Toolkit template via
L<Calendar::Simple>. This module supplies the data, you supply the HTML.
Defaults to current month within the current year. Past months and years
can be specified within the Template constructor:

  [% USE cal = Calendar.Simple( 5, 2000 ) %]

Can generate calendars that start with Monday instead of Sunday like so:

  [% USE cal = Calendar.Simple( 5, 2000, 1 ) %]
  ...
    [% FOREACH day = cal.days( 1 ) %]
    ...

See the unit tests for more examples.

=head1 METHODS

=over 4

=item C<new()>

Constructor. Will be called for you by the Template Toolkit engine.

=item C<rows()>

   [% FOREACH row = cal.rows %]

Returns a Template::Iterator which contains the calendar rows.
Each row, however, is simply an array.

=item C<days()>

   [% FOREACH day = cal.days %]

Most calendars have a header with the days - this method returns
an array of abbreviated day names (currently only in English). If
any argument is passed, then the week day starts with Monday instead
of Sunday.

=back

=head1 SEE ALSO

=over 4

=item * L<Template::Plugin>

=item * L<Calendar::Simple>.

=back

=head1 BUGS AND LIMITATIONS


Please report any bugs or feature requests to either

=over 4

=item * Email: C<bug-template-plugin-calendar-simple at rt.cpan.org>

=item * Web: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Calendar-Simple>

=back

I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 GITHUB

The Github project is L<https://github.com/jeffa/Template-Plugin-Calendar-Simple>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::Calendar::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here) L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-Calendar-Simple>

=item * AnnoCPAN: Annotated CPAN documentation L<http://annocpan.org/dist/Template-Plugin-Calendar-Simple>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/Template-Plugin-Calendar-Simple>

=item * Search CPAN L<http://search.cpan.org/dist/Template-Plugin-Calendar-Simple>

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
