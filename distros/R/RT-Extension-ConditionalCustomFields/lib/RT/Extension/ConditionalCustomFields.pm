use utf8;
use strict;
use warnings;
no warnings qw(redefine);
package RT::Extension::ConditionalCustomFields;

our $VERSION = '1.16';

=encoding utf8

=head1 NAME

RT::Extension::ConditionalCustomFields - CF conditioned by the value of another CF

=head1 DESCRIPTION

This plugin provides the ability to display/edit a L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> – called the "conditioned by L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>" throughout this documentation – conditioned by the value of another L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> – the "condition L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>" – for the same object, which can be anything that can have custom fields (L<ticket|https://docs.bestpractical.com/rt/5.0.5/RT/Ticket.html>, L<queue|https://docs.bestpractical.com/rt/5.0.5/RT/Queue.html>, L<user|https://docs.bestpractical.com/rt/5.0.5/RT/User.html>, L<group|https://docs.bestpractical.com/rt/5.0.5/RT/Group.html>, L<article|https://docs.bestpractical.com/rt/5.0.5/RT/Article.html> or L<asset|https://docs.bestpractical.com/rt/5.0.5/RT/Asset.html>).

The condition can be setup on the Admin page for editing the conditioned by L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>. From version 0.99, any L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> can be chosen as the condition L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> (whereas for earlier version, only C<Select> L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> were eligible), and you can specify which operator is to be applied against which value(s) for the condition to be met.

Available operators are:

=over

=item * C<is>

The condition is met if and only if the current value of the L<instanciated conditioned by custom field|https://docs.bestpractical.com/rt/5.0.5/RT/ObjectCustomField.html> is equal to the value (or one of the values, see below for multivalued condition) setup for this condition. With C<isn't> operator described below, C<is> operator is the only one which is eligible for selectable L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> – with C<Select>, C<Combobox> or C<Autocomplete> type –, since their values are to be selected from a set of values. For C<Date> and C<DateTime> L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, this operator is named C<on>.

=item * C<isn't>

The condition is met if and only if the current value of the L<instanciated conditioned by custom field|https://docs.bestpractical.com/rt/5.0.5/RT/Queue.html> is different from the value (or none of the values, see below for multivalued condition) setup for this condition. With C<is> operator described above, C<isn't> operator is the only one which is eligible for selectable L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> – with C<Select>, C<Combobox> or C<Autocomplete> type –, since their values are to be selected from a set of values. For C<Date> and C<DateTime> L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, this operator is named C<not on>.

=item * C<match>

The condition is met if and only if the current value of the L<instanciated conditioned by custom field|https://docs.bestpractical.com/rt/5.0.5/RT/ObjectCustomField.html> is included in the value setup for this condition, typically if the current value is a substring of the condition value. As said above, selectable L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> – with C<Select>, C<Combobox> or C<Autocomplete> type are not eligible for this operator. Also, C<Date> and C<DateTime> L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> are not eligible for this operator.

=item * C<doesn't match>

The condition is met if and only if the current value of the L<instanciated conditioned by custom field|https://docs.bestpractical.com/rt/5.0.5/RT/ObjectCustomField.html> isn't included in the value setup for this condition, typically if the current value isn't a substring of the condition value. As said above, selectable L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> – with C<Select>, C<Combobox> or C<Autocomplete> type are not eligible for this operator. Also, C<Date> and C<DateTime> L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> are not eligible for this operator.

=item * C<less than>

The condition is met if and only if the current value of the L<instanciated conditioned by custom field|https://docs.bestpractical.com/rt/5.0.5/RT/ObjectCustomField.html> is less than or equal to the value setup for this condition. The comparison is achieved according to some kind of L<natural sort order|https://en.wikipedia.org/wiki/Natural_sort_order>, that is: number values are compared as numbers, strings are compared alphabetically, insensitive to case and accents (C<a = á>, C<a = A>). Moreover, IP Adresses (IPv4 and IPv6) are expanded to be compared as expected. As said above, selectable L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> – with C<Select>, C<Combobox> or C<Autocomplete> type are not eligible for this operator.

=item * C<greater than>

The condition is met if and only if the current value of the L<instanciated conditioned by custom field|https://docs.bestpractical.com/rt/5.0.5/RT/ObjectCustomField.html> is greater than or equal to the value setup for this condition. The comparison is achieved according to some kind of L<natural sort order|https://en.wikipedia.org/wiki/Natural_sort_order>, that is: number values are compared as numbers, strings are compared alphabetically, insensitive to case and accents (C<a = á>, C<a = A>), and dates with or without times are compared chronogically. Moreover, IP Adresses (IPv4 and IPv6) are expanded to be compared as expected. As said above, selectable L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> – with C<Select>, C<Combobox> or C<Autocomplete> type are not eligible for this operator.

=item * C<between>

The condition is met if and only if the current value of the L<instanciated conditioned by custom field|https://docs.bestpractical.com/rt/5.0.5/RT/ObjectCustomField.html> is greater than or equal to the first value setup for this condition and is less than or equal to the second value setup for this condition. That means that when this operator is selected, two values have to be entered. The comparison is achieved according to some kind of L<natural sort order|https://en.wikipedia.org/wiki/Natural_sort_order>, that is: number values are compared as numbers, strings are compared alphabetically, insensitive to case and accents (C<a = á>, C<a = A>), and dates with or without times are compared chronogically. Moreover, IP Adresses (IPv4 and IPv6) are expanded to be compared as expected. As said above, selectable L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> – with C<Select>, C<Combobox> or C<Autocomplete> type are not eligible for this operator.

=back

As an exception, C<IPAddressRange> L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> are not eligible as condition L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, since there is not really any sense in comparing two ranges of IP addresses. C<IPAddress> L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, combined with C<between> operator, should be sufficient for most cases checking whether an IP address is included in a range.

If the condition L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> is selectable – with C<Select>, C<Combobox> or C<Autocomplete> type – it can be multivalued. Then, the condition for an object is met as soon as the condition is met by at least one value of the L<instanciated conditioned by custom field|https://docs.bestpractical.com/rt/5.0.5/RT/ObjectCustomField.html> for this object.

If a L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> is based on another (parent) L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> which is conditioned by, this (child) L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> will of course also be conditioned by (with the same condition as its parent). Nevertheless, there is a caveheat in  display mode: the order matters! That is the parent L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> should have a lower sort order than the child L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>.

From version 0.07, the condition can be multivalued, that is: the conditioned L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> can be displayed/edited if the condition L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> has one of these values (In other words: there is an C<OR> bewteen the values of the condition). The condition L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> can be a select custom field with values defined by L<CustomFieldValues|https://docs.bestpractical.com/rt/5.0.5/RT/CustomFieldValues.html> or an L<external custom field|https://docs.bestpractical.com/rt/5.0.5/extending/external_custom_fields.html>.

I<Note that version 0.07 is a complete redesign: the API described below has changed; also, the way that ConditionedBy property is store has changed. If you upgrade from a previous version, you have to reconfigure the custom fields which are conditionned by.>

Version 0.99 is also a complete redesign, with API changed, but backward compatibility with previously configured L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, assuming the default condition operator is C<is>.

From version 1.13, C<HTML> L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> introduced in RT 5.0.3 can be defined as condition L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>.


=head1 RT VERSION

Works with RT 4.2 or greater

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Patch your RT

C<ConditionalCustomFields> still requires a small patch to add necessary C<Callbacks> on versions of RT superior to 4.2.3.

The patch has now been integrated by BestPractical and will be included in future RT releases strictly greater than 5.0.5. In other words patching is still needed on versions of RT up to 5.0.5, but not necessary for versions of RT greater than 5.0.5.

For RT 4.2, apply the included patch:

    cd /opt/rt4 # Your location may be different
    patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.2-add-callbacks-to-extend-customfields-capabilities.patch

For RT 4.4.1, apply the included patch:

    cd /opt/rt4 # Your location may be different
    patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.4.1-add-callbacks-to-extend-customfields-capabilities.patch

For RT 4.4.2 or greater, apply the included patch:

    cd /opt/rt4 # Your location may be different
    patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.4.2-add-callbacks-to-extend-customfields-capabilities.patch

For RT 5.0.0 to 5.0.5, apply the included patch:

    cd /opt/rt5 # Your location may be different
    patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/5.0-add-callbacks-to-extend-customfields-capabilities.patch

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::ConditionalCustomFields');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::ConditionalCustomFields));

or add C<RT::Extension::ConditionalCustomFields> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

Usually, groupings of custom fields, as defined in C<$CustomFieldGroupings> configuration variable, is I<not> enabled in SelfService. This is the case if you use RT Core. Anyway, some RT instances could have overridden this restriction to enable groupings of custom fields in SelfService.

In this case, you should add to your configuration file (F</opt/rt5/etc/RT_SiteConfig.pm>) the following line, setting C<$SelfServiceCustomFieldGroupings> configuration variable to a true value:

    Set($SelfServiceCustomFieldGroupings, 1);

=cut

RT->AddJavaScript('conditional-customfields.js');

package
    RT::CustomField;

=head1 METHODS

C<ConditionalCustomFields> adds a C<ConditionedBy> property, that is a condition L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, an operator and one or more values, along with the following methods, to conditioned by L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> objects:

=head2 SetConditionedBy CF, OP, VALUE

Set the C<ConditionedBy> property for this L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> object to L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> C<CF> with operator set to C<OP> and value set to C<VALUE>. C<CF> should be an existing L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> object or the id of an existing L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> object, or the name of an unambiguous existing L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> object. C<OP> should be C<is>, C<isn't>, C<match>, C<doesn't match>, C<less than>, C<greater than> or C<between>. C<VALUE> should be a string or an anonymous array of strings (for selectable L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> or C<between> operator). Current user should have C<SeeCustomField> and C<ModifyCustomField> rights for this conditioned by L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> and C<SeeCustomField> right for the condition L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>. Returns (1, 'Status message') on success and (0, 'Error Message') on failure.

=cut

sub SetConditionedBy {
    my $self = shift;
    my $cf = shift;
    my $op = shift;
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

    if ($cf->id) {
        # Normalize IpAddresses to sort them as strings
        if ($cf->Type eq 'IPAddress') {
            @values = map { RT::ObjectCustomFieldValue->ParseIP($_); } @values;
        # Convert from Current User Timezone to UTC
        } elsif ($cf->Type eq 'DateTime') {
            @values = map { my $DateObj = RT::Date->new($self->CurrentUser); $DateObj->Set(Format => 'unknown', Value => $_); $DateObj->ISO(Time => 1) } @values;
        }
    }

    sub arrays_identical {
        my( $left, $right ) = @_;
        my @leftary = ref $left eq 'ARRAY' ? @$left : ($left);
        my @rightary = ref $right eq 'ARRAY' ? @$right : ($right);
        return 0 if scalar @$left != scalar @$right;
        my %hash;
        @hash{ @leftary, @rightary } = ();
        return scalar keys %hash == scalar @leftary;
    }

    $op = 'is' unless $op;

    if ($op eq 'between') {
        if (scalar(@values) == 2 && lc($values[0]) gt lc($values[1])) {
            my @sorted_values = reverse @values;
            @values = @sorted_values;
        }
    }

    my $attr = $self->FirstAttribute('ConditionedBy');
    if ($attr && $attr->Content
              && $attr->Content->{CF}
              && $cf->id
              && $attr->Content->{CF} == $cf->id
              && $attr->Content->{op}
              && $attr->Content->{op} eq $op
              && $attr->Content->{vals}
              && arrays_identical($attr->Content->{vals}, \@values)) {
        return (1, $self->loc('ConditionedBy unchanged'));
    }

    if ($cf->id && @values) {
        return (0, "Permission Denied")
            unless $cf->CurrentUserHasRight('SeeCustomField');

        my ($ret, $msg) = $self->SetAttribute(
            Name    => 'ConditionedBy',
            Content => {CF => $cf->id, op => $op, vals => \@values},
        );
        if ($ret) {
            return ($ret, $self->loc('ConditionedBy changed to CustomField #[_1], op:[_2], values [_3]', $cf->id, $op, join(', ', @values)));
        }
        else {
            return ($ret, $self->loc( "Can't change ConditionedBy to CustomField #[_1], op: [_2], values [_3]: [_4]", $cf->id, $op, join(', ', @values), $msg));
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

Returns the current C<ConditionedBy> property for this conditioned by L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> object as a hash with keys C<CF> containing the id of the condition L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, C<op> and C<vals> containing the condition operator as string, and the condition value as an array of strings (so we can store several values for selectable L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> or C<between> operator, but generally the C<vals> array includes only one string). If neither this conditioned by L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> nor one of its ancestor is conditioned by the C<CF> condition L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, that is: if their C<ConditionedBy> property is not (recursively) defined, returns C<undef>. Current user should have C<SeeCustomField> right for both this conditioned by L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> and the condition L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> which this L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> is conditioned recursively by. I<"Recursively"> means that this method will search for a C<ConditionedBy> property for this L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> object, then for the L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> this one is C<BasedOn>, and so on until it finds an ancestor C<Category> with a C<ConditionedBy> property or, the L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> which is being looked up, is not based on any ancestor C<Category>.

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

    # Convert DateTime from UTC to Current User Timezone
    my $conditioned_by = $attr->Content;
    if ($conditioned_by && $conditioned_by->{CF}) {
        my $cf = RT::CustomField->new($self->CurrentUser);
        $cf->Load($conditioned_by->{CF});
        if ($self->ContextObject) {
            $cf = $self->ContextObject->LoadCustomFieldByIdentifier($conditioned_by->{CF});
        }
        if ($cf->id && $cf->Type eq 'DateTime') {
            my $value = $conditioned_by->{vals} || '';
            my @values = ref($value) eq 'ARRAY' ? @$value : ($value);
            for (my $i=0; $i < scalar(@values); $i++) {
                my $DateObj = RT::Date->new($self->CurrentUser);
                $DateObj->Set(Format => 'unknown', Value => $values[$i], Timezone => 'utc');
                $values[$i] = $DateObj->Strftime("%F %T");
            }
            $conditioned_by->{vals} = \@values;
        }
    }

    # Default operator to is for backward compatibility
    $conditioned_by->{op} = 'is' unless exists $conditioned_by->{op};

    return $conditioned_by;
}

sub _findGrouping {
    my $self = shift;
    my ($record_class, $category) = $self->_GroupingClass(shift);
    my $config = RT->Config->Get('CustomFieldGroupings');
    $config = {} unless ref($config) eq 'HASH';
    if ($record_class && defined($config->{$record_class})) {
        my $config_hash = (ref($config->{$record_class} ||= []) eq "ARRAY") ? {@{$config->{$record_class}}} : $category ? (exists $config->{$record_class}->{$category} ? {@{$config->{$record_class}->{$category}}} : {@{$config->{$record_class}->{Default}}}) : {@{$config->{$record_class}->{Default}}};
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
    my $match = $old_MatchPattern->($self, @_);
    my $conditioned_by = $self->ConditionedBy;

    unless (!$conditioned_by || $match) {
        my $mason = $HTML::Mason::Commands::m;
        if ($mason) {
            my %mason_args = @{$mason->current_args};
            if ($mason_args{ARGSRef}) {
                my $condition_cf = RT::CustomField->new($self->CurrentUser);
                $condition_cf->Load($conditioned_by->{CF});
                if ( $self->ContextObject ) {
                    $condition_cf = $self->ContextObject->LoadCustomFieldByIdentifier($conditioned_by->{CF});
                }
                if ($condition_cf->id) {
                    my $condition_grouping = $condition_cf->_findGrouping($self->ContextObject);
                    $condition_grouping =~ s/\W//g if $condition_grouping;
                    my $object = $self->ContextObject;
                    # empty ticket object
                    if (ref($object) eq 'RT::Queue' && $mason_args{ARGSRef}->{id} && $mason_args{ARGSRef}->{id} eq 'new') {
                        $object = RT::Ticket->new($self->CurrentUser);
                    }
                    my $condition_arg = RT::Interface::Web::GetCustomFieldInputName(Object => $object, CustomField => $condition_cf, Grouping => $condition_grouping );

                    my $condition_val = $mason_args{ARGSRef}->{$condition_arg};
                    my @condition_vals = ref($condition_val) eq 'ARRAY' ? @$condition_val : ($condition_val);
                    my $condition_met = 0;
                    foreach my $val (@condition_vals) {
                        if (grep {$_ eq $val} @{$conditioned_by->{vals}}) {
                            $condition_met = 1;
                            last;
                        }
                    }
                    $match = 1 unless $condition_met;
                }
            }
        } else {
            my $object = $self->ContextObject;
            my $condition_vals = $object->CustomFieldValues($conditioned_by->{CF});
            my $condition_met = 0;
            while (my $condition_val = $condition_vals->Next) {
                if (grep {$_ eq $condition_val->Content} @{$conditioned_by->{vals}}) {
                    $condition_met = 1;
                    last;
                }
            }
            $match = 1 unless $condition_met;
        }
    }

    return $match;
};

=head1 INITIALDATA

Also, C<ConditionalCustomFields> allows to set the C<ConditionedBy> property when creating L<CustomFields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomFields.html> from an F<initialdata> file, with one of the following syntaxes:

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
                { Name => 'Schrödingerized', SortOrder => 2 },
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
            ConditionOp => "isn't",
            ConditionedBy => 'Failed',
        },
        {
            Name => 'Conditioned with multiple values',
            Type => 'Freeform',
            MaxValues => 1,
            Queue => [ 'General' ],
            LookupType => 'RT::Queue-RT::Ticket',
            ConditionedByCF => 'Condition',
            ConditionedBy => ['Passed', 'Schrödingerized'],
        },
    );

This examples creates a C<Select> condition L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, named C<Condition> and three conditioned by L<CustomFields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>. L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> C<Condition> should have the value C<Passed>, for L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> C<Conditioned with cf name and value> to be displayed or edited. L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> C<Condition> should not have the value C<Failed> for L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> C<Conditioned with cf id and value> to be displayed or edited. L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> C<Condition> should have one of the values C<Passed> or C<Schrödingerized> for L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> C<Conditioned with multiple values> to be displayed or edited.

Additional fields for an element of C<@CustomFields> are:

=over

=item C<ConditonedByCF>

The condition L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> that this new L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> should conditioned by. It can be either the C<id> or the C<Name> of a previously created L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>. This implies that the condition L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> should be declared before this one in the F<initialdata> file, or it should already exist. When C<ConditionedByCF> attribute is set, C<ConditionedBy> field should always also be set.

=item C<ConditonedBy>

The value as a C<string> of the condition L<CustomField|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> defined by the C<ConditionedByCF> field (which is mandatory).

=item C<ConditonOp>

The operator as a C<string> to use for comparison, either C<is>, C<isn't>, C<match>, C<doesn't match>, C<less than>, C<greater than> or C<between>. This field is optional, defaults to C<is>.

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
                my $conditioned_by_op;
                my $conditioned_by_value;
                if ($item->{'ConditionedBy'}) {
                    $conditioned_by_value = $item->{'ConditionedBy'};
                    $conditioned_by_op = $item->{'ConditionedByOp'} || 'is';
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
                    my ($ret, $msg) = $conditional_cf->SetConditionedBy($conditioned_by_cfid, $conditioned_by_op, $conditioned_by_value);
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

=head1 TEST SUITE

C<ConditionalCustomFields> comes with a fairly complete test suite. As for every L<RT extention|https://docs.bestpractical.com/rt/5.0.5/writing_extensions.html#Tests>, to run it, you will need a installed C<RT>, set up in L<development mode|https://docs.bestpractical.com/rt/5.0.5/hacking.html#Test-suite>. But, since C<ConditionalCustomFields> operates dynamically to show or hide L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, most of its magic happens in C<Javascript>. Therefore, the test suite requires a scriptable headless browser with C<Javascript> capabilities. So you also need to install L<PhantomJS|http://phantomjs.org/>, along with L<WWW::Mechanize::PhantomJS> and L<Selenium::Remote::Driver>.

It should be noted that with version 0.99, the number of cases to test has exponentially expanded. Not only any object which can have custom fields (L<ticket|https://docs.bestpractical.com/rt/5.0.5/RT/Ticket.html>, L<queue|https://docs.bestpractical.com/rt/5.0.5/RT/Queue.html>, L<user|https://docs.bestpractical.com/rt/5.0.5/RT/User.html>, L<group|https://docs.bestpractical.com/rt/5.0.5/RT/Group.html>, L<article|https://docs.bestpractical.com/rt/5.0.5/RT/Article.html> or L<asset|https://docs.bestpractical.com/rt/5.0.5/RT/Asset.html>) should be tested. But also, any type of L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> (C<Select>, C<Freeform>, C<Text>, C<Wikitext>, C<Image>, C<Binary>, C<Combobox>, C<Autocomplete>, C<Date>, C<DateTime> and C<IPAddress>) should be tested both for condition L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> and conditioned by L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>. And this both for C<Single> and C<Multiple> versions (when available) of each type of L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>. C<Select> L<custom fields|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> should also be tested for each render type (C<Select box>, C<List>, C<Dropdown> and also C<Chosen> when the number of values is greater than ten). Adding to these required unitary tests, some special cases should also be included, for instance when a condition L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> is in turn conditioned by another condition L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html>, or when a condition L<custom field|https://docs.bestpractical.com/rt/5.0.5/RT/CustomField.html> is not applied to a L<queue|https://docs.bestpractical.com/rt/5.0.5/RT/Queue.html>, etc. Eventually, the test suite includes 1929 unitary tests and 64 test files. Nevertheless some special cases may have been left over, so you're encourage to fill a bug report, so they can be fixed.

=head1 AUTHOR

Gérald Sédrati E<lt>gibus@easter-eggs.comE<gt>

=head1 REPOSITORY

L<https://github.com/gibus/RT-Extension-ConditionalCustomFields>

=head1 BUGS

All bugs should be reported via email to

L<bug-RT-Extension-ConditionalCustomFields@rt.cpan.org|mailto:bug-RT-Extension-ConditionalCustomFields@rt.cpan.org>

or via the web at

L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ConditionalCustomFields>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2017-2023 by Gérald Sédrati, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007

=cut

1;
