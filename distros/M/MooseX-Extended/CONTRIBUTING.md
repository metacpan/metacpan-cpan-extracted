# Contributing

Contributors are very welcome!

# Bug Fixes and Typos

For minor fixes, you can [open an
issue](https://github.com/Ovid/moosex-extended/issues), but a pull request
(with tests, if appropriate) is very welcome.

I do not accept patches. I've found them too much of a pain to apply.

# New Features

If you would like a feature added, please [open an
issue](https://github.com/Ovid/moosex-extended/issues) first so we can discuss
it.

# Changes

Please add an entry to the `Changes` file for anything you do.

Also, do not edit the `Makefile.pl`. It's auto-generated from the `dist.ini`
file and your changes will be overwritten.

# Non-backwards Compatible Features

Currently, [MooseX::Extended](https://metacpan.org/pod/MooseX::Extended)
allows configuration via import lists:

    use MooseX::Extended
        types    => [qw/HashRef ArrayRef/],
        excludes => ['StrictConstructor'],
		includes => ['async'];

If you wish to extend `MooseX::Extended`, please use the C<includes> flag if
the code:

* Does not backport to `v5.20.0`
* Breaks existing `MooseX::Extended` code
* Is controversial

For example:

    use MooseX::Extended includes => [qw/multi/];

The `includes` are defined in `MooseX::Extended::Core`, in
`_default_import_list` and the features are applied in
`_apply_optional_features`.
