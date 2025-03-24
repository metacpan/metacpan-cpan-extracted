use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Declare;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.050001';

use Sub::HandlesVia ();

my %cache;

sub import {
	my ( $class, $attr ) = ( shift, shift );
	my ( $via, %delegations ) = ( @_ % 2 ) ? @_ : ( undef, @_ );
	
	if ( not defined $via ) {
		$via = 'Array' if $attr =~ /^@/;
		$via = 'Hash'  if $attr =~ /^%/;
		if ( not defined $via ) {
			require Sub::HandlesVia::Mite;
			Sub::HandlesVia::Mite::croak(
				'Expected usage: '.
				'use Sub::HandlesVia::Declare ( $attr, $via, %delegations );'
			);
		}
	}
	
	my $caller = caller;
	if ( not $cache{$caller} ) {
		'Sub::HandlesVia'->import(
			{
				into      => $caller,
				installer => sub { $cache{$caller} = $_[1][1] },
			},
			qw( delegations ),
		);
	}
	
	$cache{$caller}->(
		attribute    => $attr,
		handles_via  => $via,
		handles      => \%delegations,
	);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::HandlesVia::Declare - declare delegations at compile-time

=head1 SYNOPSIS

 use Sub::HandlesVia::Declare( $attr, $via => %delegations );

This is roughly equivalent to the following:

 use Sub::HandlesVia qw(delegations);
 
 BEGIN {
   delegations(
     attribute    => $attr,
     handles_via  => $via,
     handles      => \%delegations,
   );
 };

Except it doesn't import the C<delegations> function into your namespace.

=head1 DESCRIPTION

Useful for L<Object::Pad> and kind of nice for L<Class::Tiny>. Basically
any class builder than does its stuff at compile time.

=head2 Object::Pad

 use Object::Pad;
 
 class Kitchen {
   has @foods;
   use Sub::HandlesVia::Declare '@foods', Array => (
     all_foods => 'all',
     add_food  => 'push',
   );
 }

If an attribute begins with a '@' or '%', C<< $via >> can be omitted.

 use Object::Pad;
 
 class Kitchen {
   has @foods;
   use Sub::HandlesVia::Declare '@foods', (
     all_foods => 'all',
     add_food  => 'push',
   );
 }

=head2 Class::Tiny

 package Kitchen;
 use Class::Tiny {
   foods  => sub { [] },
   drinks => sub { [ 'water' ] },
 };
 use Sub::HandlesVia::Declare 'foods', Array => (
   all_foods  => 'all',
   add_food   => 'push',
 );
 use Sub::HandlesVia::Declare 'drinks', Array => (
   all_drinks => 'all',
   add_drink  => 'push',
 );

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-sub-handlesvia/issues>.

=head1 SEE ALSO

L<Sub::HandlesVia>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

