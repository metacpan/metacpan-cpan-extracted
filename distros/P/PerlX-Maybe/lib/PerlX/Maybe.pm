use 5.006;
use strict;
use warnings;

package PerlX::Maybe;

BEGIN {
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '1.001';
	
	require Exporter;
	our @ISA         = qw/ Exporter /;
	our @EXPORT      = qw/ maybe /;
	our @EXPORT_OK   = qw/ maybe provided /;
	our %EXPORT_TAGS = (all => \@EXPORT_OK, default => \@EXPORT);
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

=item C<< PerlX::Maybe::IMPLEMENTATION >>

Indicates whether the XS backend L<PerlX::Maybe::XS> was loaded.

=back

=head2 XS Backend

If you install L<PerlX::Maybe::XS>, a faster XS-based implementation will
be used instead of the pure Perl functions. My basic benchmarking experiments
seem to show this to be around 30% faster.

=head2 Environment

The environment variable C<PERLX_MAYBE_IMPLEMENTATION> may be set to
C<< "PP" >> to prevent the XS backend from loading.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=PerlX-Maybe>.

=head1 SEE ALSO

L<Syntax::Feature::Maybe>, L<PerlX::Maybe::XS>.

L<MooseX::UndefTolerant>, L<PerlX::Perform>, L<Exporter>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

