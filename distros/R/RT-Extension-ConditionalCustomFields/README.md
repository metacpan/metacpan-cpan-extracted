# NAME

RT-Extension-ConditionalCustomFields - CF conditionned by the value of another CF

# DESCRIPTION

Provide the ability to display/edit a custom field conditioned by the value of another (select) custom field for the same object, which can be anything that can have custom fields ([ticket](https://metacpan.org/pod/RT::Ticket), [queue](https://metacpan.org/pod/RT::Queue), [user](https://metacpan.org/pod/RT::User), [group](https://metacpan.org/pod/RT::Group), [article](https://metacpan.org/pod/RT::Article) or [asset](https://metacpan.org/pod/RT::Asset)).

# RT VERSION

Works with RT 4.2 or greater

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions

- Patch your RT

    ConditionalCustomFields requires a small patch to add necessary Callbacks on versions of RT prior to 4.2.3.

    For RT 4.2, apply the included patch:

        cd /opt/rt4 # Your location may be different
        patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.2-add-callbacks-to-extend-customfields-capabilities.patch

    For RT 4.4, apply the included patch:

        cd /opt/rt4 # Your location may be different
        patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.4-add-callbacks-to-extend-customfields-capabilities.patch

- Edit your `/opt/rt4/etc/RT_SiteConfig.pm`

    If you are using RT 4.2 or greater, add this line:

        Plugin('RT::Extension::ConditionalCustomFields');

    For RT 4.0, add this line:

        Set(@Plugins, qw(RT::Extension::ConditionalCustomFields));

    or add `RT::Extension::ConditionalCustomFields` to your existing `@Plugins` line.

- Clear your mason cache

        rm -rf /opt/rt4/var/mason_data/obj

- Restart your webserver

# METHODS

ConditionalCustomFields adds a ConditionedBy property, along with the following methods, to [RT::CustomField](https://metacpan.org/pod/RT::CustomField) objets:

## SetConditionedBy VALUE

Set ConditionedBy for this [CustomField](https://metacpan.org/pod/RT::CustomField) object to VALUE. If VALUE is numerical, it should be the id of an existing [CustomFieldValue](https://metacpan.org/pod/RT::CustomFieldValue) object. Otherwise, VALUE should be an existing [CustomFieldValue](https://metacpan.org/pod/RT::CustomFieldValue) object. Current user should have SeeCustomField and ModifyCustomField rights for this CustomField and SeeCustomField right for the CustomField which this CustomField is conditionned by. Returns (1, 'Status message') on success and (0, 'Error Message') on failure.

## ConditionedByObj

Returns the current value as a [CustomFieldValue](https://metacpan.org/pod/RT::CustomFieldValue) object of the ConditionedBy property for this [CustomField](https://metacpan.org/pod/RT::CustomField) object. If this [CustomField](https://metacpan.org/pod/RT::CustomField) object is not conditioned by another one, that is: if its ConditionedBy property is not defined, returns an empty [CustomFieldValue](https://metacpan.org/pod/RT::CustomFieldValue) object (without id). Current user should have SeeCustomField right for both this CustomField and the CustomField which this CustomField is conditionned by.

## ConditionedByAsString

Returns the current value as a `string` of the ConditionedBy property for this [CustomField](https://metacpan.org/pod/RT::CustomField) object. If this [CustomField](https://metacpan.org/pod/RT::CustomField) object is not conditioned by another one, that is: if its ConditionedBy property is not defined, returns undef. Current user should have SeeCustomField right for both this CustomField and the CustomField which this CustomField is conditionned by.

## ConditionedByCustomField

Returns the  [CustomField](https://metacpan.org/pod/RT::CustomField) object that this CustomField is recursively conditionned by. "Recursively" means that this method will search for a ConditionedBy property for this [CustomField](https://metacpan.org/pod/RT::CustomField) object, then for the Customfield this one is BasedOn, and so on until it find an acestor category with a ConditionedBy property or, the Customfield which is being looked up, is not based on any ancestor category. If neither this [CustomField](https://metacpan.org/pod/RT::CustomField) object nor one of its ancestor is conditioned by another one, that is: if their ConditionedBy property is (recursively) not defined, returns undef. Current user should have SeeCustomField right for both this CustomField and the CustomField which this CustomField is conditionned by.

## ConditionedByCustomFieldValue

Returns the current value as a [CustomFieldValue](https://metacpan.org/pod/RT::CustomFieldValue) object that this CustomField is recursively conditionned by. "Recursively" means that this method will search for a ConditionedBy property for this [CustomField](https://metacpan.org/pod/RT::CustomField) object, then for the Customfield this one is BasedOn, and so on until it find an acestor category with a ConditionedBy property or, the Customfield which is being looked up, is not based on any ancestor category. If neither this [CustomField](https://metacpan.org/pod/RT::CustomField) object nor one of its ancestor is conditioned by another one, that is: if their ConditionedBy property is (recursively) not defined, returns an empty [CustomField](https://metacpan.org/pod/RT::CustomField) object (without id). Current user should have SeeCustomField right for both this CustomField and the CustomField which this CustomField is conditionned by.

# INITIALDATA

Also, ConditionalCustomFields allows to set the ConditionedBy property when creating CustomFields from an `initialdata` file, with one of the following syntaxes:

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

This examples creates a select CustomField `Condition` which should have the value `Passed`, for CustomFields `Conditioned with cf and value` and `Conditioned with cf id and value` to be displayed or edited. It also created a CustomField `Conditioned with cf value id` that is conditionned by another CustomField for the current object ([ticket](https://metacpan.org/pod/RT::Ticket), [queue](https://metacpan.org/pod/RT::Queue), [user](https://metacpan.org/pod/RT::User|), [group](https://metacpan.org/pod/RT::Group), or [article](https://metacpan.org/pod/RT::Article)) having a `CustomFieldValue` with `id = 52`.

Additional fields for an element of `@CustomFields` are:

- `ConditonedBy`

    The [CustomFieldValue](https://metacpan.org/pod/RT::CustomFieldValue) that this new [CustomField](https://metacpan.org/pod/RT::CustomField) should conditionned by. It can be either the `id` of an existing [CustomFieldValue](https://metacpan.org/pod/RT::CustomFieldValue) object (in which case attribute `ConditionedByCF` is ignored), or the value as a `string` of the [CustomField](https://metacpan.org/pod/RT::CustomField) attribute (which is then mandatory).

- `ConditonedByCF`

    The [CustomField](https://metacpan.org/pod/RT::CustomField) that this new [CustomField](https://metacpan.org/pod/RT::CustomField) should conditionned by. It can be either the `id` or the `Name` of a previously created [CustomField](https://metacpan.org/pod/RT::CustomField). This implies that this [CustomField](https://metacpan.org/pod/RT::CustomField) should be declared before this one in the `initialdata` file, or it should already exist. When `ConditionedByCF` attribute is set, `ConditionedBy` attribute should always also be set.

# AUTHOR

Gérald Sédrati-Dinet <gibus@easter-eggs.com>

# REPOSITORY

[https://github.com/gibus/RT-Extension-ConditionalCustomFields](https://github.com/gibus/RT-Extension-ConditionalCustomFields)

# BUGS

All bugs should be reported via email to

[bug-RT-Extension-ConditionalCustomFields@rt.cpan.org](mailto:bug-RT-Extension-ConditionalCustomFields@rt.cpan.org)

or via the web at

[rt.cpan.org](http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ConditionalCustomFields).

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2017 by Gérald Sédrati-Dinet, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007
