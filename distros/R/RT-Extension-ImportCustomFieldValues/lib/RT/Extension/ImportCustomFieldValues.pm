use strict;
use warnings;
package RT::Extension::ImportCustomFieldValues;

our $VERSION = '0.03';

RT->AddStyleSheets('importcustomfieldvalues.css');

=head1 NAME

RT-Extension-ImportCustomFieldValues - Allow to import customfield values from CSV file

=head1 RT VERSION

Works with RT 4.2 and 4.4.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::ImportCustomFieldValues');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 DESCRIPTION

The ImportCustomFieldValues extension gives you an easy way to import values in a customfield of type "Select" from a CSV file.

=head1 DETAILS

The tool is available through Administration->CustomFields->[CustomField]->Import from CSV

CSV file must a consist of a text file with:

- File encoding: UTF-8
- Fields separated by ";"
- No headers
- Using the following columns and order: SortOrder, Name, Description, Category
- Column "Name" is mandatory, other columns may be empty but must exists

=head1 AUTHOR

Emmanuel Lacour E<lt>elacour@easter-eggs.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ImportCustomFieldValues@rt.cpan.org|mailto:bug-RT-Extension-ImportCustomFieldValues@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ImportCustomFieldValues>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Emmanuel Lacour.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;

