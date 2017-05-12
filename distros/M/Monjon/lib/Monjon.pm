use 5.006;
use strict;
use warnings;

use Carp ();
use Moo ();
use Moo::Role ();
use Import::Into ();

package Monjon;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';
our @ISA       = qw( Moo );

do { require UNIVERSAL::DOES }
	if $] < 5.010000;

sub import {
	my $class = shift;
	my $caller = caller;
	
	'Moo'->import::into($caller, @_);
	
	'Moo::Role'->apply_roles_to_object(
		'Moo'->_accessor_maker_for($caller),
		'Method::Generate::Accessor::Role::Monjon',
	);
	
	'Moo::Role'->apply_roles_to_object(
		'Moo'->_constructor_maker_for($caller),
		'Method::Generate::Constructor::Role::Monjon',
	);
	
	$caller->Class::Method::Modifiers::install_modifier(
		before => 'has',
		sub {
			$Monjon::INSTANCES_EXIST{$caller}
				and Carp::croak("$caller has already been instantiated; cannot add attributes");
		},
	);
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=for stopwords monjon monjons booleans

=head1 NAME

Monjon - create your Moo objects as blessed scalar refs

=head1 SYNOPSIS

	use v5.14;
	
	package MyClass {
		use Monjon;
		has id   => (is => 'ro', pack => 'L');
		has name => (is => 'rw', pack => 'Z32');
	}
	
	my $obj = MyClass->new(id => 42, name => "The Answer");

=head1 DESCRIPTION

=begin html

<p
	id="#eating-marmoset-ii"
	style="float:right">
	<img
		alt=""
		src="http://buzzword.org.uk/2014/pburbidgei1.jpg"
		width="180" height="118" style="border:1px solid black">
</p>

=end html

Monjon is a subclass of L<Moo> designed for efficient memory usage when
you need to deal with many thousands of very simple objects.

Attributes are stored using a variation on the C<pack>/C<unpack>
technique used by L<BrowserUK|http://www.perlmonks.org/?node_id=171588>
on PerlMonks at L<http://www.perlmonks.org/?node_id=1040313>.

However, inside-out attributes are also offered for data which cannot
be reasonably serialized to a string. (But if you do need to store
things like references, perhaps Monjon is not for you.)

=head2 Differences from Moo

=over

=item C<has>

The attribute spec accepts an additional option C<pack>. The presence
of this key in the specification makes your attribute be stored in the
object's packed string. Attributes without a C<pack> option will be
stored inside-out.

=item C<extends>

Extending non-Monjon classes is not supported. (But who knows? It could
work!)

=item C<before>, C<after>, and C<around>

Monjon is sometimes forced to rebuild constructors and accessors at
run-time, which may lead to method modifiers being overwritten, if you
have tried to apply any modifiers to them.

Basically, don't apply method modifiers to accessors.

=back

=head2 Benchmarking

Monjon's accessors are significantly slower than Moo's, especially when
Moo is able to make use of L<Class::XSAccessor>.

However, if your data consists of mostly numbers, booleans, and small
or fixed-width strings, Monjon is likely to consume a lot less memory
per instance.

See:
L<https://github.com/tobyink/p5-monjon/blob/master/devel.bench/bench.pl>.

=head2 What's a Monjon?

It's a very shy little wallaby, and it's near-threatened. See
L<http://en.wikipedia.org/wiki/Monjon>.

If you like this module and want to help monjons, please see
L<http://www.australianwildlife.org.au/Artesian-Range.aspx>.

=head1 CAVEATS

Unless you have Moo 1.004_003 exactly (i.e. neither an older nor a
newer version of Moo), multiple inheritance is unlikely to work for
Monjon classes.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Monjon>.

=head1 SEE ALSO

L<Moo>.

L<http://www.perlmonks.org/?node_id=1040313>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

