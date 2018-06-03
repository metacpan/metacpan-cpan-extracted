# NAME

RT::Extension::ConditionalCustomFields - CF conditionned by the value of another CF

# DESCRIPTION

Provide the ability to display/edit a [custom field](https://metacpan.org/pod/RT::CustomField) conditioned by the value of another (select) [custom field](https://metacpan.org/pod/RT::CustomField) for the same object, which can be anything that can have custom fields ([ticket](https://metacpan.org/pod/RT::Ticket), [queue](https://metacpan.org/pod/RT::Queue), [user](https://metacpan.org/pod/RT::User), [group](https://metacpan.org/pod/RT::Group), [article](https://metacpan.org/pod/RT::Article) or [asset](https://metacpan.org/pod/RT::Asset)).

If a [custom field](https://metacpan.org/pod/RT::CustomField) is based on another (parent) [custom field](https://metacpan.org/pod/RT::CustomField) which is conditioned by, this (child) [custom field](https://metacpan.org/pod/RT::CustomField) will of course also be conditioned by (with the same condition as its parent).

If the condition [custom field](https://metacpan.org/pod/RT::CustomField) is a multivalued select, the condition for an object is met as soon as the condition is met by at least one value of the [instanciated custom field](https://metacpan.org/pod/RT::ObjectCustomField) for this object.

From version 0.07, the condition can be multivalued, that is: the conditioned [custom field](https://metacpan.org/pod/RT::CustomField) can be displayed/edited if the condition [custom field](https://metacpan.org/pod/RT::CustomField) has one of these values (In other words: there is an `OR` bewteen the values of the condition). The condition [custom field](https://metacpan.org/pod/RT::CustomField) can be a select custom field with values defined by [CustomFieldValues](https://metacpan.org/pod/RT::CustomFieldValues) or an [external custom field](https://metacpan.org/pod/RT::CustomFieldValues::External).

_Note that version 0.07 is a complete redesign: the API described below has changed; also, the way that ConditionedBy property is store has changed. If you upgrade from a previous version, you have to reconfigure the custom fields which are conditionned by._

# RT VERSION

Works with RT 4.2 or greater

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions

- Patch your RT

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

ConditionalCustomFields adds a ConditionedBy property, that is a [CustomField](https://metacpan.org/pod/RT::CustomField) and a value, along with the following methods, to [RT::CustomField](https://metacpan.org/pod/RT::CustomField) objets:

## SetConditionedBy CF, VALUE

Set the ConditionedBy property for this [CustomField](https://metacpan.org/pod/RT::CustomField) object to [CustomFieldValue](https://metacpan.org/pod/RT::CustomField) `CF` with value set to `VALUE`. `CF` should be an existing [CustomField](https://metacpan.org/pod/RT::CustomField) object or the id of an existing [CustomField](https://metacpan.org/pod/RT::CustomField) object, or the name of an unambiguous existing [CustomField](https://metacpan.org/pod/RT::CustomField) object. `VALUE` should be a string. Current user should have `SeeCustomField` and `ModifyCustomField` rights for this [CustomField](https://metacpan.org/pod/RT::CustomField) and `SeeCustomField` right for the [CustomField](https://metacpan.org/pod/RT::CustomField) which this [CustomField](https://metacpan.org/pod/RT::CustomField) is conditionned by. Returns (1, 'Status message') on success and (0, 'Error Message') on failure.

## ConditionedBy

Returns the current `ConditionedBy` property for this [CustomField](https://metacpan.org/pod/RT::CustomField) object as a hash with keys `CF` containing the id of the [CustomField](https://metacpan.org/pod/RT::CustomField) which this  [CustomField](https://metacpan.org/pod/RT::CustomField) is recursively conditionned by, and `val` containing the value as string. If neither this [CustomField](https://metacpan.org/pod/RT::CustomField) object nor one of its ancestor is conditioned by another one, that is: if their `ConditionedBy` property is not (recursively) defined, returns `undef`. Current user should have `SeeCustomField` right for both this [CustomField](https://metacpan.org/pod/RT::CustomField) and the [CustomField](https://metacpan.org/pod/RT::CustomField) which this [CustomField](https://metacpan.org/pod/RT::CustomField) is conditionned recursively by. _"Recursively"_ means that this method will search for a `ConditionedBy` property for this [CustomField](https://metacpan.org/pod/RT::CustomField) object, then for the [CustomField](https://metacpan.org/pod/RT::CustomField) this one is `BasedOn`, and so on until it find an acestor `Category` with a `ConditionedBy` property or, the [CustomField](https://metacpan.org/pod/RT::CustomField) which is being looked up, is not based on any ancestor `Category`.

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

This examples creates a select CustomField `Condition` which should have the value `Passed`, for CustomFields `Conditioned with cf name and value` and `Conditioned with cf id and value` to be displayed or edited.

Additional fields for an element of `@CustomFields` are:

- `ConditonedByCF`

    The [CustomField](https://metacpan.org/pod/RT::CustomField) that this new [CustomField](https://metacpan.org/pod/RT::CustomField) should conditionned by. It can be either the `id` or the `Name` of a previously created [CustomField](https://metacpan.org/pod/RT::CustomField). This implies that this [CustomField](https://metacpan.org/pod/RT::CustomField) should be declared before this one in the `initialdata` file, or it should already exist. When `ConditionedByCF` attribute is set, `ConditionedBy` attribute should always also be set.

- `ConditonedBy`

    The value as a `string` of the [CustomField](https://metacpan.org/pod/RT::CustomField) defined by the `ConditionedByCF` attribute (which is mandatory).

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
