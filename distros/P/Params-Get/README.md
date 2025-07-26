# NAME

Params::Get - Get the parameters to a subroutine in any way you want

# VERSION

Version 0.10

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
                    min => -180,
                    max => 180
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

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Sometimes giving an array ref rather than array fails.

# SEE ALSO

- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)

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

# LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

This program is released under the following licence: GPL2
