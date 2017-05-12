package Smart::Dispatch;

use 5.010;
use strict;
use warnings;

use Carp;
use Smart::Dispatch::Table ();
use Smart::Dispatch::Match ();

BEGIN {
	$Smart::Dispatch::AUTHORITY = 'cpan:TOBYINK';
	$Smart::Dispatch::VERSION   = '0.006';
}

use constant DEFAULT_MATCH_CLASS => (__PACKAGE__.'::Match');
use constant DEFAULT_TABLE_CLASS => (__PACKAGE__.'::Table');

our ($IN_FLIGHT, @LIST, @EXPORT);
BEGIN
{
	$Carp::Internal{$_}++
		foreach (__PACKAGE__, DEFAULT_MATCH_CLASS, DEFAULT_TABLE_CLASS);
	$IN_FLIGHT = 0;
	@LIST      = ();
	@EXPORT    = qw/dispatcher match match_using otherwise dispatch failover/;
}

use namespace::clean ();
use Sub::Exporter -setup => {
	exports => [
		dispatcher   => \&_build_dispatcher,
		match        => \&_build_match,
		match_using  => \&_build_match_using,
		otherwise    => \&_build_otherwise,
		dispatch     => \&_build_dispatch,
		failover     => \&_build_failover,
	],
	groups => [
		default      => [@EXPORT],
		tiny         => [qw/dispatcher match/],
	],
	collectors => [qw/class/],
	installer => sub {
		namespace::clean::->import(
			-cleanee => $_[0]{into},
			grep { !ref } @{ $_[1] },
		);
		goto \&Sub::Exporter::default_installer;
	},
};

sub _build_dispatcher
{
	my ($class, $name, $arg, $col) = @_;
	my $table_class =
		$arg->{class}
		// $col->{class}{table}
		// DEFAULT_TABLE_CLASS;
	
	return sub (&)
	{
		my $body = shift;
		local @LIST = ();
		local $IN_FLIGHT = 1;
		$body->();
		return $table_class->new(match_list => [@LIST]);
	}
}

sub _build_match
{
	my ($class, $name, $arg, $col) = @_;
	my $match_class =
		$arg->{class}
		// $col->{class}{match}
		// DEFAULT_MATCH_CLASS;
	
	return sub
	{
		croak "$name cannot be used outside dispatcher" unless $IN_FLIGHT;
		my ($condition, %args) = (@_ == 2) ? (shift, _k($_[-1]), shift) : (@_);
		push @LIST, $match_class->new(%args, test => $condition);
		return;
	}
}

sub _build_match_using
{
	my ($class, $name, $arg, $col) = @_;
	my $match_class =
		$arg->{class}
		// $col->{class}{match}
		// DEFAULT_MATCH_CLASS;
	
	return sub (&@)
	{
		croak "$name cannot be used outside dispatcher" unless $IN_FLIGHT;
		my ($condition, %args) = (@_ == 2) ? (shift, _k($_[-1]), shift) : (@_);
		push @LIST, $match_class->new(%args, test => $condition);
		return;
	}
}

sub _build_otherwise
{
	my ($class, $name, $arg, $col) = @_;
	my $match_class =
		$arg->{class}
		// $col->{class}{match}
		// DEFAULT_MATCH_CLASS;
	
	return sub
	{
		croak "$name cannot be used outside dispatcher" unless $IN_FLIGHT;
		my (%args) = (@_ == 1) ? (_k($_[-1]), shift) : (@_);
		push @LIST, $match_class->new(%args, is_unconditional => 1, test => sub {1});
		return;
	}
}

sub _build_dispatch
{
	my ($class, $name, $arg, $col) = @_;
	
	return sub (&)
	{
		croak "$name cannot be used outside dispatcher" unless $IN_FLIGHT;
		return('dispatch', shift);
	}
}

sub _build_failover
{
	my ($class, $name, $arg, $col) = @_;
	
	return sub (&)
	{
		croak "$name cannot be used outside dispatcher" unless $IN_FLIGHT;
		return('dispatch', shift, is_failover => 1);
	}
}

sub _k
{
	ref $_[0] eq 'CODE' ? 'dispatch' : 'value';
}

foreach my $f (@EXPORT)
{
	no strict 'refs';
	*{"$f"} = &{"_build_$f"}(__PACKAGE__, $f, {}, {});
}

__PACKAGE__
__END__

=head1 NAME

Smart::Dispatch - first-class switch statements

=head1 SYNOPSIS

 use Smart::Dispatch;
 my $given = dispatcher {
   match qr{ ^[A-J] }ix, dispatch { "Volume 1" };
   match qr{ ^[K-Z] }ix, dispatch { "Volume 2" };
   otherwise failover { Carp::croak "unexpected surname" };
 };
 my $surname = "Inkster";
 say $surname, " is in ", $dispatch->($surname), " of the phone book.";
 
=head1 DESCRIPTION

People have been using dispatch tables for years. They work along the
lines of:

 my $thing = get_foo_or_bar();
 
 my %dispatch = (
   foo   => sub { ... },
   bar   => sub { ... },
   );
 $dispatch{$thing}->();

Dispatch tables are often more elegant than long groups of
C<if>/C<elsif>/C<else> statements, but they do have drawbacks. Consider how
you'd change the example above to deal with C<$thing> being not just "foo" or
"bar", but adding all integers to the allowed values.

Perl 5.10 introduced smart match and the C<given> block. This allows stuff
like:

 my $thing = get_foo_or_bar();
 
 given ($thing)
 {
   when ("foo") { ... }
   when ("bar") { ... }
   when (looks_like_number($_)) { ... }
 }

The conditions in C<when> clauses can be arbirarily complex tests, and default
to comparisons using the smart match operator. This is far more flexible.

C<given> blocks do have some drawbacks over dispatch tables though. A dispatch
table is a first class object - you can put a reference to it in a variable,
and pass that reference as an argument to functions. You can check to see
whether a dispatch table contains particular entries:

 if ($dispatch{"foo"})  # dispatch table can deal with $thing="foo"

If passed a reference to an existing dispatch table, you can easily add
entries to it, or remove entries from it.

Smart::Dispatch is an attempt to combine some of the more useful features of
C<given> with dispatch tables.

=head2 Building a Dispatch Table

All the keywords used a build a dispatch table are lexical subs, which
means that you can import them into a particular code block and they
will not be available outside that block.

=head3 C<< dispatcher { CODE } >>

A dispatch table is built using the C<dispatcher> function which takes a
single block argument. This block will typically consist of a number of
C<< match >> statements, though you can theoretically put anything you
want inside it. (The code is run just once, when the dispatch table is
being built, and is called in void context.)

 my $dispatch_table = dispatcher { ... };

The return value is an L<Smart::Dispatch::Table> object.

=head3 C<< match $test, %args >>

The C<match> function adds a single entry to the current dispatch table.
The entry is a L<Smart::Dispatch::Match> object.

The C<< $test >> argument is the trigger for dispatching to that particular
entry in the table. It's like the contents of C<< when(...) >> in a
C<given> block. It is used as the right hand argument to a smart match
operation (see L<perlop>), so it can be a string/numeric constant, C<undef>,
a C<< qr/.../ >> quoted regular expression, or a coderef, or an reference
to an array containing any of the above. (There are other possibilities too,
though they are somewhat obscure.)

The hash of other arguments is passed to the constructor of
L<Smart::Dispatch::Match>.

=head3  C<< dispatch { CODE } >>

This introduces the code to run when a match has been successful. It is
used as follows:

 my $dispatch_table = dispatcher {
   match "foo", dispatch { "Monkey" };
   match "bar", dispatch { my $x = get_simian(); return $x };
 };

Actually the above is just syntactic sugar for

 my $dispatch_table = dispatcher {
   match "foo", 'dispatch' => sub { "Monkey" };
   match "bar", 'dispatch' => sub { my $x = get_simian(); return $x };
 };

So the only thing C<dispatch> is doing is depositing a coderef into the
C<%args> hash of C<match>.

=head3 C<< value => $value >>

In the case of the "Monkey" bit above, it's actually a little wasteful to
define a coderef (and run it when we do the dispatching later on) just to
return a constant string, so in this case we can use the 'value' argument
for C<match>, to provide a slight optimization:

 my $dispatch_table = dispatcher {
   match "foo", value => "Monkey";
   match "bar", dispatch { my $x = get_simian(); return $x };
 };

Note that C<value> is not a function. It's just a named argument for
C<match>. Nothing much magic is going on.

=head3 C<< match_using { CODE } %args >>

C<match_using> is exactly like C<match> but declared with a coderef
prototype (see L<perlsub>). That is, it just gives you syntactic sugar
for the case where C<$test> is a coderef. The following are equivalent:

=over

=item C<< match_using { $_ < 5 } dispatch { say "$_ is low" }; >>

=item C<< match sub { $_ < 5 }, 'dispatch' => sub { say "$_ is low" }; >>

=back

=head3 C<< otherwise %args >>

C<otherwise> is equivalent to C<default> in C<given> blocks, or C<else> in
C<if> blocks. It matches all other cases, and must thus be the last match
declared.

Again this is really just syntactic sugar. The following are equivalent:

=over

=item C<< otherwise dispatch { undef }; >>

=item C<< match sub { 1 }, 'is_unconditional' => 1, 'dispatch' => sub { undef }; >>
 
=back

Note that C<otherwise> explicitly marks the match as an "unconditional"
match. This allows Smart::Dispatch to complain if C<otherwise> is not the
last match in a dispatch table. And it helps when you try to combine
multiple dispatch tables to know which is the "otherwise" match.

=head3 C<< failover { CODE } >>

This is roughly the same as C<dispatch>, but is intended for marking
dispatches that can be regarded as failures:

 my $roman = dispatcher {
   match qr{\D}, failover { croak "non-numeric" };
   match [1..3], dispatch { "I" x $_ };
   match 4, value => 'IV';
   match [5..8], dispatch { 'V'.('I' x ($_-5)) };
   match 9, value => 'IX';
   match 10, value => 'X';
   otherwise failover { croak "out of range" };
 };

In terms of actually dispatching from the dispatch table, failovers work
exactly the same as any other dispatches. However, because the dispatch
table knows which matches are successes and which are failures, this
information can be queried.

It should be no surprise by now that the C<failover> function is just
syntactic sugar, and the same effect can be achieved without it. The
following are equivalent:

=over

=item C<< match $test, failover {...}; >>

=item C<< match $test, 'is_failover' => 1, 'dispatch' => sub {...}; >>

=back

=head2 Using a Dispatch Table

OK, so now you know how to build a dispatch table, but once we've got
one, how can we use it?

Dispatch tables, although they are not coderefs, overload C<< &{} >>,
which means they can be called like coderefs.

 my $biological_sex = dispatcher {
   match 'XX',         dispatch { 'Female' };
   match ['XY', 'YX'], dispatch { 'Male' };
   otherwise           failover { '????' };
 };
 
 my $sex_chromosomes = 'XY';
 say "I am a ", $biological_sex->($sex_chromosomes);

The above will say "I am a Male".

Note that the dispatch and failover subs here are pretty boring (we could
have just used C<<value>>), but any arbitrary Perl function is allowed.
Perl functions of course accept argument lists. Any argument list passed
into the dispatch table will be passed on to the dispatched function.

 my $biological_sex = dispatcher {
   match 'XX',
     dispatch { $_[1] eq 'fr' ? 'Femelle' : 'Female' };
   match ['XY', 'YX'],
     dispatch { $_[1] eq 'fr' ? 'Male' : 'Male' };
   otherwise
     failover { '????' };
 };
 
 my $sex_chromosomes = 'XX';
 say "I am a ", $biological_sex->($sex_chromosomes, 'en');
 say "Je suis ", $biological_sex->($sex_chromosomes, 'fr');

Note that within C<match_using>, C<dispatch> and C<failover> blocks, the
value being matched is available in the variable C<$_>. The following
match demonstrates this:

 match_using { $_ < 5 } dispatch { say "$_ is low" }

It is possible to check whether a dispatch table is able to handle a
particular value.

 my $sex_chromosomes = 'AA';
 if ($biological_sex ~~ $sex_chromosomes)
 {
   say "Dispatch table cannot handle chromosomes $sex_chromosomes";
 }
 else
 {
   say $biological_sex->($sex_chromosomes);
 }

This is where C<failover> comes in. Failover matches are B<not> considered
when determining whether a dispatch table is capable of handling a value.

=head2 Manipulating Dispatch Tables

If you have an existing dispatch table, it's possible to add more entries
to it. For this purpose, Smart::Dispatch overloads the C<<< .= >>> and
C<<< += >>> operators.

 my $more_sexes = dispatcher {
   match 'XYY',  dispatch { 'Supermale' };
   match 'XXX',  dispatch { 'Superfemale' };
 };
 $biological_sex .= $more_sexes;

The difference between the two operators is the priority is which matches
are tested.

 my $match1 = dispatcher {
   match 1, dispatch { 'One' };
 };

We can add some more matches like this:

 $match1 .= dispatcher {
   match qr{^1}, dispatch { 'Leading one' };
 };

When dispatching value "1", the result will still be "One", because the added
matches have lower priority than the original ones.

But if they are combined as:

 $match += dispatcher {
   match qr{^1}, dispatch { 'Leading one' };
 };

Then when dispatching value "1", the result will be "Leading one" because
the newer matches are given higher priority.

It is also possible to use C<< . >> and C<< + >> in their non-assignment
forms:

 my $enormous_match = $big_match . $large_match . $mighty_match;

(Some future version may introduce the ability to do subtraction, but there
are difficulties with this concept. For now, if you want to do subtraction,
look at the internals of Smart::Dispatch::Table.)

If one or both dispatch tables contain an unconditional match (C<otherwise>),
then these will be combined intelligently. The result will only have one
unconditional match (the higher priority one).

=head2 Import

By default Smart::Dispatch exports the following functions:

=over

=item * C<dispatch>

=item * C<dispatcher>

=item * C<failover>

=item * C<match>

=item * C<match_using>

=item * C<otherwise>

=back

It is possible to only import a subset of those:

 use Smart::Dispatch qw/dispatcher match otherwise/;

As noted in the "Building a Dispatch Table" section, a minimal set of
functions is just C<dispatcher> and C<match>. All the others are
just syntactic sugar. If you just want those two, then you can do:

 use Smart::Dispatch qw/:tiny/;

Smart::Dispatch uses L<Sub::Exporter> which provides a dizzying array of
cool options, such as:

 use Smart::Dispatch -all => { -prefix => 'sd_' };

which imports all the symbols but prefixed with "sd_".

 use Smart::Dispatch
   qw/dispatcher dispatch match/,
   otherwise => { -as => 'last_resort' };

which renames "otherwise" to "last_resort".

If you've written subclasses of L<Smart::Dispatch::Table> and
L<Smart::Dispatch::Match> and you want Smart::Dispatch to use your
subclasses, then you can do this:

 use Smart::Dispatch
   qw/dispatcher dispatch match/,
   otherwise => { -as => 'last_resort' },
   class => {
     table => 'My::Dispatch::Table',
     match => 'My::Dispatch::Match',
     };

Whatsmore, the C<class> option can be set on a keyword-by-keyword basis for
C<match>, C<match_using> and C<otherwise>.

 use Smart::Dispatch
   qw/dispatcher dispatch match/,
   otherwise => {
     -as   => 'last_resort',
     class => 'My::Other::Match',
     },
   class => {
     table => 'My::Dispatch::Table',
     match => 'My::Dispatch::Match',
     };

=head2 Constants

=over

=item * C<DEFAULT_MATCH_CLASS>

=item * C<DEFAULT_TABLE_CLASS>

=back

=head2 Dispatch Table Internals

See L<Smart::Dispatch::Table> and L<Smart::Dispatch::Match>.

Note that this is an early release, so the internals are still likely
to change somewhat between versions. The function-based API should be
fairly steady though.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Smart-Dispatch>.

=head1 SEE ALSO

"Switch statements" in L<perlsyn>; L<Acme::Given::Hash>.

L<http://www.perlmonks.org/?node_id=954831>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

