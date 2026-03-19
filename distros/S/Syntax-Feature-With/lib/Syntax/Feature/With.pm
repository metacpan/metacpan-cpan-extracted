package Syntax::Feature::With;

use strict;
use warnings;

use Carp 'croak';
use Exporter 'import';
use PadWalker qw(closed_over set_closed_over);

our @EXPORT_OK = qw(with with_hash);
our @EXPORT = qw(with with_hash);

our $VERSION = '0.02';

# Track nested with() depth for trace/debug output
my $WITH_DEPTH = 0;

=head1 NAME

Syntax::Feature::With - Simulate Pascal's "with" statement in Perl

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Syntax::Feature::With qw(with with_hash);

    my %h = ( a => 1, b => 2 );
    my ($a, $b);

    # Basic usage
    with \%h, sub {
        say $a;   # 1
        $b = 99;  # updates %h
    };

    # Strict mode
    with -strict => \%h, sub {
        say $a;   # ok
        say $b;   # ok
        say $c;   # error: undeclared
    };

    # Debug mode
    with -debug => \%h, sub {
        ...
    };

    # Trace mode (includes debug)
    with -trace => \%h, sub {
        ...
    };

    # Convenience wrapper
    with_hash %h => sub {
        say $a;
    };

=head1 DESCRIPTION

C<with()> provides a simple, predictable way to temporarily alias hash
keys into lexical variables inside a coderef.
It is implemented using L<PadWalker> and requires no XS, no parser hooks, and no syntax changes.

=head1 FEATURES

=head2 Read/write aliasing

Lexicals declared in the outer scope become aliases to hash entries:

    my ($a);
    with \%h, sub { $a = 10 };   # updates $h{a}

=head2 Strict mode

    with -strict => \%h, sub { ... };

Every valid hash key must have a matching lexical declared in the outer
scope. Missing lexicals cause an immediate error.

=head2 Debug mode

    with -debug => \%h, sub { ... };

Prints a summary of aliasing decisions:

    Aliased: $a -> %hash{a}
    Ignored: foo-bar (invalid identifier)
    Ignored: y (no lexical declared)

=head2 Trace mode

    with -trace => \%h, sub { ... };

Shows entry/exit and nesting depth:

    [with depth=1] entering with()
    Aliased: $a -> %hash{a}
    [with depth=1] leaving with()

Trace mode implies debug mode.

=head2 Nested with() support

Nested calls work naturally:

    with \%h1, sub {
        with \%h2, sub {
            ...
        };
    };

=head2 with_hash wrapper

Syntactic sugar:

    with_hash %h => sub { ... };

=head1 COOKBOOK

This section provides practical,
ready-to.use patterns for common tasks
using C<with_hash> and C<with>.
Each example is self-contained and demonstrates a specific technique or flag combination.

=head2 Basic Aliasing

Expose hash keys as lexicals inside a block:

    my %cfg = ( host => 'localhost', port => 3306 );
    my ($host, $port);

    with_hash \%cfg, sub {
        say "$host:$port";   # prints "localhost:3306"
        $port = 3307;        # updates %cfg
    };

=head2 Readonly Aliases

Make lexicals read-only while still reflecting external changes:

    my %cfg = ( retries => 3 );
    my ($retries);

    with_hash -readonly => \%cfg, sub {
        say $retries;        # ok
        $retries++;          # dies
    };

=head2 Strict Mode (lexicals must exist)

Require that every aliased key has a declared lexical:

    my %cfg = ( host => 'localhost', port => 3306 );
    my ($host, $port);

    with_hash -strict => \%cfg, sub {
        say $host;
        say $port;
    };

If a lexical is missing, C<-strict> throws an error before the block runs.

=head2 Strict Keys (keys must have lexicals)

Require that every visible key has a corresponding lexical:

    my %cfg = ( host => 'localhost', port => 3306 );
    my ($host, $port);

    with_hash -strict_keys => \%cfg, sub {
        () = $host;   # ensure PadWalker sees it
        () = $port;
    };

This is the inverse of C<-strict>.

=head2 Renaming Keys

Expose hash keys under different lexical names:

    my %cfg = ( 'http-status' => 200, 'user_id' => 42 );
    my ($status, $user);

    with_hash
        -rename => {
            'http-status' => 'status',
            'user_id'     => 'user',
        },
        \%cfg,
        sub {
            say $status;   # 200
            say $user;     # 42
        };

=head2 Filtering Keys with C<-only>

Expose only a subset of keys:

    my %cfg = ( host => 'localhost', port => 3306, debug => 1 );
    my ($host);

    with_hash
        -only => [qw/host/],
        \%cfg,
        sub {
            say $host;   # ok
            # $port and $debug are not aliased
        };

=head2 Filtering Keys with C<-except>

Exclude specific keys:

    my %cfg = ( host => 'localhost', port => 3306, debug => 1 );
    my ($host, $port);

    with_hash
        -except => [qw/debug/],
        \%cfg,
        sub {
            say $host;   # ok
            say $port;   # ok
            # $debug is not aliased
        };

=head2 Combining Filtering and Renaming

Filtering happens first, then renaming:

    my %cfg = ( 'http-status' => 200, foo => 1, bar => 2 );
    my ($status);

    with_hash
        -only   => [qw/http-status/],
        -rename => { 'http-status' => 'status' },
        \%cfg,
        sub {
            say $status;   # 200
        };

=head2 Nested C<with_hash> Blocks

Each block gets its own aliasing environment:

    my %outer = ( a => 1 );
    my %inner = ( b => 2 );

    my ($a, $b);

    with_hash \%outer, sub {
        say $a;   # 1

        with_hash \%inner, sub {
            say $b;   # 2
        };

        say $a;   # still 1
    };

=head2 Using C<with> Directly (Advanced)

C<with> is the low-level engine.
Use it when you already have a validated
hashref and want direct control:

    my %cfg = ( x => 10, y => 20 );
    my ($x, $y);

    with \%cfg, sub {
        $x += $y;
    };

=head2 Forcing PadWalker to See a Lexical

PadWalker only reports lexicals that the coderef actually closes over.
To ensure a lexical is visible under C<-strict_keys>, use:

    () = $debug;

This evaluates the variable in void context, ensuring that PadWalker
treats it as closed over without warnings.

=cut

# ------------------------------------------------------------
# with() — main entry point
# ------------------------------------------------------------
sub with {
	my @args = @_;

	my %opts = (
		# strict	  => 0,
		# debug	   => 0,
		# trace	   => 0,
		# rename	  => undef,
		# readonly	=> 0,
		# strict_keys => 0,
	);

	while (@args && $args[0] =~ /^-(strict|debug|trace|rename|readonly|strict_keys)$/) {
		my $flag = shift @args;

		if ($flag eq '-rename') {
			my $map = shift @args;
			croak 'with(): -rename expects a hashref' unless ref($map) eq 'HASH';

			$opts{rename} = $map;
			next;
		}

		$flag =~ s/^-//;
		$opts{$flag} = 1;
	}

	$opts{debug} = 1 if $opts{trace};

	my ($href, $code) = @args;

	croak 'with(): first argument must be a hashref' unless ref($href) eq 'HASH';

	croak 'with(): second argument must be a coderef' unless ref($code) eq 'CODE';

	$WITH_DEPTH++;
	warn "[with depth=$WITH_DEPTH] entering with()" if $opts{trace};

	my $closed = closed_over($code);
	my %newpad = %$closed;

	# --------------------------------------------------------
	# Process each hash key (aliasing)
	# --------------------------------------------------------
	KEY: for my $key (keys %$href) {
		# Determine lexical name (after rename)
		my $lex = $opts{rename} && exists $opts{rename}{$key} ? $opts{rename}{$key} : $key;

		# Skip invalid identifiers
		unless ($lex =~ /^[A-Za-z_]\w*$/) {
			warn "Ignored: $key (invalid identifier as $lex)" if $opts{debug};
			next KEY;
		}

		my $var = '$' . $lex;

		# strict_keys: every valid key must have a lexical
		if ($opts{strict_keys} && !exists $newpad{$var}) {
			die "with(): strict_keys mode: hash key '$key' has no lexical \$$lex";
		}

		# strict: only keys that WOULD be aliased must have lexicals
		unless (exists $newpad{$var}) {
			if ($opts{strict}) {
				die "with(): strict mode: lexical \$$lex not declared in outer scope";
			}
			warn "Ignored: $key (no lexical \$$lex declared)" if $opts{debug};
			next KEY;
		}

		# Alias
		if ($opts{readonly}) {
			tie my $ro, 'Syntax::Feature::With::ReadonlyScalar', \$href->{$key};
			$newpad{$var} = \$ro;
		} else {
			$newpad{$var} = \$href->{$key};
		}

		warn "Aliased: \$$lex => \%hash{$key}" if $opts{debug};
	}

	set_closed_over($code, \%newpad);

	my $result = $code->();

	warn "[with depth=$WITH_DEPTH] leaving with()" if $opts{trace};
	$WITH_DEPTH--;

	return $result;
}

=head2 with_hash

    with_hash \%hash, sub {
        say $foo;     # reads $hash{foo}
        $bar = 123;   # writes to $hash{bar}
    };

    with_hash strict => a => 1, b => 2, sub {
        ...
    };

Execute a block with temporary lexical aliases to the keys of a hash.

C<with_hash> provides a convenient way to work with a hash by exposing each
key as a lexical variable inside a coderef. Reads and writes to those
lexicals operate directly on the underlying hash, making the block feel like
it has named parameters or local variables without the usual unpacking
boilerplate.

This is syntactic sugar around C<with()>, normalizing the arguments and
ensuring that the hash and coderef are parsed correctly.

=head3 Arguments

C<with_hash> accepts the following forms:

=over 4

=item * Optional flags

One or more strings that modify behaviour (e.g. C<strict>, C<debug>).
Flags must appear first.

=item * A hash reference

    with_hash \%h, sub { ... };

=item * A hash list

    with_hash a => 1, b => 2, sub { ... };

The list must contain an even number of elements.

When called with a key/value list rather than a hash reference,
C<with_hash> constructs an internal hash for the duration of the block.
Writes inside the block update this internal hash, not the caller's variables.

=item * A final coderef (required)

The last argument must be a coderef. It receives no parameters; instead,
lexical aliases are created for each hash key.

=back

=head3 Behaviour

Inside the coderef:

=over 4

=item * Each hash key becomes a lexical variable

    $foo   # alias to $hash{foo}
    $bar   # alias to $hash{bar}

=item * Assigning to a lexical updates the original hash

    $foo = 42;   # sets $hash{foo} = 42

=item * Reading the lexical reads from the hash

=item * Aliases are removed when the coderef returns

=back

=head3 Error Handling

C<with_hash> throws descriptive exceptions when:

=over 4

=item * No coderef is provided

=item * A hash list has an odd number of elements

=item * Extra arguments appear after the coderef

=item * The hash argument is neither a hashref nor a valid key/value list

=back

These errors are intended to catch common mistakes early and make test
failures easier to diagnose.

=head3 Return Value

Returns whatever the coderef returns.

=head3 Examples

Using a hashref:

    my %config = ( host => 'localhost', port => 3306 );

    with_hash \%config, sub {
        say "$host:$port";   # prints "localhost:3306"
        $port = 3307;        # updates %config
    };

Using a hash list:

    with_hash debug => 1, retries => 3, sub {
        $retries++;          # modifies the underlying hash
    };

With flags:

    with_hash strict => \%opts, sub {
        ...
    };

=head3 Notes

C<with_hash> is intended for small, self-contained blocks where aliasing
improves clarity. It is not a general-purpose replacement for normal hash
access, nor does it attempt to provide full lexical scoping tricks beyond
simple aliasing.

=head3 with vs. with_hash

Although C<with> and C<with_hash> share a similar calling style, they serve
different purposes and operate at different levels of abstraction.

=head4 C<with> - the low-level aliasing engine

C<with> is the core primitive. It expects:

    with \%hash, sub { ... };

It assumes that:

=over 4

=item * The first argument is already a valid hash reference

=item * The last argument is a coderef

=item * Any flags have already been parsed

=item * The hash keys are suitable for use as lexical variable names

=back

C<with> performs no argument normalization. It simply creates lexical aliases
for each key in the provided hash and executes the coderef. It is strict,
minimal, and intended for internal use or advanced callers who want full
control.

=head4 C<with_hash> - the user-friendly wrapper

C<with_hash> is the public, ergonomic interface. It accepts a much more
flexible argument style:

    with_hash a => 1, b => 2, sub { ... };
    with_hash \%hash, sub { ... };
    with_hash strict => a => 1, b => 2, sub { ... };

C<with_hash> is responsible for:

=over 4

=item * Parsing optional flags

=item * Accepting either a hash reference OR a key/value list

=item * Validating argument structure (even key/value pairs, final coderef, etc.)

=item * Converting key/value lists into a hash reference

=item * Producing clear, user-facing error messages

=item * Calling C<with> with a normalized hashref and the coderef

=back

In other words, C<with_hash> does all the DWIM work so that users can write
clean, concise code without worrying about argument shape or validation.

=head4 Summary

=over 4

=item * Use C<with_hash> in normal code.

=item * Use C<with> only when you already have a validated hashref and want
direct access to the aliasing mechanism.

=back

C<with_hash> is the safe, friendly API.
C<with> is the strict,
low-level engine that powers it.

=head3 Key Filtering: C<-only> and C<-except>

C<with_hash> supports two optional flags that control which keys from the
input hash are exposed as lexical aliases inside the block.

These flags allow you to limit or refine the set of variables created,
making aliasing more intentional and avoiding namespace clutter.

=head4 C<-only => \@keys>

    with_hash -only => [qw/foo bar/], \%hash, sub {
        say $foo;   # alias to $hash{foo}
        say $bar;   # alias to $hash{bar}
    };

Only the listed keys are aliased. Any keys not listed are ignored. Keys that
do not exist in the hash are silently skipped.

=head4 C<-except => \@keys>

    with_hash -except => [qw/debug verbose/], \%hash, sub {
        say $host;   # ok
        say $port;   # ok
        # $debug is NOT aliased
    };

All keys except those listed are aliased.

=head4 Rules and Validation

=over 4

=item *

C<-only> and C<-except> are mutually exclusive.
Using both at the same time results in an error.

=item *

Both flags require an array reference. Anything else triggers an error.

=item *

Filtering is applied B<before> renaming or strict key validation.
Filtering temporarily hides keys from the underlying hash during the with() call.
Keys not selected by only/except are removed before aliasing and restored afterwards,
ensuring that write-through aliasing always affects the original hash.

=item *

If filtering removes all keys, the block still runs normally; no aliases are
created.

=back

=head4 Error Handling

All validation errors are raised via C<Croak>, so error messages correctly
report the caller's file and line number.

=head3 -readonly

    with_hash -readonly => \%hash, sub {
        say $foo;   # ok
        $foo = 10;  # dies
    };

The C<-readonly> flag creates read-only aliases for each exposed hash key.
Reading works normally, but any attempt to assign to a lexical alias will
throw an exception.

Readonly aliases still reflect changes made to the underlying hash from
outside the block.

Readonly mode works with all other flags, including C<-rename>,
C<-only>, C<-except>, C<-strict>, and C<-trace>.

=head3 -rename => { OLDKEY => NEWLEX, ... }

The C<-rename> flag allows you to expose hash keys under different lexical
variable names inside the C<with_hash> block.

This is useful when the original hash keys are not valid Perl identifiers
(e.g. contain hyphens), or when you want more convenient or descriptive
lexical names.

    with_hash
        -rename => {
            'http-status' => 'status',
            'user_id'     => 'user',
        },
        \%hash,
        sub {
            say $status;   # alias to $hash{'http-status'}
            say $user;     # alias to $hash{'user_id'}
        };

Renaming does B<not> copy values.  The new lexical name is aliased directly
to the original hash slot, so write-through works as expected:

    $status = 404;   # updates $hash{'http-status'}
    $user   = 99;    # updates $hash{'user_id'}

=head4 Interaction with filtering

Renaming happens B<after> C<-only> / C<-except> filtering.  Filtering selects
which keys are visible; renaming changes the lexical names of those keys.

For example:

    with_hash
        -only   => [qw/http-status foo/],
        -rename => { 'http-status' => 'status' },
        \%hash,
        sub {
            say $status;   # ok
            say $foo;      # ok
            say $user;     # undef (not selected by -only)
        };

=head4 Interaction with strict mode

When C<-strict> is enabled, every renamed lexical must be declared in the
outer scope.  If a renamed lexical does not exist, C<with_hash> will croak:

    my ($status);   # but NOT $missing_lex

    with_hash
        -strict,
        -rename => { 'http-status' => 'missing_lex' },
        \%hash,
        sub { ... };

This dies with:

    strict mode: lexical $missing_lex not declared in outer scope

=head4 Validity of new names

The new lexical name must be a valid Perl identifier:

    /^[A-Za-z_]\w*$/

If the new name is invalid, the key is ignored (or causes an error under
C<-strict>).

=head4 Summary

=over 4

=item *
Renames hash keys to different lexical variable names.

=item *
Write-through updates the original hash.

=item *
Works with C<-only> and C<-except>.

=item *
Respects C<-strict> (renamed lexicals must exist).

=item *
Does not copy values; aliases directly to the original storage.

=back

=head3 -strict_keys

    with_hash -strict_keys => \%hash, sub { ... };

The C<-strict_keys> flag enforces that every key in the input hash must have
a corresponding lexical variable declared in the outer scope. If any key is
missing a lexical, C<with_hash> will croak before executing the block.

This is the inverse of C<-strict>, which enforces that every lexical must
correspond to a hash key.

Strict key checking happens after filtering and renaming, so only the keys
that are actually exposed must be declared.

    my ($host, $port);

    with_hash
        -strict_keys,
        -rename => { host => 'h' },
        \%config,
        sub { ... };

If C<%config> contains a key that does not map to a declared lexical (after
renaming), an error is thrown.

This mode is useful for catching unexpected or misspelled keys in
configuration hashes or user input.

=head4 A note on C<-strict_keys> and unused lexicals

C<-strict_keys> relies on L<PadWalker/closed_over> to determine which
lexical variables are visible to the coderef.  PadWalker only reports
lexicals that the coderef actually closes over.  A lexical that is
declared in the outer scope but never referenced inside the block is
not considered "closed over" and therefore will not appear in the pad.

This means that under C<-strict_keys>, a declared lexical must be
*mentioned* inside the block, otherwise it will be treated as missing:

    my ($host, $port, $debug);

    with_hash -strict_keys => \%cfg, sub {
        say $host;   # ok
        # $port is declared but unused - PadWalker does not report it
        # $debug is declared but unused - also not reported
    };

The above will die with:

    strict_keys mode: hash key 'port' has no lexical $port

To force a lexical to be recognised without producing warnings, use the
standard idiom:

    () = $port;
    () = $debug;

This evaluates the variable in void context, ensuring that PadWalker
treats it as closed over, without affecting program behaviour.

This is a limitation of Perl's closure model rather than of this module.

=cut

sub with_hash {
	my @args = @_;

	# 1. Boolean flags
	my @flags;
	while (@args && $args[0] =~ /^-(strict|debug|trace|readonly|strict_keys)$/) {
		push @flags, shift @args;
	}

	# 2. Value-taking flags: -only, -except, -rename
	my ($only, $except);

	while (@args && $args[0] =~ /^-(only|except|rename)$/) {
		my $flag  = shift @args;
		my $value = shift @args;

		if ($flag eq '-only' || $flag eq '-except') {
			croak "with_hash(): $flag expects an arrayref" unless ref($value) eq 'ARRAY';

			$only   = $value if $flag eq '-only';
			$except = $value if $flag eq '-except';
			next;
		}

		if ($flag eq '-rename') {
			croak "with_hash(): -rename expects a hashref" unless ref($value) eq 'HASH';

			push @flags, ($flag, $value);
			next;
		}
	}

	croak 'with_hash(): cannot use both -only and -except' if $only && $except;

	# 3. Extract coderef
	croak 'with_hash(): missing coderef' unless @args;

	my $code = pop @args;

	croak 'with_hash(): last argument must be a coderef' unless ref($code) eq 'CODE';

	# 4. Normalize hash argument
	my $href;

	if (@args == 1 && ref($args[0]) eq 'HASH') {
		$href = shift @args;
	} else {
		if (@args >= 1 && ref($args[0]) eq 'HASH') {
			croak 'with_hash(): hashref must be the only argument before coderef';
		}

		croak 'with_hash(): odd number of elements in hash list' if @args % 2;

		my %h = @args;
		$href = \%h;
	}

	# 5. Filtering (delete/restore)
	my %removed;

	if ($only || $except) {
		my %only   = $only   ? map { $_ => 1 } @$only   : ();
		my %except = $except ? map { $_ => 1 } @$except : ();

		my %keep;
		if ($only) {
			%keep = %only;
		} elsif ($except) {
			%keep = map { $_ => 1 } grep { !$except{$_} } keys %$href;
		}

		for my $k (keys %$href) {
			next if $keep{$k};
			$removed{$k} = $href->{$k};
			delete $href->{$k};
		}
	}

	# 6. Call underlying engine — FLAGS FIRST
	my $result = with(@flags, $href, $code);

	# 7. Restore removed keys
	@$href{keys %removed} = values %removed if %removed;

	return $result;
}

1;

package Syntax::Feature::With::ReadonlyScalar;

use Carp 'croak';

sub TIESCALAR {
	my ($class, $ref) = @_;
	return bless { ref => $ref }, $class;
}

sub FETCH {
	my $self = $_[0];
	return ${ $self->{ref} };
}

sub STORE {
	my ($self, $value) = @_;
	croak 'with(): readonly variable cannot be modified';
}

1;

__END__

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LIMITATIONS

C<with()> uses PadWalker to manipulate lexical pads.
This is fast enough for normal use, but not intended for tight loops or high-frequency calls.

=over 4

=item *

Lexicals must be declared in the outer scope.

=item *

Only hashrefs are supported.

=item *

Only keys matching C</^[A-Za-z_]\w*$/> are eligible.

=back

=head1 AUTHOR

Nigel Horne

=head1 REPOSITORY

L<https://github.com/nigelhorne/Syntax-Feature-With>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-syntax-feature-with at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Syntax-Featre-With>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Syntax-Feature-With

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Syntax-Featre-With>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Syntax-Featre-With>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Syntax-Featre-With>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Syntax-Featre-With>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut
