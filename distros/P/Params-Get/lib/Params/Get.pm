package Params::Get;

# Normalises the many calling conventions Perl callers use when passing
# arguments -- positional scalar, named pairs, hashref, arrayref -- into a
# single hashref so the receiving sub need not care which style was used.

use strict;
use warnings;
use autodie qw(:all);

use parent 'Exporter';

use Carp ();
use Scalar::Util ();

use Readonly;

our @EXPORT_OK = qw(get_params);

=head1 NAME

Params::Get - Normalise subroutine arguments regardless of calling convention

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.15';

# Reference-type sentinels.  Collected here so a typo is a compile-time
# error via Readonly and grep/ack finds every usage in one search.
Readonly::Scalar my $T_HASH   => 'HASH';
Readonly::Scalar my $T_ARRAY  => 'ARRAY';
Readonly::Scalar my $T_SCALAR => 'SCALAR';
Readonly::Scalar my $T_CODE   => 'CODE';
Readonly::Scalar my $T_REF    => 'REF';

=head1 DESCRIPTION

C<Params::Get> exports a single function, C<get_params>, which accepts a
caller's argument list (or a reference to it) in any of the common Perl
calling conventions and returns a unified hash-ref.  Library authors can
write one normalisation call at the top of every public method rather than
hand-rolling the same conditional chains in each one.

When combined with L<Params::Validate::Strict> and L<Return::Set> you can
formally specify and enforce the input and output contracts of every method.

=head1 SYNOPSIS

    use Params::Get qw(get_params);
    use Params::Validate::Strict;

    sub where_am_i {
        my $params = Params::Validate::Strict::validate_strict({
            args   => get_params(undef, \@_),
            schema => {
                latitude  => { type => 'number', min => -90,  max =>  90 },
                longitude => { type => 'number', min => -180, max => 180 },
            },
        });
        printf "You are at %s, %s\n",
            $params->{latitude}, $params->{longitude};
    }

    where_am_i(latitude => 0.3, longitude => 124);
    where_am_i({ latitude => 3.14, longitude => -155 });

=head1 METHODS

=head2 get_params

Parse the argument list passed to a subroutine and return a unified hash-ref
regardless of the calling convention used.  Supported conventions:

=over 4

=item * Single hash-ref: C<foo({ a =E<gt> 1 })>

=item * Named key/value pairs: C<foo(a =E<gt> 1, b =E<gt> 2)>

=item * Single scalar with a default key: C<foo('US')> given C<get_params('country', @_)>

=item * Array-ref shorthand: C<foo(\@_)> inside the callee

=item * Mandatory positional argument plus an options hash-ref:
C<Obj-E<gt>new($val, { opt =E<gt> 1 })>

=item * Scalar-ref: C<foo(\'text')> -- dereferenced automatically

=item * Blessed object or CODE ref: mapped under C<$default>

=item * Array-ref of positional key names as C<$default>:
C<get_params([qw(name age)], @_)>

=back

=head3 ARGUMENTS

=over 4

=item C<$default> (scalar string, arrayref of strings, or C<undef>)

Controls how a single non-hash argument is interpreted:

=over 8

=item * B<string> -- used as the key name when a lone scalar, ref, or object
is received.

=item * B<arrayref of strings> -- positional key names; the I<n>th argument
is mapped to the I<n>th name.  Extra arguments are silently discarded;
missing arguments produce C<undef> values.

=item * B<undef> -- no default key; the caller must pass named pairs or a
single hash-ref.  An empty argument list returns C<undef>.

=back

=item C<@args>

The caller's argument list, passed either as a flat list (C<@_>) or as a
reference to the array (C<\@_>).  Both forms are accepted transparently.

=back

=head3 RETURNS

A hash-ref on success, or C<undef> when C<$default> is C<undef> and no
arguments are provided.

=head3 SIDE EFFECTS

Croaks from the caller's frame on programming errors (wrong calling
convention, non-ARRAY ref passed as C<$default>).  Confesses with a full
stack trace when C<$default> is defined but zero arguments are received,
because that almost always indicates a programming error.

=head3 API SPECIFICATION

=head4 Input

	{
		default => {
			type => [ 'string', 'stringref' ],
			optional => 1,
			position => 0,
		}, args => {
			type => [ 'array', 'arrayref' ],
			optional => 1,
			position => 1,
		}
	}

=head4 output

    {
	type => 'hashref',
	optional => 1,
    }

=head3 MESSAGES

    Message                                             Meaning                                Resolution
    --------------------------------------------------  -------------------------------------  ----------------------------------------------
    ::get_params: $default must be a scalar or          A non-ARRAY ref was passed as          Pass a plain string, arrayref of strings,
      arrayref                                          $default                               or undef
    Usage: Pkg->method($key => $val)  [stack trace]    $default is defined but no args given  Ensure the caller always passes a value
    Usage: Pkg->method()                               Odd-length or unrecognisable arg list  Correct the calling convention in the caller

=head3 PSEUDOCODE

    1.  Fast-path: if the sole argument is a plain HASH ref, return it
        immediately (fires before $default is inspected -- see LIMITATIONS).

    2.  Shift $default.  Validate: must be undef, a plain scalar, or an
        ARRAY ref.  Any other ref type croaks immediately.

    3.  If $default is an ARRAY ref, map remaining @_ positionally to those
        key names and return.  A single plain HASH ref is still passed
        through unchanged.

    4.  Detect the \@_ calling convention: if exactly one ARRAY ref argument
        remains, check the two-element (key => scalar-val) shorthand and
        return immediately when it matches.  Otherwise unwrap and use the
        array contents as the effective @args.

    5.  Dispatch on argument count:
        0 -- confess (with stack trace) if $default is defined;
             return undef otherwise.
        1 -- if $default is defined, wrap the single arg under $default
             (scalar, arrayref, scalarref->deref, coderef, blessed object).
             Without $default: unwrap REF-of-REF, pass HASH ref through,
             return empty ARRAY ref as-is.  Anything else: croak.
        2 with HASH ref as arg[1]
          -- Mandatory-positional + options-hashref pattern.
        even N -- treat as flat key/value pairs.
        odd N  -- croak.

=cut

sub get_params
{
	# Fast path: sole argument is already a plain hashref.  Returning it
	# directly avoids the overhead of shifting and inspecting $default.
	# Consequence: a single hashref always bypasses default key naming --
	# documented in LIMITATIONS.
	return $_[0] if (@_ == 1) && (ref($_[0]) eq $T_HASH);

	my $default = shift;

	if (ref($default) && (ref($default) ne $T_ARRAY)) {
		Carp::croak(__PACKAGE__, '::get_params: $default must be a scalar or arrayref');
	}

	# Positional-names feature: $default is an arrayref of key names and the
	# remaining @_ are values to map to those keys in order.
	if($default && (ref($default) eq $T_ARRAY)) {
		# Honour the single-hashref passthrough for consistency with scalar $default.
		return $_[0] if (@_ == 1) && (ref($_[0]) eq $T_HASH);
		my %rc;
		{ no warnings 'uninitialized'; @rc{@{$default}} = @_[0 .. $#{$default}] }
		return \%rc;
	}

	# Detect \@_ usage: caller passed a reference to its own @_.
	my ($args, $from_arrayref);
	if ((@_ == 1) && (ref($_[0]) eq $T_ARRAY)) {
		# Two-element shorthand: caller did routine('key' => 'scalar') and the
		# callee received \@_.  Only fires when the value is a plain scalar to
		# avoid ambiguity with an arrayref value.
		if($default && (@{$_[0]} == 2) && ($_[0]->[0] eq $default) && !ref($_[0]->[1])) {
			return { $default => $_[0]->[1] };
		}
		$args = $_[0];
		$from_arrayref = 1;
	} else {
		$args = \@_;
	}

	my $num_args = scalar @{$args};

	# --- Zero arguments ---
	if ($num_args == 0) {
		if (defined $default) {
			# Full stack trace via Devel::Confess because receiving zero args
			# when a default is defined is virtually always a programming error.
			Carp::confess('Usage: ', __PACKAGE__, '->', (caller(1))[3], "($default => \$val)");
		}
		return;
	}

	# --- One argument ---
	if ($num_args == 1) {
		if (defined $default) {
			my $arg  = $args->[0];
			my $kind = ref($arg);

			return { $default => $arg     } if !$kind;
			return { $default => $arg     } if $kind eq $T_ARRAY;
			return { $default => ${$arg}  } if $kind eq $T_SCALAR;
			return { $default => $arg     } if $kind eq $T_CODE;
			return { $default => $arg     } if Scalar::Util::blessed($arg);
			# Unblessed HASH ref falls through to the no-default path below,
			# where it is returned directly (see LIMITATIONS).
		}

		return unless defined $args->[0];

		# Copy before type checks: $args->[0] is an alias to the caller's
		# variable via @_ -- assigning through it would silently mutate the
		# caller's data.  Work on a named copy instead.
		my $val = $args->[0];
		$val = ${$val} if ref($val) eq $T_REF;

		return $val if ref($val) eq $T_HASH;

		# Empty arrayref with no default: return the ref itself.
		if ((ref($val) eq $T_ARRAY) && (@{$val} == 0)) {
			return $val;
		}

		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	}

	# --- Two arguments where the second is a hash ref ---
	# Handles the Obj->new($mandatory, \%options) convention.
	if (($num_args == 2) && (ref($args->[1]) eq $T_HASH)) {
		if (defined $default) {
			if (scalar keys %{$args->[1]}) {
				# When first arg is the default key name itself, second arg is its value.
				return { $default => $args->[1] } if $args->[0] eq $default;
				# Otherwise: first arg is the mandatory value; options are merged.
				return { $default => $args->[0], %{$args->[1]} };
			}
			# Empty options hashref: store the ref as the value.
			return { $default => $args->[1] };
		}
	}

	# --- \@_ with multiple values under a scalar default ---
	return { $default => $args } if $from_arrayref && defined $default;

	# --- Even-length list: flat key/value pairs ---
	if (($num_args % 2) == 0) {
		my %rc = @{$args};
		return \%rc;
	}

	Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
}

=head1 LIMITATIONS

=over 4

=item B<Single empty arrayref cannot be distinguished from C<\@_> of an empty list>

When the caller does C<foo([])> and the callee uses C<get_params('key', @_)>,
the C<@_> list is C<([])> -- one element, an arrayref.  The function
interprets the lone arrayref as a C<\@_> passthrough, unwraps it to an empty
list, and then croaks because C<$default> is defined but there are zero
arguments.  Workaround: pass the value as a named pair
(C<key =E<gt> []>) or ensure the callee always uses C<\@_>.

=item B<Single hash ref always bypasses C<$default> key naming>

C<get_params('config', { a =E<gt> 1 })> returns C<{ a =E<gt> 1 }>, not
C<{ config =E<gt> { a =E<gt> 1 } }>.  The fast path fires before C<$default>
is inspected.  To store a hash ref under a default key, pass it as a named
pair: C<get_params('config', config =E<gt> { a =E<gt> 1 })>.

=item B<No mechanism to mark a C<$default> argument as optional>

When C<$default> is a string and zero arguments are received, the function
always confesses.  There is no way to express I<"accept zero args and return
undef gracefully">.

=item B<Duplicate keys in a flat list silently overwrite; last value wins>

C<get_params(undef, foo =E<gt> 1, foo =E<gt> 2)> returns C<{ foo =E<gt> 2 }>
with no warning.  If an attacker controls part of the argument list, a
later duplicate key can silently override an earlier sanitised value.
Detect and reject duplicate keys in the validation layer (e.g.
L<Params::Validate::Strict>) rather than relying on C<get_params> to catch
them.

=item B<Positional-names C<$default> silently discards extra arguments>

C<get_params([qw(a b)], 1, 2, 3)> returns C<{ a =E<gt> 1, b =E<gt> 2 }>
and ignores C<3>.  If strict arity is required, validate the returned hash
with L<Params::Validate::Strict>.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report bugs or feature requests to C<bug-params-get at rt.cpan.org>
or through L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Get>.

=head1 SEE ALSO

=over 4

=item * L<Params::Smart>

=item * L<Params::Validate::Strict>

=item * L<Return::Set>

=item * L<Test Dashboard|https://nigelhorne.github.io/Params-Get/coverage/>

=back

=head1 SUPPORT

=over 4

=item * MetaCPAN: L<https://metacpan.org/dist/Params-Get>

=item * RT: L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Get>

=item * CPAN Testers: L<http://matrix.cpantesters.org/?dist=Params-Get>

=item * CPAN Testers Dependencies: L<http://deps.cpantesters.org/?module=Params::Get>

=back

=head2 FORMAL SPECIFICATION

=head3 get_params

    Let D = default key (Str | [Str*] | undef), A = argument tuple.

    get_params : D x A* -> HashRef | Undef

    -- Fast path (fires before D is inspected -- see LIMITATIONS)
    get_params(D, h)            == h             when |A|=1, h:HashRef

    -- Positional-names default
    get_params([n1..nk], v*)    == {ni -> vi}    i in 1..k, vi = undef when missing

    -- Scalar default, single arg
    get_params(d, s)            == {d -> s}      d:Str, s:Scalar
    get_params(d, a)            == {d -> a}      d:Str, a:ArrayRef
    get_params(d, \s)           == {d -> s}      d:Str (scalarref dereferenced)
    get_params(d, c)            == {d -> c}      d:Str, c:CodeRef
    get_params(d, o)            == {d -> o}      d:Str, o:BlessedObject

    -- Mandatory-positional + options-hashref
    get_params(d, v, {k->w..})  == {d->v, k->w..}    non-empty opts
    get_params(d, d, {k->w..})  == {d -> {k->w..}}   first arg IS the key name

    -- Named pairs
    get_params(undef, k1,v1..)  == {ki -> vi}    when |A| is even

    -- Empty / error
    get_params(undef)           == undef
    get_params(d)               => confess       d:Str (missing required arg)
    get_params(D, odd-list)     => croak

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.  If you use this module,
please let me know.

=cut

1;
