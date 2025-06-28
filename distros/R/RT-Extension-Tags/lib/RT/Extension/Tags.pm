use strict;
use warnings;
package RT::Extension::Tags;

our $VERSION = '1.00';

require RT::CustomField;
require RT::Interface::Web;

$RT::CustomField::FieldTypes{Tags} = {
    sort_order     => 85,
    selection_type => 1,
    labels         => [
        'Enter multiple tags',  # loc
        'Enter one tag',        # loc
        'Enter up to [_1] tag', # loc
    ],
};

no warnings 'redefine';
my $old_avfo = \&RT::CustomField::AddValueForObject;
*RT::CustomField::AddValueForObject = sub {
    my $self = shift;
    my %args = (
        Content => undef,
        LargeContent => undef,
        @_
    );

    my ($ok, $msg) = $old_avfo->($self, @_);
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

my $old_nocfv = \&HTML::Mason::Commands::_NormalizeObjectCustomFieldValue;
*HTML::Mason::Commands::_NormalizeObjectCustomFieldValue = sub {
    my %args = @_;
    my $cf_type = $args{CustomField}->Type;

    # if this is a Tags custom field replace ',  ' with newline
    # tomselect uses ',  ' as a delimiter but _NormalizeObjectCustomFieldValue
    # expects newline as a delimiter for non autocomplete custom fields
    if ( ( $cf_type eq 'Tags' ) && !( ref( $args{Value} ) eq 'ARRAY' ) ) {
        $args{Value} =~ s/,  /\n/g
            if defined $args{Value};
    }

    return $old_nocfv->(%args);
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

Works with RT 6.0. For RT 5.0 use the latest 0.* version.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Patch RT

If you are running on RT 6.0.0, apply the included patch:

    patch -p1 -d /opt/rt6 < patches/0001-Split-multiple-tomselect-initial-value-on-delimiter.patch

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

Add this line to your F<RT_SiteConfig.pm> file:

    Plugin('RT::Extension::Tags');

=item C<make initdb>

This optional step installs an example global C<Tag> custom field.

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

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

This software is Copyright (c) 2016-2025 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
