use utf8;
use strict;
use warnings;
no warnings qw(redefine);
package RT::Extension::RichtextCustomField;

our $VERSION = '0.05';

=encoding utf8

=head1 NAME

RT::Extension::RichtextCustomField - CF with wysiwyg editor

=head1 DESCRIPTION

Provide a new type of L<custom field|https://docs.bestpractical.com/rt/4.4.4/RT/CustomField.html>, similar to Text but with wysiwyg editor when editing value.

=head1 RT VERSION

Works with RT 4.2 or greater

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Patch your RT

C<RichtextCustomField> requires a small patch to allow  L<custom fields|https://docs.bestpractical.com/rt/4.4.4/RT/CustomField.html> with C<Richtext> type to be chosen as recipient for extracting from a L<ticket|https://docs.bestpractical.com/rt/4.4.4/RT/Ticket.html> into an L<article|https://docs.bestpractical.com/rt/4.4.4/RT/Article.pm>. I<You have to apply this patch if you need this feature, and only in this case.>

For RT 4.4 or lower, apply the included patch:

    cd /opt/rt4 # Your location may be different
    patch -p1 < /download/dir/RT-Extension-RichtextCustomField/patches/4.4-add-Richtext-CFs-ExtractArticleFromTicket.patch

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::RichtextCustomField');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::RichtextCustomField));

or add C<RT::Extension::RichtextCustomField> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=cut

$RT::CustomField::FieldTypes{Richtext} = {
    sort_order => 35,
    selection_type => 0,
    canonicalizes => 1,
    labels         => [
        'Fill in multiple richtext areas with wysiwyg editor',
        'Fill in one richtext area with wysiwyg editor',
        'Fill in up to [quant,_1,richtext area,richtext areas] with wysiwyg editor',
    ]
};

=head1 AUTHOR

Gérald Sédrati-Dinet E<lt>gibus@easter-eggs.comE<gt>

=head1 REPOSITORY

L<https://github.com/gibus/RT-Extension-RichtextCustomField>

=head1 BUGS

All bugs should be reported via email to

L<bug-RT-Extension-RichtextCustomField@rt.cpan.org|mailto:bug-RT-Extension-RichtextCustomField@rt.cpan.org>

or via the web at

L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-RichtextCustomField>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2017 by Gérald Sédrati-Dinet, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007

=cut

1;
