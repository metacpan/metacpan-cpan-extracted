package Mojolicious::Plugin::FormChecker;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '1.001003'; # VERSION

sub register {
    my ($self, $app) = @_;

    $app->helper(
        form_checker => sub {
            $self->_perform_checks( @_ );
        },
    );

    $app->helper(
        form_checker_error => sub {
            shift->stash('form_checker_error') // [];
        },
    );

    $app->helper(
        form_checker_error_wrapped => sub {
            shift->stash('form_checker_error_wrapped');
        },
    );

    $app->helper(
        form_checker_ok => sub {
            shift->stash('form_checker_ok');
        },
    );
}

sub _perform_checks {
    my ( $self, $c, %conf ) = @_;

    %conf = (
        all_errors  => 1, # TODO: get rid of this and always do all_errors
        error_class => 'alert alert-extra-danger',
        %conf,
    );

    $self->_conf( \%conf );
    $self->_check_ok(0);
    $self->{FAIL} = []; # TODO: refactor all of the $self->{CAPS} stuff

    keys %{ $conf{rules} };
    while ( my ( $param, $rule ) = each %{ $conf{rules} } ) {
        if ( not ref $rule ) {
            $rule = { $rule => 1 };
        }
        elsif ( ref $rule eq 'CODE' ) {
            $rule = { code => $rule };
        }
        elsif ( ref $rule eq 'Regexp' ) {
            $rule = { must_match => $rule };
        }
        elsif ( ref $rule eq 'ARRAY' ) {
            $rule = { map +( $_ => 1 ), @$rule };
        }
        elsif ( ref $rule eq 'SCALAR' ) {
            $rule = { param => $$rule };
        }

        $self->_rule_ok( $param, $rule, $c->param( $param ), $c );
    }

    $self->_check_ok(1)
        unless ( ref $self->_error and @{ $self->_error } )
            or ( ! ref $self->_error );

    $c->stash(
        form_checker_ok => $self->_check_ok,
        form_checker_error => $self->_error,
        form_checker_error_wrapped =>
            join "\n", map qq{<p class="} . $conf{error_class}
                . q{"><i class="glyphicon glyphicon-warning-sign"></i> }
                . qq{$_</p>}, @{ $self->_error || [] },
    );
}

sub _rule_ok {
    my ( $self, $param, $rule, $value, $c ) = @_;

    my $name = defined $rule->{name} ? $rule->{name} : ucfirst $param;

    unless ( defined $value and length $value ) {
        if ( $rule->{optional} ) {
            if ( $rule->{either_or} ) {
                my $which = ref $rule->{either_or}
                          ? $rule->{either_or}
                          : [ $rule->{either_or} ];

                for ( @$which, $param ) {
                    if ( length $c->param($_) ) {
                        return 1;
                    }
                }

                return $self->_fail( $name, 'either_or_error', $rule );
            }
            return 1;
        }
        else {
            return $self->_fail( $name, 'mandatory_error', $rule );
        }
    }

    if ( $rule->{num} ) {
        return $self->_fail( $name, 'num_error', $rule )
            if $value =~ /\D/;
    }

    return $self->_fail( $name, 'min_error', $rule )
        if defined $rule->{min}
            and length($value) < $rule->{min};

    return $self->_fail( $name, 'max_error', $rule )
        if defined $rule->{max}
            and length($value) > $rule->{max};

    if ( $rule->{must_match} ) {
        return $self->_fail( $name, 'must_match_error', $rule )
            if $value !~ /$rule->{must_match}/;
    }

    if ( $rule->{must_not_match} ) {
        return $self->_fail( $name, 'must_not_match_error', $rule )
            if $value =~ /$rule->{must_not_match}/;
    }

    if ( $rule->{code} ) {
        return $self->_fail( $name, 'code_error', $rule )
            unless $rule->{code}->( $value, $param, $c );
    }

    if ( my @values = @{ $rule->{valid_values} || [] } ) {
        my %valid;
        @valid{ @values} = (1) x @values;

        return $self->_fail( $name, 'valid_values_error', $rule )
            unless exists $valid{$value};
    }

    if ( $rule->{param} ) {
        my $param_match = $c->param( $rule->{param} );
        defined $param_match
            or $param_match = '';

        return $self->_fail( $name, 'param_error', $rule )
            unless $value eq $param_match;
    }

    return 1;
}

sub _fail {
    my ( $self, $name, $err_name, $rule ) = @_;

    push @{ $self->{FAIL} }, $self->_make_error( $name, $err_name, $rule );
    return;
}

sub _make_error {
    my ( $self, $name, $err_name, $rule ) = @_;

    return $rule->{ $err_name }
        if exists $rule->{ $err_name };

    my %errors = (
        mandatory_error
            => "You must specify parameter $name",
        num_error
            => "Parameter $name must contain digits only",
        min_error
            => "Parameter $name must be at least "
                . ($rule->{min} // '') . ' characters long',
        max_error
            => "Parameter $name cannot be longer "
                . 'than ' . ($rule->{max} // '') . ' characters',
        code_error
            => "Parameter $name contains incorrect data",
        must_match_error
            => "Parameter $name contains incorrect data",
        must_not_match_error
            => "Parameter $name contains incorrect data",
        param_error
            => "Parameter $name does not match parameter "
                . ( $rule->{param} // ''),
        either_or_error
            => "Parameter $name must contain data if "
                . "other parameters are not set",
        valid_values_error
            => "Parameter $name must be " . do {
            my $last = pop @{ $rule->{valid_values} || [''] };
            join(', ', @{ $rule->{valid_values} || [] } ) . " or $last"
        },
    );

    return $errors{ $err_name };
}

sub _error {
    my $self = shift;

    return
        unless defined $self->{FAIL};

    if ( $self->_conf->{all_errors} ) {
        my %errors = map +( $_ => 1 ), @{ $self->{FAIL} || [] };
        return [ sort keys %errors ];
    }
    else {
        return shift @{ $self->{FAIL} || [] };
    }
}

sub _conf {
    my $self = shift;

    if ( @_ ) { $self->{CONF} = shift; }

    return $self->{CONF};
}

sub _check_ok {
    my $self = shift;

    if ( @_ ) { $self->{CHECK_OK} = shift; }

    return $self->{CHECK_OK};
}


'
"Can I tell you a TCP Joke?"
"Yes, Please tell me a TCP Joke."
"Ok, I will tell you a TCP Joke."

"Can I tell you a UDP joke?"
"Can I tell you a UDP joke?"
"Can I tell you a UDP joke?"
';

__END__

=encoding utf8

=for stopwords scalarref RULESETS rulesets subref ruleset

=head1 NAME

Mojolicious::Plugin::FormChecker - Mojolicious plugin for validating query parameters

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<Mojolicious::Plugin::FormChecker> is a L<Mojolicious> plugin for
validating query parameters input.

=head1 METHODS

L<Mojolicious::Plugin::FormChecker> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 HELPERS

=head2 C<form_checker>

    $c->form_checker(
        error_class => 'alert alert-extra-danger',
        rules => {
            name => { max => 2, },
            email => { max => 200, },
        },
    );

The C<form_checker> helper is used to initiate validation.
It takes a list of key/value pairs, which are:

=head3 C<error_class>

    error_class => 'custom_error_class',

Used only by the C<form_checker_error_wrapped> helper and specifies
which class name to use for C<< <p> >> elements that wrap errors.

=head3 C<rules>

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
The C<rules> key takes a hashref as a value.

The keys of C<rules> hashref are the names
of the query parameters that you wish to check.
The values of those keys are the
"rulesets" (see below). The values can be either a string,
regex (C<qr//>), arrayref, subref, scalarref or a hashref;
If the value is NOT a hashref it will be changed into hashref
as follows (the actual meaning of resulting hashrefs is described below):

=head4 a string

    param => 'num',
    # same as
    param => { num => 1 },

=head4 a regex

    param => qr/foo/,
    # same as
    param => { must_match => qr/foo/ },

=head4 an arrayref

    param => [ qw/optional num/ ],
    # same as
    param => {
        optional => 1,
        num      => 1,
    },

=head4 a subref

    param => sub { time() % 2 },
    # same as
    param => { code => sub { time() % 2 } },

=head4 a scalarref

    param => \'param2',
    # same as
    param => { param => 'param2' },

=head3 C<rules> RULESETS

The rulesets (values of C<rules> hashref) have keys that
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

=head4 C<name>

    name => 'Decent name',

This is not actually a rule but the text to use for the name of the parameter in error
messages. If not specified the
actual parameter name - on which C<ucfirst()> will be run -
will be used.

=head4 C<num>

    num => 1,

When set to a true value the query parameter's value must contain digits only.

=head4 C<optional>

    optional => 1,

When set to a true value indicates that the parameter is optional. Note that you can specify
other rules along with this one, e.g.:

    optional => 1,
    num      => 1,

Means, query parameter is optional, B<but if it is given> it must contain only digits.

=head4 C<either_or>

    optional    => 1, # must use this
    either_or   => 'foo',

    optional    => 1, # must use this
    either_or   => [ qw/foo bar baz/ ],

The C<optional>. B<must be set to a true value> in order
for C<either_or> rule to work.
The rule takes either a string or an arrayref as a value.
Specifying a string as a value is
the same as specifying a hashref with just that string in it. Each string in an arrayref
represents the name of a query parameter. In order for the rule
to succeed B<either> one
of the parameters must be set. It's a bit messy, but you must use the C<optional> rule
as well as list the C<either_or> rule for every parameter that is tested for "either or" rule.

=head4 C<must_match>

    must_match => qr/foo/,

Takes a regex (C<qr//>) as a value. The query parameter's value must match this regex.

=head4 C<must_not_match>

    must_not_match => qr/bar/,

Takes a regex (C<qr//>) as a value. The query parameter's value must B<NOT> match this regex.

=head4 C<max>

    max => 20,

Takes a positive integer as a value. Query parameter's value must not exceed C<max>
characters in length.

=head4 C<min>

    min => 3,

Takes a positive integer as a value. Query parameter's value must be at least C<min>
characters in length.

=head4 C<valid_values>

    valid_values => [ qw/foo bar baz/ ],

Takes an arrayref as a value. Query parameter's value must be one of the items in the arrayref.

=head4 C<code>

    code => sub {
        my ( $value, $param_name, $c ) = @_;
        ...
    },

Takes a subref as a value. The C<@_> will
contain the following (in that order): - the value of the parameter that is being tested,
the name of the parameter, your Mojolicious controller object.
If the sub returns a true value - the check will be
considered successful. If the
sub returns a false value, then test fails and form check
stops and errors out.

=head4 C<param>

    param => 'param2',

Takes a string as an argument; that string will be interpreted as a name of a query parameter.
Values of the parameter that is currently being inspected and the one given as a value must
match in order for the rule to succeed. The example above indicates that query parameter
C<param> C<eq> query parameter C<param2>.

=head4 C<select>

    select => 1,

This one is not actually a "rule". This is a flag for C<{t}> "filling" that is
described in great detail (way) above under the description of C<no_fill> key.

=head3 CUSTOM ERROR MESSAGES IN RULESETS

All C<*_error> keys take strings as values; they can be used to set custom error
messages for each test in the ruleset. In the defaults listed below under each C<*_error>,
the C<$name> represents either the name of the parameter or the value of C<name> key that
you set in the ruleset.

=head4 C<num_error>

    num_error => 'Numbers only!',

This will be the error to be displayed if C<num> test fails.
B<Defaults to> C<Parameter $name must contain digits only>.

=head4 C<mandatory_error>

    mandatory_error => 'Must gimme!',

This is the error when C<optional> is set to a false value, which is the default, and
user did not specify the query parameter. I.e., "error to display for missing mandatory
parameters". B<Defaults to:> C<You must specify parameter $name>

=head4 C<must_match_error>

    must_match_error => 'Must match me!',

This is the error for C<must_match> rule. B<Defaults to:>
C<Parameter $name contains incorrect data>

=head4 C<must_not_match_error>

    must_not_match_error => 'Cannot has me!',

This is the error for C<must_not_match> rule. B<Defaults to:>
C<Parameter $name contains incorrect data>

=head4 C<max_error>

    max_error => 'Too long!',

This is the error for C<max> rule. B<Defaults to:>
C<Parameter $name cannot be longer than $max characters> where C<$max> is the C<max> rule's
value.

=head4 C<min_error>

    min_error => 'Too short :(',

This is the error for C<min> rule. B<Defaults to:>
C<Parameter $name must be at least $min characters long>

=head4 C<code_error>

    code_error => 'No likey 0_o',

This is the error for C<code> rule. B<Defaults to:>
C<Parameter $name contains incorrect data>

=head4 C<either_or_error>

    either_or_error => "You must specify either Foo or Bar",

This is the error for C<either_or> rule.
B<Defaults to:> C<Parameter $name must contain data if other parameters are not set>

=head4 C<valid_values_error>

    valid_values_error => 'Pick the correct one!!!',

This is the error for C<valid_values> rule. B<Defaults to:>
C<Parameter $name must be $list_of_values> where C<$list_of_values> is the list of the
values you specified in the arrayref given to C<valid_values> rule joined by commas and
the last element joined by word "or".

=head4 C<param_error>

    param_error => "Two passwords do not match",

This is the error for C<param> rule. You pretty much always would want to set a custom
error message here as it B<defaults to:> C<< Parameter $name does not match parameter
$rule->{param} >> where C<< $rule->{param} >> is the value you set to C<param> rule.

=head2 C<form_checker_ok>

    % if ( form_checker_ok() ) {
        <p class="message success">Check was alright!</p>
    % }

Will return a true value if the form check was successful

=head2 C<form_checker_error>

    % for my $error ( @{ form_checker_error() } ) {
        <p><%= $error %></p>
    % }

If check fails, returns an arrayref of error messages (that are strings)

=head2 C<form_checker_error_wrapped>

    <%== form_checker_error_wrapped %>

If check fails, returns a string containing all errors, where
each error is wrapped into a C<< <p class="error"> ... </p> >>. The
classname can be changed via C<error_class>
argument to C<form_checker>

=head1 SEE ALSO

L<Mojolicious::Plugin::FormValidator>,
L<Mojolicious::Plugin::FormValidatorLazy>

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 EXAMPLES

The C<examples/> directory of this distribution contains an example
of a L<Mojolicious::Lite> application utilizing this plugin.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Mojolicious-Plugin-FormChecker>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Mojolicious-Plugin-FormChecker/issues>

If you can't access GitHub, you can email your request
to C<bug-mojolicious-plugin-formchecker at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet C<zoffix at cpan.org>, (L<http://zoffix.com/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut