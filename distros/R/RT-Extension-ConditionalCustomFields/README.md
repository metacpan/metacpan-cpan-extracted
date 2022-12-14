# NAME

RT::Extension::ConditionalCustomFields - CF conditioned by the value of another CF

# DESCRIPTION

This plugin provides the ability to display/edit a [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) – called the "conditioned by [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html)" throughout this documentation – conditioned by the value of another [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) – the "condition [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html)" – for the same object, which can be anything that can have custom fields ([ticket](https://docs.bestpractical.com/rt/5.0.3/RT/Ticket.html), [queue](https://docs.bestpractical.com/rt/5.0.3/RT/Queue.html), [user](https://docs.bestpractical.com/rt/5.0.3/RT/User.html), [group](https://docs.bestpractical.com/rt/5.0.3/RT/Group.html), [article](https://docs.bestpractical.com/rt/5.0.3/RT/Article.html) or [asset](https://docs.bestpractical.com/rt/5.0.3/RT/Asset.html)).

The condition can be setup on the Admin page for editing the conditioned by [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html). From version 0.99, any [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) can be chosen as the condition [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) (whereas for earlier version, only `Select` [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) were eligible), and you can specify which operator is to be applied against which value(s) for the condition to be met.

Available operators are:

- `is`

    The condition is met if and only if the current value of the [instanciated conditioned by custom field](https://docs.bestpractical.com/rt/5.0.3/RT/ObjectCustomField.html) is equal to the value (or one of the values, see below for multivalued condition) setup for this condition. With `isn't` operator described below, `is` operator is the only one which is eligible for selectable [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) – with `Select`, `Combobox` or `Autocomplete` type –, since their values are to be selected from a set of values. For `Date` and `DateTime` [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), this operator is named `on`.

- `isn't`

    The condition is met if and only if the current value of the [instanciated conditioned by custom field](https://docs.bestpractical.com/rt/5.0.3/RT/Queue.html) is different from the value (or none of the values, see below for multivalued condition) setup for this condition. With `is` operator described above, `isn't` operator is the only one which is eligible for selectable [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) – with `Select`, `Combobox` or `Autocomplete` type –, since their values are to be selected from a set of values. For `Date` and `DateTime` [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), this operator is named `not on`.

- `match`

    The condition is met if and only if the current value of the [instanciated conditioned by custom field](https://docs.bestpractical.com/rt/5.0.3/RT/ObjectCustomField.html) is included in the value setup for this condition, typically if the current value is a substring of the condition value. As said above, selectable [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) – with `Select`, `Combobox` or `Autocomplete` type are not eligible for this operator. Also, `Date` and `DateTime` [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) are not eligible for this operator.

- `doesn't match`

    The condition is met if and only if the current value of the [instanciated conditioned by custom field](https://docs.bestpractical.com/rt/5.0.3/RT/ObjectCustomField.html) isn't included in the value setup for this condition, typically if the current value isn't a substring of the condition value. As said above, selectable [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) – with `Select`, `Combobox` or `Autocomplete` type are not eligible for this operator. Also, `Date` and `DateTime` [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) are not eligible for this operator.

- `less than`

    The condition is met if and only if the current value of the [instanciated conditioned by custom field](https://docs.bestpractical.com/rt/5.0.3/RT/ObjectCustomField.html) is less than or equal to the value setup for this condition. The comparison is achieved according to some kind of [natural sort order](https://en.wikipedia.org/wiki/Natural_sort_order), that is: number values are compared as numbers, strings are compared alphabetically, insensitive to case and accents (`a = á`, `a = A`). Moreover, IP Adresses (IPv4 and IPv6) are expanded to be compared as expected. As said above, selectable [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) – with `Select`, `Combobox` or `Autocomplete` type are not eligible for this operator.

- `greater than`

    The condition is met if and only if the current value of the [instanciated conditioned by custom field](https://docs.bestpractical.com/rt/5.0.3/RT/ObjectCustomField.html) is greater than or equal to the value setup for this condition. The comparison is achieved according to some kind of [natural sort order](https://en.wikipedia.org/wiki/Natural_sort_order), that is: number values are compared as numbers, strings are compared alphabetically, insensitive to case and accents (`a = á`, `a = A`), and dates with or without times are compared chronogically. Moreover, IP Adresses (IPv4 and IPv6) are expanded to be compared as expected. As said above, selectable [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) – with `Select`, `Combobox` or `Autocomplete` type are not eligible for this operator.

- `between`

    The condition is met if and only if the current value of the [instanciated conditioned by custom field](https://docs.bestpractical.com/rt/5.0.3/RT/ObjectCustomField.html) is greater than or equal to the first value setup for this condition and is less than or equal to the second value setup for this condition. That means that when this operator is selected, two values have to be entered. The comparison is achieved according to some kind of [natural sort order](https://en.wikipedia.org/wiki/Natural_sort_order), that is: number values are compared as numbers, strings are compared alphabetically, insensitive to case and accents (`a = á`, `a = A`), and dates with or without times are compared chronogically. Moreover, IP Adresses (IPv4 and IPv6) are expanded to be compared as expected. As said above, selectable [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) – with `Select`, `Combobox` or `Autocomplete` type are not eligible for this operator.

As an exception, `IPAddressRange` [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) are not eligible as condition [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), since there is not really any sense in comparing two ranges of IP addresses. `IPAddress` [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), combined with `between` operator, should be sufficient for most cases checking whether an IP address is included in a range.

If the condition [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) is selectable – with `Select`, `Combobox` or `Autocomplete` type – it can be multivalued. Then, the condition for an object is met as soon as the condition is met by at least one value of the [instanciated conditioned by custom field](https://docs.bestpractical.com/rt/5.0.3/RT/ObjectCustomField.html) for this object.

If a [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) is based on another (parent) [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) which is conditioned by, this (child) [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) will of course also be conditioned by (with the same condition as its parent).
From version 0.07, the condition can be multivalued, that is: the conditioned [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) can be displayed/edited if the condition [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) has one of these values (In other words: there is an `OR` bewteen the values of the condition). The condition [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) can be a select custom field with values defined by [CustomFieldValues](https://docs.bestpractical.com/rt/5.0.3/RT/CustomFieldValues.html) or an [external custom field](https://docs.bestpractical.com/rt/5.0.3/extending/external_custom_fields.html).

_Note that version 0.07 is a complete redesign: the API described below has changed; also, the way that ConditionedBy property is store has changed. If you upgrade from a previous version, you have to reconfigure the custom fields which are conditionned by._

Version 0.99 is also a complete redesign, with API changed, but backward compatibility with previously configured [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), assuming the default condition operator is `is`.

# RT VERSION

Works with RT 4.2 or greater

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions

- Patch your RT

    `ConditionalCustomFields` requires a small patch to add necessary `Callbacks` on versions of RT superior to 4.2.3. (The patch has been submitted to BestPractical in order to be included in future RT releases, as of RT 4.4.2, some parts of the patch are already included, but some other parts still required to apply this patch.)

    For RT 4.2, apply the included patch:

        cd /opt/rt4 # Your location may be different
        patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.2-add-callbacks-to-extend-customfields-capabilities.patch

    For RT 4.4.1, apply the included patch:

        cd /opt/rt4 # Your location may be different
        patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.4.1-add-callbacks-to-extend-customfields-capabilities.patch

    For RT 4.4.2 or greater, apply the included patch:

        cd /opt/rt4 # Your location may be different
        patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/4.4.2-add-callbacks-to-extend-customfields-capabilities.patch

    For RT 5.0.0 or greater, apply the included patch:

        cd /opt/rt5 # Your location may be different
        patch -p1 < /download/dir/RT-Extension-ConditionalCustomFields/patches/5.0-add-callbacks-to-extend-customfields-capabilities.patch

- Edit your `/opt/rt5/etc/RT_SiteConfig.pm`

    If you are using RT 4.2 or greater, add this line:

        Plugin('RT::Extension::ConditionalCustomFields');

    For RT 4.0, add this line:

        Set(@Plugins, qw(RT::Extension::ConditionalCustomFields));

    or add `RT::Extension::ConditionalCustomFields` to your existing `@Plugins` line.

- Clear your mason cache

        rm -rf /opt/rt5/var/mason_data/obj

- Restart your webserver

# CONFIGURATION

Usually, groupings of custom fields, as defined in `$CustomFieldGroupings` configuration variable, is _not_ enabled in SelfService. This is the case if you use RT Core. Anyway, some RT instances could have overridden this restriction to enable groupings of custom fields in SelfService.

In this case, you should add to your configuration file (`/opt/rt5/etc/RT_SiteConfig.pm`) the following line, setting `$SelfServiceCustomFieldGroupings` configuration variable to a true value:

    Set($SelfServiceCustomFieldGroupings, 1);

# METHODS

`ConditionalCustomFields` adds a `ConditionedBy` property, that is a condition [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), an operator and one or more values, along with the following methods, to conditioned by [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) objects:

## SetConditionedBy CF, OP, VALUE

Set the `ConditionedBy` property for this [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) object to [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) `CF` with operator set to `OP` and value set to `VALUE`. `CF` should be an existing [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) object or the id of an existing [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) object, or the name of an unambiguous existing [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) object. `OP` should be `is`, `isn't`, `match`, `doesn't match`, `less than`, `greater than` or `between`. `VALUE` should be a string or an anonymous array of strings (for selectable [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) or `between` operator). Current user should have `SeeCustomField` and `ModifyCustomField` rights for this conditioned by [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) and `SeeCustomField` right for the condition [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html). Returns (1, 'Status message') on success and (0, 'Error Message') on failure.

## ConditionedBy

Returns the current `ConditionedBy` property for this conditioned by [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) object as a hash with keys `CF` containing the id of the condition [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), `op` and `vals` containing the condition operator as string, and the condition value as an array of strings (so we can store several values for selectable [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) or `between` operator, but generally the `vals` array includes only one string). If neither this conditioned by [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) nor one of its ancestor is conditioned by the `CF` condition [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), that is: if their `ConditionedBy` property is not (recursively) defined, returns `undef`. Current user should have `SeeCustomField` right for both this conditioned by [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) and the condition [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) which this [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) is conditioned recursively by. _"Recursively"_ means that this method will search for a `ConditionedBy` property for this [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) object, then for the [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) this one is `BasedOn`, and so on until it finds an ancestor `Category` with a `ConditionedBy` property or, the [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) which is being looked up, is not based on any ancestor `Category`.

# INITIALDATA

Also, `ConditionalCustomFields` allows to set the `ConditionedBy` property when creating [CustomFields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomFields.html) from an `initialdata` file, with one of the following syntaxes:

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

This examples creates a `Select` condition [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), named `Condition` and three conditioned by [CustomFields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html). [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) `Condition` should have the value `Passed`, for [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) `Conditioned with cf name and value` to be displayed or edited. [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) `Condition` should not have the value `Failed` for [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) `Conditioned with cf id and value` to be displayed or edited. [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) `Condition` should have one of the values `Passed` or `Schrödingerized` for [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) `Conditioned with multiple values` to be displayed or edited.

Additional fields for an element of `@CustomFields` are:

- `ConditonedByCF`

    The condition [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) that this new [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) should conditioned by. It can be either the `id` or the `Name` of a previously created [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html). This implies that the condition [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) should be declared before this one in the `initialdata` file, or it should already exist. When `ConditionedByCF` attribute is set, `ConditionedBy` field should always also be set.

- `ConditonedBy`

    The value as a `string` of the condition [CustomField](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) defined by the `ConditionedByCF` field (which is mandatory).

- `ConditonOp`

    The operator as a `string` to use for comparison, either `is`, `isn't`, `match`, `doesn't match`, `less than`, `greater than` or `between`. This field is optional, defaults to `is`.

# TEST SUITE

`ConditionalCustomFields` comes with a fairly complete test suite. As for every [RT extention](https://docs.bestpractical.com/rt/5.0.3/writing_extensions.html#Tests), to run it, you will need a installed `RT`, set up in [development mode](https://docs.bestpractical.com/rt/5.0.3/hacking.html#Test-suite). But, since `ConditionalCustomFields` operates dynamically to show or hide [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), most of its magic happens in `Javascript`. Therefore, the test suite requires a scriptable headless browser with `Javascript` capabilities. So you also need to install [PhantomJS](http://phantomjs.org/), along with [WWW::Mechanize::PhantomJS](https://metacpan.org/pod/WWW::Mechanize::PhantomJS) and [Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver).

It should be noted that with version 0.99, the number of cases to test has exponentially expanded. Not only any object which can have custom fields ([ticket](https://docs.bestpractical.com/rt/5.0.3/RT/Ticket.html), [queue](https://docs.bestpractical.com/rt/5.0.3/RT/Queue.html), [user](https://docs.bestpractical.com/rt/5.0.3/RT/User.html), [group](https://docs.bestpractical.com/rt/5.0.3/RT/Group.html), [article](https://docs.bestpractical.com/rt/5.0.3/RT/Article.html) or [asset](https://docs.bestpractical.com/rt/5.0.3/RT/Asset.html)) should be tested. But also, any type of [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) (`Select`, `Freeform`, `Text`, `Wikitext`, `Image`, `Binary`, `Combobox`, `Autocomplete`, `Date`, `DateTime` and `IPAddress`) should be tested both for condition [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) and conditioned by [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html). And this both for `Single` and `Multiple` versions (when available) of each type of [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html). `Select` [custom fields](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) should also be tested for each render type (`Select box`, `List`, `Dropdown` and also `Chosen` when the number of values is greater than ten). Adding to these required unitary tests, some special cases should also be included, for instance when a condition [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) is in turn conditioned by another condition [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html), or when a condition [custom field](https://docs.bestpractical.com/rt/5.0.3/RT/CustomField.html) is not applied to a [queue](https://docs.bestpractical.com/rt/5.0.3/RT/Queue.html), etc. Eventually, the test suite includes 1929 unitary tests and 64 test files. Nevertheless some special cases may have been left over, so you're encourage to fill a bug report, so they can be fixed.

# AUTHOR

Gérald Sédrati <gibus@easter-eggs.com>

# REPOSITORY

[https://github.com/gibus/RT-Extension-ConditionalCustomFields](https://github.com/gibus/RT-Extension-ConditionalCustomFields)

# BUGS

All bugs should be reported via email to

[bug-RT-Extension-ConditionalCustomFields@rt.cpan.org](mailto:bug-RT-Extension-ConditionalCustomFields@rt.cpan.org)

or via the web at

[rt.cpan.org](http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ConditionalCustomFields).

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2017-2022 by Gérald Sédrati, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007
