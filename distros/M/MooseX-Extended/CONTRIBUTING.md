# Contributing

Contributors are very welcome!

# Bug Fixes and Typos

For minor fixes, you can [open an
issue](https://github.com/Ovid/moosex-extreme/issues), but a pull request
(with tests, if appropriate) is very welcome.

I do not accept patches. I've found them too much of a pain to apply.

# New Features

If you would like a feature added, please [open an
issue](https://github.com/Ovid/moosex-extreme/issues) first so we can discuss
it.

# Changes

Please add an entry to the `Changes` file for anything you do.

# Non-backwards Compatible Features

Currently, [MooseX::Extended](https://metacpan.org/pod/MooseX::Extended)
allows configuration via import lists:

    use MooseX::Extended
        types    => [qw/HashRef ArrayRef/],
        excludes => [qw/StrictConstructor/];

We may add a new `includes` feature if a change:

* Does not backport to `v5.20.0`
* Breaks existing `MooseX::Extended` code
* Is controversial

For example:

    use MooseX::Extended includes => [qw/some_new_feature/];

This is not yet implemented. The key idea here is that we want to be safe and
not break existing code.
