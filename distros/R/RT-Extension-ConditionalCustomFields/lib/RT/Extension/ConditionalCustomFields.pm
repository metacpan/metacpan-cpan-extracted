use utf8;
use strict;
use warnings;
no warnings qw(redefine);
package RT::Extension::ConditionalCustomFields;

our $VERSION = '0.09';

=encoding utf8

=head1 NAME

RT::Extension::ConditionalCustomFields - CF conditionned by the value of another CF

=head1 DESCRIPTION

Provide the ability to display/edit a L<custom field|RT::CustomField> conditioned by the value of another (select) L<custom field|RT::CustomField> for the same object, which can be anything that can have custom fields (L<ticket|RT::Ticket>, L<queue|RT::Queue>, L<user|RT::User>, L<group|RT::Group>, L<article|RT::Article> or L<asset|RT::Asset>). If a L<custom field|RT::CustomField> is based on another (parent) L<custom field|RT::CustomField> which is conditioned by, this (child) L<custom field|RT::CustomField> will of course also be conditioned by (with the same condition as its parent).

From version 0.07, the condition can be multivalued, that is: the conditioned custom field can be displayed/edited if the condition custom field has one of these values (In other words: there is an C<OR> bewteen the values of the condition). The condition custom field can be a select custom field with values defined by L<CustomFieldValues|RT::CustomFieldValues> or an L<external custom field|RT::CustomFieldValues::External>.

I<Note that version 0.07 is a complete redesign: the API described below has changed; also, the way that ConditionedBy property is store has changed. If you upgrade from a previous version, you have to reconfigure the custom fields which are conditionned by.>

=head1 RT VERSION

Works with RT 4.2 or greater

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Patch your RT

ConditionalCustomFields requires a small patch to add necessary Callbacks on versions of RT superior to 4.2.3. (The patch has been submitted to BestPractical in order to be included in future RT releases, as of RT 4.4.2, some parts of the patch are already included, but some other parts still required to apply this patch.)

For RT 4.2, apply the included patch:

    cd /opt/rt4 # Your location may be different
    patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.2-add-callbacks-to-extend-customfields-capabilities.patch

For RT 4.4.1, apply the included patch:

    cd /opt/rt4 # Your location may be different
    patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.4.1-add-callbacks-to-extend-customfields-capabilities.patch

For RT 4.4.2, apply the included patch:

    cd /opt/rt4 # Your location may be different
    patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.4.2-add-callbacks-to-extend-customfields-capabilities.patch

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

ConditionalCustomFields adds a ConditionedBy property, that is a L<CustomField|RT::CustomField> and a value, along with the following methods, to L<RT::CustomField> objets:

=head2 SetConditionedBy CF, VALUE

Set the ConditionedBy property for this L<CustomField|RT::CustomField> object to L<CustomFieldValue|RT::CustomField> C<CF> with value set to C<VALUE>. C<CF> should be an existing L<CustomField|RT::CustomField> object or the id of an existing L<CustomField|RT::CustomField> object, or the name of an unambiguous existing L<CustomField|RT::CustomField> object. C<VALUE> should be a string. Current user should have C<SeeCustomField> and C<ModifyCustomField> rights for this L<CustomField|RT::CustomField> and C<SeeCustomField> right for the L<CustomField|RT::CustomField> which this L<CustomField|RT::CustomField> is conditionned by. Returns (1, 'Status message') on success and (0, 'Error Message') on failure.

=cut

sub SetConditionedBy {
    my $self = shift;
    my $cf = shift;
    my $value = shift;

    return (0, $self->loc('CF parametrer is mandatory')) if (!$cf && $value);

    # Use empty RT::CustomField to delete attribute
    unless ($cf) {
        $cf = RT::CustomField->new($self->CurrentUser);
    }

    # Use $cf as a RT::CustomField object
    unless (ref $cf) {
        my $cf_id = $cf;
        $cf = RT::CustomField->new($self->CurrentUser);
        $cf->Load($cf_id);
        return(0, $self->loc("Couldn't load CustomField #[_1]", $cf_id)) unless $cf->id;
    }

    my @values = ref($value) eq 'ARRAY' ? @$value : ($value);

    sub arrays_identical {
        my( $left, $right ) = @_;
        my @leftary = ref $left eq 'ARRAY' ? @$left : ($left);
        my @rightary = ref $right eq 'ARRAY' ? @$right : ($right);
        return 0 if scalar @$left != scalar @$right;
        my %hash;
        @hash{ @leftary, @rightary } = ();
        return scalar keys %hash == scalar @leftary;
    }

    my $attr = $self->FirstAttribute('ConditionedBy');
    if ($attr && $attr->Content
              && $attr->Content->{CF}
              && $cf->id
              && $attr->Content->{CF} == $cf->id
              && $attr->Content->{vals}
              && arrays_identical($attr->Content->{vals}, \@values)) {
        return (1, $self->loc('ConditionedBy unchanged'));
    }

    if ($cf->id && @values) {
        return (0, "Permission Denied")
            unless $cf->CurrentUserHasRight('SeeCustomField');

        my ($ret, $msg) = $self->SetAttribute(
            Name    => 'ConditionedBy',
            Content => {CF => $cf->id, vals => \@values},
        );
        if ($ret) {
            return ($ret, $self->loc('ConditionedBy changed to CustomField #[_1], values [_2]', $cf->id, join(', ', @values)));
        }
        else {
            return ($ret, $self->loc( "Can't change ConditionedBy to CustomField #[_1], values [_2]: [_3]", $cf->id, join(', ', @values), $msg));
        }
    } elsif ($attr) {
        my ($ret, $msg) = $attr->Delete;
        if ($ret) {
            return ($ret, $self->loc('ConditionedBy deleted'));
        }
        else {
            return ($ret, $self->loc( "Can't delete ConditionedBy: [_1]", $msg));
        }
    }
}

=head2 ConditionedBy

Returns the current C<ConditionedBy> property for this L<CustomField|RT::CustomField> object as a hash with keys C<CF> containing the id of the L<CustomField|RT::CustomField> which this  L<CustomField|RT::CustomField> is recursively conditionned by, and C<val> containing the value as string. If neither this L<CustomField|RT::CustomField> object nor one of its ancestor is conditioned by another one, that is: if their C<ConditionedBy> property is not (recursively) defined, returns C<undef>. Current user should have C<SeeCustomField> right for both this L<CustomField|RT::CustomField> and the L<CustomField|RT::CustomField> which this L<CustomField|RT::CustomField> is conditionned recursively by. I<"Recursively"> means that this method will search for a C<ConditionedBy> property for this L<CustomField|RT::CustomField> object, then for the L<CustomField|RT::CustomField> this one is C<BasedOn>, and so on until it find an acestor C<Category> with a C<ConditionedBy> property or, the L<CustomField|RT::CustomField> which is being looked up, is not based on any ancestor C<Category>.


=cut

sub ConditionedBy {
    my $self = shift;

    $self->ClearAttributes;
    my $attr = $self->FirstAttribute('ConditionedBy');
    unless ($attr && $attr->Content) {
        # Recurse on ancestor category
        return undef unless $self->BasedOnObj->id;
        return $self->BasedOnObj->ConditionedBy;
    }

    return $attr->Content;
}

sub _findGrouping {
    my $self = shift;
    my $record_class = $self->_GroupingClass(shift);
    my $config = RT->Config->Get('CustomFieldGroupings');
       $config = {} unless ref($config) eq 'HASH';
    if ($record_class && (ref($config->{$record_class} ||= []) eq "ARRAY")) {
        my $config_hash = {@{$config->{$record_class}}};
        while (my ($group, $cfs) = each %$config_hash) {
            return $group
                if grep {$_ eq $self->Name} @$cfs;
        }
    }
    return undef;
}

my $old_MatchPattern = RT::CustomField->can("MatchPattern");
*RT::CustomField::MatchPattern = sub {
    my $self = shift;
    my $match = $old_MatchPattern->($self);
    my $conditioned_by = $self->ConditionedBy;

    unless (!$conditioned_by || $match) {
        my $mason = $HTML::Mason::Commands::m;
        if ($mason) {
            my %mason_args = @{$mason->current_args};
            if ($mason_args{ARGSRef}) {
                my $condition_cf = RT::CustomField->new($self->CurrentUser);
                $condition_cf->Load($conditioned_by->{CF});
                if ($condition_cf->id) {
                    my $condition_grouping = $condition_cf->_findGrouping($self->ContextObject);
                    $condition_grouping =~ s/\W//g if $condition_grouping;
                    my $condition_arg = RT::Interface::Web::GetCustomFieldInputName(Object => $self->ContextObject, CustomField => $condition_cf, Grouping => $condition_grouping );

                    my $condition_val = $mason_args{ARGSRef}->{$condition_arg};
                    if ($condition_val && !grep {$_ eq $condition_val} @{$conditioned_by->{vals}}) {
                        $match = 1;
                    }
                }
            }
        }
    }

    return $match;
};

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
            Name => 'Conditioned with cf name and value',
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
    );

This examples creates a select CustomField C<Condition> which should have the value C<Passed>, for CustomFields C<Conditioned with cf name and value> and C<Conditioned with cf id and value> to be displayed or edited.

Additional fields for an element of C<@CustomFields> are:

=over 4

=item C<ConditonedByCF>

The L<CustomField|RT::CustomField> that this new L<CustomField|RT::CustomField> should conditionned by. It can be either the C<id> or the C<Name> of a previously created L<CustomField|RT::CustomField>. This implies that this L<CustomField|RT::CustomField> should be declared before this one in the F<initialdata> file, or it should already exist. When C<ConditionedByCF> attribute is set, C<ConditionedBy> attribute should always also be set.

=item C<ConditonedBy>

The value as a C<string> of the L<CustomField|RT::CustomField> defined by the C<ConditionedByCF> attribute (which is mandatory).

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

                my $conditioned_by_cfid;
                my $conditioned_by_value;
                if ($item->{'ConditionedBy'}) {
                    $conditioned_by_value = $item->{'ConditionedBy'};
                    if ($item->{'ConditionedByCF'} ) {
                        if ($item->{'ConditionedByCF'} =~ /^\d+$/) {
                            # Already have a cf ID
                            $conditioned_by_cfid = $item->{'ConditionedByCF'};
                        } elsif ($item->{'LookupType'}) {
                            my $cf = RT::CustomField->new($RT::SystemUser);
                            my ($ok, $msg) = $cf->LoadByCols(
                                Name => $item->{'ConditionedByCF'},
                                LookupType => $item->{'LookupType'},
                                Disabled => 0);
                            if ($ok) {
                                $conditioned_by_cfid = $cf->id;
                            } else {
                                $RT::Logger->error("Unable to load $item->{ConditionedByCF} as a $item->{LookupType} CF. Skipping ConditionedBy: $msg");
                            }
                        } else {
                            $RT::Logger->error("Unable to load CF $item->{ConditionedByCF} because no LookupType was specified. Skipping ConditionedBy");
                        }
                    } else {
                        $RT::Logger->error("Unable to load value $item->{ConditionedBy} because no ConditionedByCF was specified. Skipping ConditionedBy");
                    }
                }

                if ($conditioned_by_value) {
                    my ($ret, $msg) = $conditional_cf->SetConditionedBy($conditioned_by_cfid, $conditioned_by_value);
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
