package Params::Check::Faster;

use 5.006; #warnings.pm 
use strict;

use Carp                        qw[carp croak];
use Locale::Maketext::Simple    Style => 'gettext';

BEGIN {
    use Exporter    ();
    use vars        qw[ @ISA $VERSION @EXPORT_OK $VERBOSE $ALLOW_UNKNOWN
                        $STRICT_TYPE $STRIP_LEADING_DASHES $NO_DUPLICATES
                        $PRESERVE_CASE $ONLY_ALLOW_DEFINED $WARNINGS_FATAL
                        $SANITY_CHECK_TEMPLATE $CALLER_DEPTH $_ERROR_STRING
                    ];

    @ISA        =   qw[ Exporter ];
    @EXPORT_OK  =   qw[check allow last_error];

    $VERSION                = '0.04';
    $VERBOSE                = $^W ? 1 : 0;
    $NO_DUPLICATES          = 0;
    $STRIP_LEADING_DASHES   = 0;
    $STRICT_TYPE            = 0;
    $ALLOW_UNKNOWN          = 0;
    $PRESERVE_CASE          = 0;
    $ONLY_ALLOW_DEFINED     = 0;
    $SANITY_CHECK_TEMPLATE  = 1;
    $WARNINGS_FATAL         = 0;
    $CALLER_DEPTH           = 0;
}

my %known_keys = map { $_ => 1 }
                    qw| required allow default strict_type no_override
                        store defined |;

=pod

=head1 NAME

Params::Check::Faster - A generic input parsing/checking mechanism. Reimplementation of Params::Check.

=head1 SYNOPSIS

    use Params::Check::Faster qw[check allow last_error];

    sub fill_personal_info {
        my %hash = @_;
        my $x;

        my $tmpl = {
            firstname   => { required   => 1, defined => 1 },
            lastname    => { required   => 1, store => \$x },
            gender      => { required   => 1,
                             allow      => [qr/M/i, qr/F/i],
                           },
            married     => { allow      => [0,1] },
            age         => { default    => 21,
                             allow      => qr/^\d+$/,
                           },

            phone       => { allow => [ sub { return 1 if /$valid_re/ },
                                        '1-800-PERL' ]
                           },
            id_list     => { default        => [],
                             strict_type    => 1
                           },
            employer    => { default => 'NSA', no_override => 1 },
        };

        ### check() returns a hashref of parsed args on success ###
        my $parsed_args = check( $tmpl, \%hash, $VERBOSE )
                            or die qw[Could not parse arguments!];

        ... other code here ...
    }

    my $ok = allow( $colour, [qw|blue green yellow|] );

    my $error = Params::Check::Faster::last_error();


=head1 DESCRIPTION

Params::Check::Faster is a generic input parsing/checking mechanism.

This module is a faster reimplementation of Params::Check. It should be 100%
compatible. It might be merged with Params::Check at some point, after its author (kane) has reviewed it and is happy with merging it.

It allows you to validate input via a template. The only requirement
is that the arguments must be named.

Params::Check::Faster can do the following things for you:

=over 4

=item *

Convert all keys to lowercase

=item *

Check if all required arguments have been provided

=item *

Set arguments that have not been provided to the default

=item *

Weed out arguments that are not supported and warn about them to the
user

=item *

Validate the arguments given by the user based on strings, regexes,
lists or even subroutines

=item *

Enforce type integrity if required

=back

Most of Params::Check::Faster's power comes from its template, which we'll
discuss below:

=head1 Template

As you can see in the synopsis, based on your template, the arguments
provided will be validated.

The template can take a different set of rules per key that is used.

The following rules are available:

=over 4

=item default

This is the default value if none was provided by the user.
This is also the type C<strict_type> will look at when checking type
integrity (see below).

=item required

A boolean flag that indicates if this argument was a required
argument. If marked as required and not provided, check() will fail.

=item strict_type

This does a C<ref()> check on the argument provided. The C<ref> of the
argument must be the same as the C<ref> of the default value for this
check to pass.

This is very useful if you insist on taking an array reference as
argument for example.

=item defined

If this template key is true, enforces that if this key is provided by
user input, its value is C<defined>. This just means that the user is
not allowed to pass C<undef> as a value for this key and is equivalent
to:
    allow => sub { defined $_[0] && OTHER TESTS }

=item no_override

This allows you to specify C<constants> in your template. ie, they
keys that are not allowed to be altered by the user. It pretty much
allows you to keep all your C<configurable> data in one place; the
C<Params::Check::Faster> template.

=item store

This allows you to pass a reference to a scalar, in which the data
will be stored:

    my $x;
    my $args = check(foo => { default => 1, store => \$x }, $input);

This is basically shorthand for saying:

    my $args = check( { foo => { default => 1 } }, $input );
    my $x    = $args->{foo};

It works for arrays or hash reference too. You can write :

    my @array;
    my %hash;
    my $args = check(foo => { default => [ 1 ], store => \@array },
                     bar => { default => { answer => 42 }, store => \%hash },
                     $input);

And @array and %hash contains directly the corresponding array or hash dereferenced.


You can alter the global variable $Params::Check::Faster::NO_DUPLICATES to
control whether the C<store>'d key will still be present in your
result set. See the L<Global Variables> section below.

=item allow

A set of criteria used to validate a particular piece of data if it
has to adhere to particular rules.

See the C<allow()> function for details.

=back

=head1 Functions

=head2 check( \%tmpl, \%args, [$verbose] );

This function is not exported by default, so you'll have to ask for it
via:

    use Params::Check::Faster qw[check];

or use its fully qualified name instead.

C<check> takes a list of arguments, as follows:

=over 4

=item Template

This is a hashreference which contains a template as explained in the
C<SYNOPSIS> and C<Template> section.

=item Arguments

This is a reference to a hash of named arguments which need checking.

=item Verbose

A boolean to indicate whether C<check> should be verbose and warn
about what went wrong in a check or not.

You can enable this program wide by setting the package variable
C<$Params::Check::Faster::VERBOSE> to a true value. For details, see the
section on C<Global Variables> below.

=back

C<check> will return when it fails, or a hashref with lowercase
keys of parsed arguments when it succeeds.

So a typical call to check would look like this:

    my $parsed = check( \%template, \%arguments, $VERBOSE )
                    or warn q[Arguments could not be parsed!];

A lot of the behaviour of C<check()> can be altered by setting
package variables. See the section on C<Global Variables> for details
on this.

=cut


sub check {
    # for speed purpose we don't copy @_; check if we have anything to work on
    if (!$_[0] || !$_[1]) {
        return;
    }

    my %template = %{$_[0]};
    my %args = %{$_[1]};
    my $verbose = $_[2] || $VERBOSE || 0;

    # clear current error
    _clear_error();

    # flag to see if we warned for anything, needed for warnings_fatal
    my $warned;

    # flag to see if anything went wrong
    my $wrong; 

    # key to remove from the args, if unauthorised
    my @keys_to_remove = ();

    # keys to rename : [ old_key_name, new_key_name]
    my @keys_to_rename = ();

    # list of values to store into ref : [ $type, $ref, $value ]
    my @to_store = ();

    # list of keys to delete from args
    my @to_delete = ();

#  ARG_LOOP:
    # loop on the arguments
    while (my ($arg_key, $arg_value) = each %args) {

        # handle key name
        if (!$PRESERVE_CASE || $STRIP_LEADING_DASHES) {
            my $orig_arg_key = $arg_key;
            $arg_key = lc($arg_key) unless $PRESERVE_CASE;
            $arg_key =~ s/^-// if $STRIP_LEADING_DASHES;
            if ($arg_key ne $orig_arg_key) {
                push @keys_to_rename, [ $arg_key, $orig_arg_key ];
            }
        }

        # the argument doesn't exist in the template
        if ( !exists $template{$arg_key} ) {
            if (!$ALLOW_UNKNOWN) {
                _store_error(
                             loc(q(Key '%1' is not a valid key for %2 provided by %3),
                                 $arg_key, _who_was_it(), _who_was_it(1)), $verbose);
                $warned = 1;
                push @keys_to_remove, $arg_key;
            }
            next;
        };

        # copy of this keys template instructions, to save derefs
        my %arg_template = %{delete $template{$arg_key} };

        if ($SANITY_CHECK_TEMPLATE) {
            foreach(grep { ! $known_keys{$_} } keys %arg_template) {
                _store_error(loc(q(Template type '%1' not supported [at key '%2']),
                                 $_, $arg_key), $verbose)
            }
        }

        # the argument cannot be overridden
        if ($arg_template{no_override}) {
            _store_error(
                loc(q(You are not allowed to override key '%1' for %2 from %3),
                    $arg_key, _who_was_it(), _who_was_it(1)),
                $verbose
            );
            $warned = 1;
            push @keys_to_remove, $arg_key;
            $template{$arg_key} = \%arg_template;
            next;
        }

        # check if you were supposed to provide defined() values
        if ( ($arg_template{defined} || $ONLY_ALLOW_DEFINED) && !defined $arg_value ) {
            _store_error(loc(q(Key '%1' must be defined when passed), $arg_key),
                         $verbose );
            $wrong = 1;
            push @keys_to_remove, $arg_key;
            $template{$arg_key} = \%arg_template;
            next;
        }

        # check if they should be of a strict type, and if it is
        if ( ($arg_template{strict_type} || $STRICT_TYPE) && ref $arg_value ne ref $arg_template{default}) {
            _store_error(loc(q(Key '%1' needs to be of type '%2'),
                             $arg_key, ref($arg_template{default}) || 'SCALAR'),
                         $verbose );
            $wrong = 1;
            push @keys_to_remove, $arg_key;
            $template{$arg_key} = \%arg_template;
            next;
        }

        # check if we have an allow handler, to validate against
        # allow() will report its own errors
        if (exists $arg_template{allow} && !do {
            local $_ERROR_STRING;
            allow($arg_value, $arg_template{allow})
        }) {
            # stringify the value in the error report -- we don't want dumps
            # of objects, but we do want to see *roughly* what we passed
            _store_error(loc(q(Key '%1' (%2) is of invalid type for '%3' provided by %4),
                        $arg_key, $arg_value, _who_was_it(),
                        _who_was_it(1)), $verbose);
            $wrong = 1;
            push @keys_to_remove, $arg_key;
            $template{$arg_key} = \%arg_template;
            next;
        }

        # check if we need to store the argument value to a provided ref
        if (my $ref = $arg_template{store}) {
            if ( !_store_var($arg_key, $ref, $arg_value, $verbose, \@to_store, \@to_delete)) {
                $wrong = 1;
                next;
            }
        }
    }


    # if we needed to rename keys
    foreach (@keys_to_rename) {
        $args{$_->[0]} = delete $args{$_->[1]};
    }

    # if we needed to remove unknown keys, so that default applies
    if (@keys_to_remove) {
        delete @args{@keys_to_remove};
    }

    # now check if there is any key left in the template
    while (my ($t_key, $t_value) = each %template) {

        # check if required key is missing
        if ($t_value->{required}) {
            _store_error(
                loc(q(Required option '%1' is not provided for %2 by %3),
                    $t_key, _who_was_it(), _who_was_it(1)), $verbose );
            $wrong = 1;
            next;
        }

        # set default argument omitted
        if (exists $t_value->{default}) {
            $args{$t_key} = $t_value->{default};
            # check if we need to store the default value to a provided ref
            if (my $ref = $t_value->{store}) {
                if (!_store_var($t_key, $ref, $t_value->{default}, $verbose, \@to_store, \@to_delete)) {
                    $wrong = 1;
                    next;
                }
            }
        }
        # special case to be backward compatible
        if ($SANITY_CHECK_TEMPLATE && exists $t_value->{store} && !ref $t_value->{store} ) {
            _store_error( loc(
                              q(Store variable for '%1' is not a reference!), $t_key
                             ), $verbose);
        }

    }

    # croak with the collected errors if there were errors and we have the
    # fatal flag toggled.
    if ( ($wrong || $warned) && $WARNINGS_FATAL) {
        croak(__PACKAGE__->last_error());
    }

    # if $wrong is set, somethign went wrong and the user is already informed,
    # just return...
    return if $wrong;

    # check if we need to store any of the keys. can't do it before, because
    # something may go wrong later, leaving the user with a few set variables

    foreach(@to_store) {
        my ($type, $ref, $value) = @$_;
        if ($type == 0) {
            $$ref = $value;
        }
        elsif ($type == 1) {
            @{$ref} = @{$value};
        }
        elsif ($type == 2) {
            %{$ref} = %{$value};
        }
    }
    $NO_DUPLICATES and delete @args{@to_delete};

    # now, everything is fine, we can return the arguments
    return(\%args);
}

sub _store_var {
    my ($key, $ref, $value, $verbose, $to_store, $to_delete) = @_;

    if ($SANITY_CHECK_TEMPLATE && !ref($ref)) {
        _store_error( loc(
                          q(Store variable for '%1' is not a reference!), $key
                         ), $verbose, 1 );
        return; #error
    }
    
    if (ref($ref) eq 'ARRAY') {
        if (ref($value) ne 'ARRAY') {
            _store_error(
                loc(q(Key '%1' (value %2) is not a ARRAYREF. For %3 by %4),
                    $key, $value, _who_was_it(1), _who_was_it(2)), $verbose, 1);
            return; # error
    }
        # push the refs/values to execute later
        push @$to_store, [ 1, $ref, $value]; # 1 = array
        $NO_DUPLICATES and push @$to_delete, $key;
    }
    elsif (ref($ref) eq 'HASH') {
    if (ref($value) ne 'HASH') {
            _store_error(
                loc(q(Key '%1' (value %2) is not a HASHREF. For %3 by %4),
                    $key, $value, _who_was_it(1), _who_was_it(2)), $verbose, 1);
            return; # error
    }
        # push the refs/values to execute later
        push @$to_store, [ 2, $ref, $value]; # 2 = hash
        $NO_DUPLICATES and push @$to_delete, $key;
    }
    else {
        # push the refs/values to execute later
        push @$to_store, [ 0, $ref, $value]; # 0 = scalar ref
        $NO_DUPLICATES and push(@$to_delete, $key);
    }

    return 1; # success
}

=head2 allow( $test_me, \@criteria );

The function that handles the C<allow> key in the template is also
available for independent use.

The function takes as first argument a key to test against, and
as second argument any form of criteria that are also allowed by
the C<allow> key in the template.

You can use the following types of values for allow:

=over 4

=item string

The provided argument MUST be equal to the string for the validation
to pass.

=item regexp

The provided argument MUST match the regular expression for the
validation to pass.

=item subroutine

The provided subroutine MUST return true in order for the validation
to pass and the argument accepted.

(This is particularly useful for more complicated data).

=item array ref

The provided argument MUST equal one of the elements of the array
ref for the validation to pass. An array ref can hold all the above
values.

=back

It returns true if the key matched the criteria, or false otherwise.

=cut

sub allow {

    # it's a regexp
    if (ref($_[1]) eq 'Regexp') {
        no warnings;
        return(scalar $_[0] =~ /$_[1]/); ## no critic (Regular expression)
    }

    # it's a sub
    if (ref($_[1]) eq 'CODE') {
        return $_[1]->($_[0]);
    }
    
    # it's an array
    if (ref($_[1])eq 'ARRAY') {

        # loop over the elements, see if one of them says the
        # value is OK
        # also, short-cicruit when possible
        foreach (@{$_[1]}) {
            if (allow($_[0], $_)) {
                return 1;
            }
        }
        return;
    }

    # fall back to a simple, but safe 'eq'
    return (defined $_[0] && defined $_[1]
            ? $_[0] eq $_[1]
            : defined $_[0] eq defined $_[1]
           );
}

# helper functions

sub _who_was_it {
    my $level = $_[0] || 0;

    return (caller(2 + $CALLER_DEPTH + $level))[3] || 'ANON'
}

=head2 last_error()

Returns a string containing all warnings and errors reported during
the last time C<check> was called.

This is useful if you want to report then some other way than
C<carp>'ing when the verbose flag is on.

It is exported upon request.

=cut

{   $_ERROR_STRING = '';

    sub _store_error {
        my($err, $verbose, $offset) = @_[0..2];
        $verbose ||= 0;
        $offset  ||= 0;
        my $level   = 1 + $offset;

        local $Carp::CarpLevel = $level;

        carp $err if $verbose;

        $_ERROR_STRING .= $err . "\n";
    }

    sub _clear_error {
        $_ERROR_STRING = '';
    }

    sub last_error { $_ERROR_STRING }
}

1;

=head1 Global Variables

The behaviour of Params::Check::Faster can be altered by changing the
following global variables:

=head2 $Params::Check::Faster::VERBOSE

This controls whether Params::Check::Faster will issue warnings and
explanations as to why certain things may have failed.
If you set it to 0, Params::Check::Faster will not output any warnings.

The default is 1 when L<warnings> are enabled, 0 otherwise;

=head2 $Params::Check::Faster::STRICT_TYPE

This works like the C<strict_type> option you can pass to C<check>,
which will turn on C<strict_type> globally for all calls to C<check>.

The default is 0;

=head2 $Params::Check::Faster::ALLOW_UNKNOWN

If you set this flag, unknown options will still be present in the
return value, rather than filtered out. This is useful if your
subroutine is only interested in a few arguments, and wants to pass
the rest on blindly to perhaps another subroutine.

The default is 0;

=head2 $Params::Check::Faster::STRIP_LEADING_DASHES

If you set this flag, all keys passed in the following manner:

    function( -key => 'val' );

will have their leading dashes stripped.

=head2 $Params::Check::Faster::NO_DUPLICATES

If set to true, all keys in the template that are marked as to be
stored in a scalar, will also be removed from the result set.

Default is false, meaning that when you use C<store> as a template
key, C<check> will put it both in the scalar you supplied, as well as
in the hashref it returns.

=head2 $Params::Check::Faster::PRESERVE_CASE

If set to true, L<Params::Check::Faster> will no longer convert all keys from
the user input to lowercase, but instead expect them to be in the
case the template provided. This is useful when you want to use
similar keys with different casing in your templates.

Understand that this removes the case-insensitivy feature of this
module.

Default is 0;

=head2 $Params::Check::Faster::ONLY_ALLOW_DEFINED

If set to true, L<Params::Check::Faster> will require all values passed to be
C<defined>. If you wish to enable this on a 'per key' basis, use the
template option C<defined> instead.

Default is 0;

=head2 $Params::Check::Faster::SANITY_CHECK_TEMPLATE

If set to true, L<Params::Check::Faster> will sanity check templates, validating
for errors and unknown keys. Although very useful for debugging, this
can be somewhat slow in hot-code and large loops.

To disable this check, set this variable to C<false>.

Default is 1;

=head2 $Params::Check::Faster::WARNINGS_FATAL

If set to true, L<Params::Check::Faster> will C<croak> when an error during 
template validation occurs, rather than return C<false>.

Default is 0;

=head2 $Params::Check::Faster::CALLER_DEPTH

This global modifies the argument given to C<caller()> by
C<Params::Check::Faster::check()> and is useful if you have a custom wrapper
function around C<Params::Check::Faster::check()>. The value must be an
integer, indicating the number of wrapper functions inserted between
the real function call and C<Params::Check::Faster::check()>.

Example wrapper function, using a custom stacktrace:

    sub check {
        my ($template, $args_in) = @_;

        local $Params::Check::Faster::WARNINGS_FATAL = 1;
        local $Params::Check::Faster::CALLER_DEPTH = $Params::Check::Faster::CALLER_DEPTH + 1;
        my $args_out = Params::Check::Faster::check($template, $args_in);

        my_stacktrace(Params::Check::Faster::last_error) unless $args_out;

        return $args_out;
    }

Default is 0;

=head1 AUTHOR

This module by
Damien "dams" Krotkine E<lt>dams@cpan.orgE<gt>.

=head1 COPYRIGHT

This module is
copyright (c) 2007 Damien "dams" Krotkine E<lt>dams@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
