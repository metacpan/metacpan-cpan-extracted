# NAME

Params::Get - Get the parameters to a subroutine in any way you want

# VERSION

Version 0.14

# DESCRIPTION

Exports a single function, `get_params`, which returns a given value.

When used hand-in-hand with [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) and [Return::Set](https://metacpan.org/pod/Return%3A%3ASet),
you should be able to formally specify the input and output sets for a method.

# SYNOPSIS

    use Params::Get;
    use Params::Validate::Strict;

    sub where_am_i
    {
        my $params = Params::Validate::Strict::validate_strict({
            args => Params::Get::get_params(undef, \@_),
            schema => {
                'latitude' => {
                    type => 'number',
                    min => -90,
                    max => 90
                }, 'longitude' => {
                    type => 'number',
                    min => -180,
                    max => 180
                }
            }
        });

        print 'You are at ', $params->{'latitude'}, ', ', $params->{'longitude'}, "\n";
    }

    where_am_i(latitude => 0.3, longitude => 124);
    where_am_i({ latitude => 3.14, longitude => -155 });

# METHODS

## get\_params

Parse the arguments given to a function.
Processes arguments passed to methods and ensures they are in a usable format,
allowing the caller to call the function in any way that they want
e.g. \`foo('bar')\`, \`foo(arg => 'bar')\`, \`foo({ arg => 'bar' })\` all mean the same
when called with

    get_params('arg', @_);

or

    get_params('arg', \@_);

Some people like this sort of model, which is also supported.

    use MyClass;

    my $str = 'hello world';
    my $obj = MyClass->new($str, { type => 'string' });

    package MyClass;

    use Params::Get;

    sub new {
        my $class = shift;
        my $rc = Params::Get::get_params('value', \@_);

        return bless $rc, $class;
    }

## The `$default` Parameter

The first argument is the `$default` parameter controls how single-argument calls are interpreted and provides
a default key name for parameter extraction in those cases.

When no arguments are provided with a defined `$default`:

    get_params('required'); # Throws usage error

The function requires either arguments or an undefined `$default`.

### Usage Examples

- Simple scalar parameter:

        sub set_country {
            my $params = get_params('country', @_);
            # Accepts: set_country('US')
            # Returns: { country => 'US' }
        }

- Object constructor with options:

        sub new {
            my $class = shift;
            my $params = get_params('value', @_);
            # Accepts: MyClass->new($object)
            # Accepts: MyClass->new($object, { option => 'value' })
            # Returns: { value => $object } or { value => $object, option => 'value' }
        }

- Hash parameter:

        sub configure {
            my $params = get_params('config', @_);
            # Accepts: configure({ db => 'mysql', host => 'localhost' })
            # Returns: { config => { db => 'mysql', host => 'localhost' } }
        }

- Without default (named parameters only):

        sub process {
            my $params = get_params(undef, @_);
            # Accepts: process(name => 'John', age => 30)
            # Returns: { name => 'John', age => 30 }
        }

### Caveats

- When `$default` is defined and no arguments are provided, an error is thrown
- There's no way to specify that a default parameter is optional
- Single hash references always bypass the default parameter naming

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Sometimes giving an array ref rather than array fails.

# SEE ALSO

- [Params::Smart](https://metacpan.org/pod/Params%3A%3ASmart)
- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
- [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)
- [Test Dashboard](https://nigelhorne.github.io/Params-Get/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-params-get at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Get](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Get).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Params::Get

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Params-Get](https://metacpan.org/dist/Params-Get)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Get](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Get)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Params-Get](http://matrix.cpantesters.org/?dist=Params-Get)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Params::Get](http://deps.cpantesters.org/?module=Params::Get)

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
