use strict;
use warnings;
package RT::Extension::Tags;

our $VERSION = '0.05';


require RT::CustomField;

$RT::CustomField::FieldTypes{Tags} = {
    sort_order     => 85,
    selection_type => 1,
    labels         => [
        'Enter multiple tags',  # loc
        'Enter one tag',        # loc
        'Enter up to [_1] tag', # loc
    ],
};

RT->AddJavaScript("tag-it.min.js");
RT->AddStyleSheets("jquery.tagit.css");

no warnings 'redefine';
my $old = \&RT::CustomField::AddValueForObject;
*RT::CustomField::AddValueForObject = sub {
    my $self = shift;
    my %args = (
        Content => undef,
        LargeContent => undef,
        @_
    );

    my ($ok, $msg) = $old->($self, @_);
    return ($ok, $msg) unless $ok;

    return ($ok, $msg) unless $self->Type eq "Tags";


    my $value = $args{LargeContent} || $args{Content};
    my $as_super = RT::CustomField->new( RT->SystemUser );
    $as_super->Load( $self->id );
    my $values = $as_super->Values;
    $values->Limit( FIELD => 'Name', VALUE => $value );
    return ($ok, $msg) if $values->Count;

    $as_super->AddValue( Name => $value );
    return ($ok, $msg);
};


=head1 NAME

RT-Extension-Tags - Provides simple tagging using custom fields

=head1 DESCRIPTION

This extension allows you to create tags using custom fields on
tickets.  It adds a new custom field type, "Tags", which allows users
to add new values (tags) that will then be added to the list of
available autocomplete values for that custom field.

The created tags become links to a search of all active tickets
with that tag.

=head2 Tag Custom Field

The initdb step installs an example global Tag custom field.

=head1 RT VERSION

Works with RT 4.0, 4.2, 4.4, 5.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::Tags');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::Tags));

or add C<RT::Extension::Tags> to your existing C<@Plugins> line.

=item C<make initdb>

This optional step installs an example global C<Tag> custom field.

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head2 UPGRADING

If you are upgrading from version 0.01 or 0.02, note that the custom field
type was changed from a default RT "multiple values with autocompletion" to
a dedicated tag custom field type. To upgrade:

=over

=item * Change your Tag custom field to use the new tag custom field type

You can either edit your existing custom field and change the Type to "Enter
multiple tags" or run the initdb step and copy your values to the new Tag
custom field automatically created.

=item * Disable the scrip "On Custom Field Change Add New Tag Values"

This scrip is no longer needed with the new tag custom field type,
so you can disable or delete it.

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-Tags@rt.cpan.org|mailto:bug-RT-Extension-Tags@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-Tags>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2016-2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
