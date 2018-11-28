use 5.006;
use strict;
use warnings;

package PerlX::Maybe;

BEGIN {
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '1.201';
	
	our @EXPORT      = qw/ maybe /;
	our @EXPORT_OK   = qw/ maybe provided provided_deref provided_deref_with_maybe/;
	our %EXPORT_TAGS = (all => \@EXPORT_OK, default => \@EXPORT);
}

sub import
{
	if (@_ == 1)
	{
		my $caller = caller;
		no strict 'refs';
		*{"$caller\::maybe"} = \&maybe;
		return;
	}
	elsif (grep ref||/^-/, @_)
	{
		require Exporter::Tiny;
		our @ISA = qw/ Exporter::Tiny /;
		no warnings 'redefine';
		*import = \&Exporter::Tiny::import;
		*unimport = \&Exporter::Tiny::unimport;
		goto \&Exporter::Tiny::import;
	}
	require Exporter;
	goto \&Exporter::import;
}

sub unimport
{
	require Exporter::Tiny;
	our @ISA = qw/ Exporter::Tiny /;
	no warnings 'redefine';
	*import = \&Exporter::Tiny::import;
	*unimport = \&Exporter::Tiny::unimport;
	goto \&Exporter::Tiny::unimport;
}

sub _croak
{
	require Carp;
	goto \&Carp::croak;
}

unless (($ENV{PERLX_MAYBE_IMPLEMENTATION}||'') =~ /pp/i)
{
	eval q{ use PerlX::Maybe::XS 0.003 ':all' };
}

__PACKAGE__->can('maybe') ? eval <<'END_XS' : eval <<'END_PP';

sub IMPLEMENTATION () { "XS" }

END_XS

sub IMPLEMENTATION () { "PP" }

sub maybe ($$@)
{
	if (defined $_[0] and defined $_[1])
	{
		@_
	}
	else
	{
		(scalar @_ > 1) ? @_[2 .. $#_] : qw()
	}
}

sub provided ($$$@)
{
	if (shift)
	{
		@_
	}
	else
	{
		(scalar @_ > 1) ? @_[2 .. $#_] : qw()
	}
}

END_PP

sub provided_deref ($$@)
{
	unshift @_, 0;
	goto \&_provided_magic;
}

sub provided_deref_with_maybe ($$@)
{
	unshift @_, 1;
	goto \&_provided_magic;
}

sub _provided_magic ($$$@)
{
	my $m = shift; # maybe, clean up private keys
	
	if (shift)
	{
		my $r = shift;
		my $t = ref $r;
		_croak "Not a reference, $r" unless $t;
		
		my @vals;
		if ($t eq 'ARRAY')
		{
			return (@$r, @_) unless $m;
			@vals = @$r;
		}
		
		elsif ($t eq 'CODE')
		{
			return ($r->(), @_) unless $m;
			@vals = $r->();
		}

		elsif ($t eq 'HASH')
		{
			return (%$r, @_) unless $m;
			@vals = %$r;
		}
		
		elsif (do { require Scalar::Util; Scalar::Util::blessed($r) })
		{
			my %vals = eval { %$r };
			_croak "Can not unwrap $r into a hash" if $@;
			return (%vals, @_) unless $m;
			
			delete $vals{$_} for grep /^_/, keys %vals;
			@vals = %vals;
		}

		else
		{
			_croak "Can not dereference, $r ... yet";
		}
		
		my @return;
		for (my $i = 0; $i < @vals; $i+=2) {
			push @return, $vals[$i], $vals[$i+1] if defined $vals[$i] && defined $vals[$i+1];
		}
		
		return (@return, @_);
	}
	else
	{
		(scalar @_ > 0) ? @_[1 .. $#_] : qw()
	}
}

__FILE__
__END__

=pod

=encoding utf8

=for stopwords benchmarking

=head1 NAME

PerlX::Maybe - return a pair only if they are both defined

=head1 SYNOPSIS

You once wrote:

 my $bob = Person->new(
    defined $name ? (name => $name) : (),
    defined $age ? (age => $age) : (),
 );

Now you can write:

 use PerlX::Maybe;
 
 my $bob = Person->new(
    maybe name => $name,
    maybe age  => $age,
 );

=head1 DESCRIPTION

Moose classes (and some other classes) distinguish between an attribute
being unset and the attribute being set to undef. Supplying a constructor
arguments like this:

 my $bob = Person->new(
    name => $name,
    age => $age,
 );

Will result in the C<name> and C<age> attributes possibly being set to
undef (if the corresponding C<$name> and C<$age> variables are not defined),
which may violate the Person class' type constraints.

(Note: if you are the I<author> of the class in question, you can solve
this using L<MooseX::UndefTolerant>. However, some of us are stuck using
non-UndefTolerant classes written by third parties.)

To ensure that the Person constructor does not try to set a name or age
at all when they are undefined, ugly looking code like this is often used:

 my $bob = Person->new(
    defined $name ? (name => $name) : (),
    defined $age ? (age => $age) : (),
 );

or:

 use PerlX::Maybe;

 my $bob = Person->new(
    (name => $name) x!!(defined $name),
    (age  => $age)  x!!(defined $age),
 );

A slightly more elegant solution is the C<maybe> function.

=head2 Functions

=over

=item C<< maybe $x => $y, @rest >>

This function checks that C<< $x >> and C<< $y >> are both defined. If they
are, it returns them both as a list; otherwise it returns the empty list.

If C<< @rest >> is provided, it is unconditionally appended to the end of
whatever list is returned.

The combination of these behaviours allows the following very sugary syntax
to "just work".

 my $bob = Person->new(
         name      => $name,
         address   => $addr,
   maybe phone     => $tel,
   maybe email     => $email,
         unique_id => $id,
 );

This function is exported by default.

=item C<< provided $condition, $x => $y, @rest >>

Like C<maybe> but allows you to use a custom condition expression:

 my $bob = Person->new(
                             name      => $name,
                             address   => $addr,
   provided length($tel),    phone     => $tel,
   provided $email =~ /\@/,  email     => $email,
                             unique_id => $id,
 );

This function is not exported by default.

=item C<< provided_deref $condition, $r, @rest >>

Like C<provided> but dereferences the second argument into list context:

 my $bob = Person->new(
                             name        => $name,
                             address     => $addr,
   provided length($tel),    phone       => $tel,
   provided $email =~ /\@/,  email       => $email,
   provided_deref $employee, sub {
                             employee_id => $employee->employee_id,
                       maybe department  => $employee->department,
                           },
                             unique_id   => $id,
 );

The second argument may be a HASH or ARRAY reference. It may also be a CODE
reference, which will be called in list context. If it is a blessed object,
it will be treated as if it were a HASH reference (internally it could be
another type of reference with overloading). A code reference can be used
if evaluation of the second argument should only occur if the condition is met
(e.g. to prevent method calls on an uninitialised value).

This function is not exported by default.

=item C<< provided_deref_with_maybe $condition, $r, @rest >>

Like C<provide_deref> but will perform C<maybe> on each key-value pair in
the dereferenced values.

 my $bob = Person->new(
                             name        => $name,
                             address     => $addr,
   provided length($tel),    phone       => $tel,
   provided $email =~ /\@/,  email       => $email,
   provided_deref_with_maybe $employee, $employee,
                             unique_id   => $id,
 );

Also, if the second argument is a blessed object, it will also skip any
'private' attributes (keys starting with an underscore).

It not only "just works", it "DWIM"s!

This function is not exported by default.

=item C<< PerlX::Maybe::IMPLEMENTATION >>

Indicates whether the XS backend L<PerlX::Maybe::XS> was loaded.

=back

=head2 XS Backend

If you install L<PerlX::Maybe::XS>, a faster XS-based implementation will
be used instead of the pure Perl functions. My basic benchmarking experiments
seem to show this to be around 30% faster.

Currently there are no XS implementations of the C<provided_deref> and
C<provided_deref_with_maybe> functions. Contributions welcome.

=head2 Environment

The environment variable C<PERLX_MAYBE_IMPLEMENTATION> may be set to
C<< "PP" >> to prevent the XS backend from loading.

=head2 Exporting

Only C<maybe> is exported by default. You can request other functions
by name:

  use PerlX::Maybe "maybe", "provided";

Or to export everything:

  use PerlX::Maybe ":all";

If L<Exporter::Tiny> is installed, you can rename imports:

  use PerlX::Maybe "maybe" => { -as => "perhaps" };

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=PerlX-Maybe>.

=head1 SEE ALSO

L<Syntax::Feature::Maybe>, L<PerlX::Maybe::XS>.

L<MooseX::UndefTolerant>, L<PerlX::Perform>, L<Exporter>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

C<provided_deref> and C<provided_deref_with_maybe> by Theo van Hoesel.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013, 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

