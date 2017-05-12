use utf8;
use strict;
use warnings;
no warnings qw(redefine);
package RT::Extension::ConditionalCustomFields;

our $VERSION = '0.05';

=encoding utf8

=head1 NAME

RT-Extension-ConditionalCustomFields - CF conditionned by the value of another CF

=head1 DESCRIPTION

Provide the ability to display/edit a custom field conditioned by the value of another (select) custom field for the same object, which can be anything that can have custom fields (L<ticket|RT::Ticket>, L<queue|RT::Queue>, L<user|RT::User>, L<group|RT::Group>, L<article|RT::Article> or L<asset|RT::Asset>).

=head1 RT VERSION

Works with RT 4.2 or greater

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Patch your RT

ConditionalCustomFields requires a small patch to add necessary Callbacks on versions of RT prior to 4.2.3.

For RT 4.2, apply the included patch:

    cd /opt/rt4 # Your location may be different
    patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.2-add-callbacks-to-extend-customfields-capabilities.patch

For RT 4.4, apply the included patch:

    cd /opt/rt4 # Your location may be different
    patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.4-add-callbacks-to-extend-customfields-capabilities.patch

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::ConditionalCustomFields');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::ConditionalCustomFields));

or add C<RT::Extension::ConditionalCustomFields> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=cut

package
    RT::CustomField;

=head1 METHODS

ConditionalCustomFields adds a ConditionedBy property, along with the following methods, to L<RT::CustomField> objets:

=head2 SetConditionedBy VALUE

Set ConditionedBy for this L<CustomField|RT::CustomField> object to VALUE. If VALUE is numerical, it should be the id of an existing L<CustomFieldValue|RT::CustomFieldValue> object. Otherwise, VALUE should be an existing L<CustomFieldValue|RT::CustomFieldValue> object. Current user should have SeeCustomField and ModifyCustomField rights for this CustomField and SeeCustomField right for the CustomField which this CustomField is conditionned by. Returns (1, 'Status message') on success and (0, 'Error Message') on failure.

=cut

sub SetConditionedBy {
    my $self = shift;
    my $value = shift || 0;
    my ($ret, $msg) = (1, '');

    my $attr = $self->FirstAttribute('ConditionedBy');
    return $ret if $attr && $attr->Content && $attr->Content == $value;

    if ($value) {
        my $cf_value = RT::CustomFieldValue->new($self->CurrentUser);
        $cf_value->SetContextObject($self->ContextObject);
        $cf_value->Load(ref $value ? $value->id : $value);

        return (0, "Permission Denied")
            unless     $cf_value->id
                    && $cf_value->CustomFieldObj
                    && $cf_value->CustomFieldObj->id
                    && $cf_value->CustomFieldObj->CurrentUserHasRight('SeeCustomField');
        ($ret, $msg) = $self->SetAttribute(
            Name    => 'ConditionedBy',
            Content => $value,
        );
    } elsif ($attr) {
        ($ret, $msg) = $attr->Delete;
    }

    if ($ret) {
        return ($ret, $self->loc('ConditionedBy changed to [_1]', $value));
    }
    else {
        return ($ret, $self->loc( "Can't change ConditionedBy to [_1]: [_2]", $value, $msg));
    }
}

=head2 ConditionedByObj

Returns the current value as a L<CustomFieldValue|RT::CustomFieldValue> object of the ConditionedBy property for this L<CustomField|RT::CustomField> object. If this L<CustomField|RT::CustomField> object is not conditioned by another one, that is: if its ConditionedBy property is not defined, returns an empty L<CustomFieldValue|RT::CustomFieldValue> object (without id). Current user should have SeeCustomField right for both this CustomField and the CustomField which this CustomField is conditionned by.

=cut

sub ConditionedByObj {
    my $self = shift;

    my $obj = RT::CustomFieldValue->new($self->CurrentUser);
    $obj->SetContextObject($self->ContextObject);

    my $attr = $self->FirstAttribute('ConditionedBy');
    if ($attr && $attr->Content && $attr->Content =~ /^\d+$/) {
        $obj->Load($attr->Content);
    }

    return $obj;
}

=head2 ConditionedByAsString

Returns the current value as a C<string> of the ConditionedBy property for this L<CustomField|RT::CustomField> object. If this L<CustomField|RT::CustomField> object is not conditioned by another one, that is: if its ConditionedBy property is not defined, returns undef. Current user should have SeeCustomField right for both this CustomField and the CustomField which this CustomField is conditionned by.

=cut

sub ConditionedByAsString {
    my $self = shift;
    my $cfv = $self->ConditionedByObj;
    return undef unless $cfv && $cfv->id;
    return $cfv->Name;
}

=head2 ConditionedByCustomField

Returns the  L<CustomField|RT::CustomField> object that this CustomField is recursively conditionned by. "Recursively" means that this method will search for a ConditionedBy property for this L<CustomField|RT::CustomField> object, then for the Customfield this one is BasedOn, and so on until it find an acestor category with a ConditionedBy property or, the Customfield which is being looked up, is not based on any ancestor category. If neither this L<CustomField|RT::CustomField> object nor one of its ancestor is conditioned by another one, that is: if their ConditionedBy property is (recursively) not defined, returns undef. Current user should have SeeCustomField right for both this CustomField and the CustomField which this CustomField is conditionned by.

=cut

sub ConditionedByCustomField {
    my $self = shift;
    my $cfv = $self->ConditionedByObj;
    # Recurse on ancestor category
    unless ($cfv->id) {
        return undef unless $self->BasedOnObj->id;
        return $self->BasedOnObj->ConditionedByCustomField;
    }
    my $cf = $cfv->CustomFieldObj;
    $cf->SetContextObject($self->ContextObject);
    return $cf;
}

=head2 ConditionedByCustomFieldValue

Returns the current value as a L<CustomFieldValue|RT::CustomFieldValue> object that this CustomField is recursively conditionned by. "Recursively" means that this method will search for a ConditionedBy property for this L<CustomField|RT::CustomField> object, then for the Customfield this one is BasedOn, and so on until it find an acestor category with a ConditionedBy property or, the Customfield which is being looked up, is not based on any ancestor category. If neither this L<CustomField|RT::CustomField> object nor one of its ancestor is conditioned by another one, that is: if their ConditionedBy property is (recursively) not defined, returns an empty L<CustomField|RT::CustomField> object (without id). Current user should have SeeCustomField right for both this CustomField and the CustomField which this CustomField is conditionned by.

=cut

sub ConditionedByCustomFieldValue {
    my $self = shift;
    my $cfv = $self->ConditionedByObj;
    # Recurse on ancestor category
    unless ($cfv->id) {
        return $cfv unless $self->BasedOnObj->id;
        return $self->BasedOnObj->ConditionedByCustomFieldValue;
    }
    return $cfv;
}

=head1 INITIALDATA

Also, ConditionalCustomFields allows to set the ConditionedBy property when creating CustomFields from an F<initialdata> file, with one of the following syntaxes:

    @CustomFields = (
        {
            Name => 'Condition',
            Type => 'SelectSingle',
            RenderType => 'Dropdown',
            Queue => [ 'General' ],
            LookupType => 'RT::Queue-RT::Ticket',
            Values => [
                { Name => 'Passed', SortOrder => 0 },
                { Name => 'Failed', SortOrder => 1 },
            ],
            Pattern => '(?#Mandatory).',
            DefaultValues => [ 'Failed' ],
        },
        {
            Name => 'Conditioned with cf and value',
            Type => 'FreeformSingle',
            Queue => [ 'General' ],
            LookupType => 'RT::Queue-RT::Ticket',
            ConditionedByCF => 'Condition',
            ConditionedBy => 'Passed',
        },
        {
            Name => 'Conditioned with cf id and value',
            Type => 'FreeformSingle',
            Queue => [ 'General' ],
            LookupType => 'RT::Queue-RT::Ticket',
            ConditionedByCF => 66,
            ConditionedBy => 'Passed',
        },
        {
            Name => 'Conditioned with cf value id',
            Type => 'FreeformSingle',
            Queue => [ 'General' ],
            LookupType => 'RT::Queue-RT::Ticket',
            ConditionedBy => 52,
        },
    );

This examples creates a select CustomField C<Condition> which should have the value C<Passed>, for CustomFields C<Conditioned with cf and value> and C<Conditioned with cf id and value> to be displayed or edited. It also created a CustomField C<Conditioned with cf value id> that is conditionned by another CustomField for the current object (L<ticket|RT::Ticket>, L<queue|RT::Queue>, L<user|RT::User|>, L<group|RT::Group>, or L<article|RT::Article>) having a C<CustomFieldValue> with C<id = 52>.

Additional fields for an element of C<@CustomFields> are:

=over 4

=item C<ConditonedBy>

The L<CustomFieldValue|RT::CustomFieldValue> that this new L<CustomField|RT::CustomField> should conditionned by. It can be either the C<id> of an existing L<CustomFieldValue|RT::CustomFieldValue> object (in which case attribute C<ConditionedByCF> is ignored), or the value as a C<string> of the L<CustomField|RT::CustomField> attribute (which is then mandatory).

=item C<ConditonedByCF>

The L<CustomField|RT::CustomField> that this new L<CustomField|RT::CustomField> should conditionned by. It can be either the C<id> or the C<Name> of a previously created L<CustomField|RT::CustomField>. This implies that this L<CustomField|RT::CustomField> should be declared before this one in the F<initialdata> file, or it should already exist. When C<ConditionedByCF> attribute is set, C<ConditionedBy> attribute should always also be set.

=back

=cut

{
    my $old_InsertData = RT::Handle->can("InsertData");
    *RT::Handle::InsertData = sub {
        my $self = shift;
        my $datafile = shift;
        my $root_password = shift;
        my ($ret, $msg) = $old_InsertData->($self, $datafile, $root_password, disconnect_after => 0, @_);
        return ($ret, $msg) unless $ret;

        our @CustomFields;
        local @CustomFields;
        local $@;
        $RT::Logger->debug("Going to reload '$datafile' data file for processing Conditional CustomFields");
        eval { do $datafile }
            or return (0, "Couldn't load data from '$datafile' for import:\n\nERROR:". $@);

        if (@CustomFields) {
            $RT::Logger->debug("Processing Conditional CustomFields...");
            for my $item (@CustomFields) {
                next unless $item->{Name};
                $RT::Logger->debug("Processing " . $item->{Name});
                my $conditional_cf = RT::CustomField->new($RT::SystemUser);
                $conditional_cf->Load($item->{Name});
                next unless $conditional_cf->id;

                my $conditioned_by_value;
                if ($item->{'ConditionedBy'}) {
                    if ($item->{'ConditionedBy'} =~ /^\d+$/) {
                        # Already have a cfvalue ID -- should be fine
                        $conditioned_by_value = $item->{'ConditionedBy'};
                    } elsif ($item->{'ConditionedByCF'} ) {
                        my $cfid;
                        if ($item->{'ConditionedByCF'} =~ /^\d+$/) {
                            # Already have a cf ID
                            $cfid = $item->{'ConditionedByCF'};
                        } elsif ($item->{'LookupType'}) {
                            my $cf = RT::CustomField->new($RT::SystemUser);
                            my ($ok, $msg) = $cf->LoadByCols(
                                Name => $item->{'ConditionedByCF'},
                                LookupType => $item->{'LookupType'},
                                Disabled => 0);
                            if ($ok) {
                                $cfid = $cf->id;
                            } else {
                                $RT::Logger->error("Unable to load $item->{ConditionedByCF} as a $item->{LookupType} CF. Skipping ConditionedBy: $msg");
                            }
                        } else {
                            $RT::Logger->error("Unable to load CF $item->{ConditionedByCF} because no LookupType was specified. Skipping ConditionedBy");
                        }

                        if ($cfid) {
                            my $conditioned_by = RT::CustomFieldValue->new($RT::SystemUser);
                            my ($ok, $msg) = $conditioned_by->LoadByCols(
                                Name => $item->{'ConditionedBy'},
                                CustomField => $cfid);
                            if ($ok) {
                                $conditioned_by_value = $conditioned_by->Id;
                            } else {
                                $RT::Logger->error("Unable to load $item->{ConditionedByCF} as a $item->{LookupType} CF. Skipping ConditionedBy: $msg");
                            }
                        }
                    } else {
                        $RT::Logger->error("Unable to load CFValue $item->{ConditionedBy} because no ConditionedByCF was specified. Skipping ConditionedBy");
                    }
                }

                if ($conditioned_by_value) {
                    my ($ret, $msg) = $conditional_cf->SetConditionedBy($conditioned_by_value);
                    unless($ret) {
                        $RT::Logger->error($msg);
                        next;
                    }
                    $RT::Logger->debug("ConditionedBy set for " . $item->{Name});
                }
            }
            $RT::Logger->debug("done.");
        }
        return($ret, $msg);
    };
}

=head1 AUTHOR

Gérald Sédrati-Dinet E<lt>gibus@easter-eggs.comE<gt>

=head1 REPOSITORY

L<https://github.com/gibus/RT-Extension-ConditionalCustomFields>

=head1 BUGS

All bugs should be reported via email to

L<bug-RT-Extension-ConditionalCustomFields@rt.cpan.org|mailto:bug-RT-Extension-ConditionalCustomFields@rt.cpan.org>

or via the web at

L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ConditionalCustomFields>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2017 by Gérald Sédrati-Dinet, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007

=cut

1;
