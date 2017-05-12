# NAME

Mojolicious::Plugin::FormChecker - Mojolicious plugin for validating query parameters

# SYNOPSIS

    #!/usr/bin/env perl

    use Mojolicious::Lite;

    plugin 'FormChecker';

    get '/' => 'index';
    post '/' => sub {
        my $c = shift;

        $c->form_checker(
            rules => {
                name  => { max => 200 },
                email => {
                    must_match => qr/\@/,
                    must_match_error
                        => 'Email field does not contain a valid email address',
                },
                message => {},
            },
        );
    } => 'index';

    app->start;

    __DATA__

    @@ index.html.ep

    % if ( form_checker_ok() ) {

        <p class="message success">Check was alright!
            <a href="/">Do it again!</a></p>

    % } else {
        %= form_for index => (method => 'POST') => begin
            %= csrf_field
            <%== form_checker_error_wrapped %>

            <ul>
                <li><label for="name">*Name:</label><%= text_field 'name' %></li>
                <li><label for="email">*Email:</label><%= text_field 'email'%></li>
                <li><label for="Message" class="textarea_label">*Message:</label
                    ><%= text_area 'message', cols => 40, rows => 5 %>
                </li>
            </ul>
            %= submit_button 'Send'
        % end
    % }

# DESCRIPTION

[Mojolicious::Plugin::FormChecker](https://metacpan.org/pod/Mojolicious::Plugin::FormChecker) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin for
validating query parameters input.

# METHODS

[Mojolicious::Plugin::FormChecker](https://metacpan.org/pod/Mojolicious::Plugin::FormChecker) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# HELPERS

## `form_checker`

    $c->form_checker(
        error_class => 'alert alert-extra-danger',
        rules => {
            name => { max => 2, },
            email => { max => 200, },
        },
    );

The `form_checker` helper is used to initiate validation.
It takes a list of key/value pairs, which are:

### `error_class`

    error_class => 'custom_error_class',

Used only by the `form_checker_error_wrapped` helper and specifies
which class name to use for `<p>` elements that wrap errors.

### `rules`

        rules       => {
            param1 => 'num',
            param2 => qr/foo|bar/,
            param3 => [ qw/optional num/ ],
            param4 => {
                optional        => 1,
                select          => 1,
                must_match      => qr/foo|bar/,
                must_not_match  => qr/foos/,
                must_match_error => 'Param4 must contain either foo or bar but not foos',
            },
            param5 => {
                valid_values        => [ qw/foo bar baz/ ],
                valid_values_error  => 'Param5 must be foo, bar or baz',
            },
            param6 => sub { time() % 2 }, # return true or false values
        },

This is where you specify what and how needs to be checked.
The `rules` key takes a hashref as a value.

The keys of `rules` hashref are the names
of the query parameters that you wish to check.
The values of those keys are the
"rulesets" (see below). The values can be either a string,
regex (`qr//`), arrayref, subref, scalarref or a hashref;
If the value is NOT a hashref it will be changed into hashref
as follows (the actual meaning of resulting hashrefs is described below):

#### a string

    param => 'num',
    # same as
    param => { num => 1 },

#### a regex

    param => qr/foo/,
    # same as
    param => { must_match => qr/foo/ },

#### an arrayref

    param => [ qw/optional num/ ],
    # same as
    param => {
        optional => 1,
        num      => 1,
    },

#### a subref

    param => sub { time() % 2 },
    # same as
    param => { code => sub { time() % 2 } },

#### a scalarref

    param => \'param2',
    # same as
    param => { param => 'param2' },

### `rules` RULESETS

The rulesets (values of `rules` hashref) have keys that
define the type of the rule and
value defines different things or
just indicates that the rule should be considered.
Here is the list of all valid ruleset keys:

    rules => {
        param => {
            name            => 'Parameter', # the name of this param to use in error messages
            num             => 1, # value must be numbers-only
            optional        => 1, # parameter is optional
            either_or       => [ qw/foo bar baz/ ], # param or foo or bar or baz must be set
            must_match      => qr/foo/, # value must match given regex
            must_not_match  => qr/bar/, # value must NOT match the given regex
            max             => 20, # value must not exceed 20 characters in length
            min             => 3,  # value must be more than 3 characters in length
            valid_values    => [ qw/foo bar baz/ ], # value must be one from the given list
            code            => sub { time() %2 }, # return from the sub determines pass/fail
            select          => 1, # flag for "filling", see no_fill key above
            param           => 'param1',
            num_error       => 'Numbers only!', # custom error if num rule failed
            mandatory_error => '', # same for if parameter is missing and not optional.
            must_match_error => '', # same for must_match rule
            must_not_match_error => '', # same for must_not_match_rule
            max_error            => '', # same for max rule
            min_error            => '', # same for min rule
            code_error           => '', # same for code rule
            either_or_error      => '', # same for either_or rule
            valid_values_error   => '', # same for valid_values rule
            param_error          => '', # same fore param rule
        },
    }

You can mix and match the rules for perfect tuning.

#### `name`

    name => 'Decent name',

This is not actually a rule but the text to use for the name of the parameter in error
messages. If not specified the
actual parameter name - on which `ucfirst()` will be run -
will be used.

#### `num`

    num => 1,

When set to a true value the query parameter's value must contain digits only.

#### `optional`

    optional => 1,

When set to a true value indicates that the parameter is optional. Note that you can specify
other rules along with this one, e.g.:

    optional => 1,
    num      => 1,

Means, query parameter is optional, **but if it is given** it must contain only digits.

#### `either_or`

    optional    => 1, # must use this
    either_or   => 'foo',

    optional    => 1, # must use this
    either_or   => [ qw/foo bar baz/ ],

The `optional`. **must be set to a true value** in order
for `either_or` rule to work.
The rule takes either a string or an arrayref as a value.
Specifying a string as a value is
the same as specifying a hashref with just that string in it. Each string in an arrayref
represents the name of a query parameter. In order for the rule
to succeed **either** one
of the parameters must be set. It's a bit messy, but you must use the `optional` rule
as well as list the `either_or` rule for every parameter that is tested for "either or" rule.

#### `must_match`

    must_match => qr/foo/,

Takes a regex (`qr//`) as a value. The query parameter's value must match this regex.

#### `must_not_match`

    must_not_match => qr/bar/,

Takes a regex (`qr//`) as a value. The query parameter's value must **NOT** match this regex.

#### `max`

    max => 20,

Takes a positive integer as a value. Query parameter's value must not exceed `max`
characters in length.

#### `min`

    min => 3,

Takes a positive integer as a value. Query parameter's value must be at least `min`
characters in length.

#### `valid_values`

    valid_values => [ qw/foo bar baz/ ],

Takes an arrayref as a value. Query parameter's value must be one of the items in the arrayref.

#### `code`

    code => sub {
        my ( $value, $param_name, $c ) = @_;
        ...
    },

Takes a subref as a value. The `@_` will
contain the following (in that order): - the value of the parameter that is being tested,
the name of the parameter, your Mojolicious controller object.
If the sub returns a true value - the check will be
considered successful. If the
sub returns a false value, then test fails and form check
stops and errors out.

#### `param`

    param => 'param2',

Takes a string as an argument; that string will be interpreted as a name of a query parameter.
Values of the parameter that is currently being inspected and the one given as a value must
match in order for the rule to succeed. The example above indicates that query parameter
`param` `eq` query parameter `param2`.

#### `select`

    select => 1,

This one is not actually a "rule". This is a flag for `{t}` "filling" that is
described in great detail (way) above under the description of `no_fill` key.

### CUSTOM ERROR MESSAGES IN RULESETS

All `*_error` keys take strings as values; they can be used to set custom error
messages for each test in the ruleset. In the defaults listed below under each `*_error`,
the `$name` represents either the name of the parameter or the value of `name` key that
you set in the ruleset.

#### `num_error`

    num_error => 'Numbers only!',

This will be the error to be displayed if `num` test fails.
**Defaults to** `Parameter $name must contain digits only`.

#### `mandatory_error`

    mandatory_error => 'Must gimme!',

This is the error when `optional` is set to a false value, which is the default, and
user did not specify the query parameter. I.e., "error to display for missing mandatory
parameters". **Defaults to:** `You must specify parameter $name`

#### `must_match_error`

    must_match_error => 'Must match me!',

This is the error for `must_match` rule. **Defaults to:**
`Parameter $name contains incorrect data`

#### `must_not_match_error`

    must_not_match_error => 'Cannot has me!',

This is the error for `must_not_match` rule. **Defaults to:**
`Parameter $name contains incorrect data`

#### `max_error`

    max_error => 'Too long!',

This is the error for `max` rule. **Defaults to:**
`Parameter $name cannot be longer than $max characters` where `$max` is the `max` rule's
value.

#### `min_error`

    min_error => 'Too short :(',

This is the error for `min` rule. **Defaults to:**
`Parameter $name must be at least $min characters long`

#### `code_error`

    code_error => 'No likey 0_o',

This is the error for `code` rule. **Defaults to:**
`Parameter $name contains incorrect data`

#### `either_or_error`

    either_or_error => "You must specify either Foo or Bar",

This is the error for `either_or` rule.
**Defaults to:** `Parameter $name must contain data if other parameters are not set`

#### `valid_values_error`

    valid_values_error => 'Pick the correct one!!!',

This is the error for `valid_values` rule. **Defaults to:**
`Parameter $name must be $list_of_values` where `$list_of_values` is the list of the
values you specified in the arrayref given to `valid_values` rule joined by commas and
the last element joined by word "or".

#### `param_error`

    param_error => "Two passwords do not match",

This is the error for `param` rule. You pretty much always would want to set a custom
error message here as it **defaults to:** `Parameter $name does not match parameter
$rule->{param}` where `$rule->{param}` is the value you set to `param` rule.

## `form_checker_ok`

    % if ( form_checker_ok() ) {
        <p class="message success">Check was alright!</p>
    % }

Will return a true value if the form check was successful

## `form_checker_error`

    % for my $error ( @{ form_checker_error() } ) {
        <p><%= $error %></p>
    % }

If check fails, returns an arrayref of error messages (that are strings)

## `form_checker_error_wrapped`

    <%== form_checker_error_wrapped %>

If check fails, returns a string containing all errors, where
each error is wrapped into a `<p class="error"> ... </p>`. The
classname can be changed via `error_class`
argument to `form_checker`

# SEE ALSO

[Mojolicious::Plugin::FormValidator](https://metacpan.org/pod/Mojolicious::Plugin::FormValidator),
[Mojolicious::Plugin::FormValidatorLazy](https://metacpan.org/pod/Mojolicious::Plugin::FormValidatorLazy)

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicio.us](http://mojolicio.us).

# EXAMPLES

The `examples/` directory of this distribution contains an example
of a [Mojolicious::Lite](https://metacpan.org/pod/Mojolicious::Lite) application utilizing this plugin.

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/Mojolicious-Plugin-FormChecker](https://github.com/zoffixznet/Mojolicious-Plugin-FormChecker)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/Mojolicious-Plugin-FormChecker/issues](https://github.com/zoffixznet/Mojolicious-Plugin-FormChecker/issues)

If you can't access GitHub, you can email your request
to `bug-mojolicious-plugin-formchecker at rt.cpan.org`

# AUTHOR

Zoffix Znet `zoffix at cpan.org`, ([http://zoffix.com/](http://zoffix.com/))

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
