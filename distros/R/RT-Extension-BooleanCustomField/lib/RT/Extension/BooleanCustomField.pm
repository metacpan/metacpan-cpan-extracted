use utf8;
use strict;
use warnings;
no warnings qw(redefine);
package RT::Extension::BooleanCustomField;

our $VERSION = '0.04';

=encoding utf8

=head1 NAME

RT-Extension-BooleanCustomField - CF with checkbox to set or unset its value

=head1 DESCRIPTION

Provide a new type of L<custom field|RT::CustomField>, which value can only be set or unset. Editing a C<BooleanCustomField> is done through a single checkbox.

This enhances the behaviour allowed by core C<Request Tracker> through C<SelectCustomField>, where editing a C<SelectCustomField>, with only a single value, should be done through a dropdown menu, radio buttons or checkboxes, including the single value and C<no value>. With C<BooleanCustomField>, you have only a single checkbox to check or uncheck.

=head1 RT VERSION

Works with RT 4.0 or greater. Use v0.03 for RT 4 and last version for RT 5 and upper.

It should be noted that from RT 5, you can use a C<SelectCustomField> with C<Checkbox> C<RenderType> to have the same functionality than C<BooleanCustomField>. The difference is that C<Checkbox> expects two values, first for unchecked and the other for checked. While C<BooleanCustomField> use C<no value> for unchecked and C<1> for checked. So if you want to migrate a C<CustomField> from C<BooleanCustomField> to C<Checkbox>, you have to change the type of this C<CustomField>, add two values (first for unchecked and the other for checked) and then update all objects (tickets, articles, assets…) where this C<CustomField> can be set, moving values from C<unset> to your first value and from c<1> to the second one. This can be tedious if your RT has a lot of tickets, and you should probably stick to C<BooleanCustomField> in this case! Otherwise, you can use the F<etc/boolean2checbox.initialdata> file provided in this distibution.

=head1 INSTALLATION

=over

=item export C<$RTHOME=/home/of/your/RT/installation/lib>

This is needed if your C<RT> installation directory is not C</opt/rt6/> (nor C</opt/rt5> for RT 5, nor C</opt/rt4> for RT 4).

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::BooleanCustomField');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::BooleanCustomField));

or add C<RT::Extension::BooleanCustomField> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=cut

$RT::CustomField::FieldTypes{Boolean} = {
    sort_order => 15,
    selection_type => 0,
    canonicalizes => 0,
    labels         => [
        undef,
        'Check/Uncheck',
        undef,
    ]
};

{
    # Boolean CustomField cannnot have multiple values
    my $old_TypeComposites = RT::CustomField->can("TypeComposites");
    *RT::CustomField::TypeComposites = sub {
        my $self = shift;
        return grep !/Boolean-0/, $self->$old_TypeComposites();
    };
}

=head1 AUTHOR

Gérald Sédrati E<lt>gibus@easter-eggs.comE<gt>

=head1 REPOSITORY

L<https://github.com/gibus/RT-Extension-BooleanCustomField>

=head1 BUGS

All bugs should be reported via email to

L<bug-RT-Extension-BooleanCustomField@rt.cpan.org|mailto:bug-RT-Extension-BooleanCustomField@rt.cpan.org>

or via the web at

L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-BooleanCustomField>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2018-2026 by Gérald Sédrati, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007

=cut

1;
