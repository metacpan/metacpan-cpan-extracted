use 5.008003;
use strict;
use warnings;

package Sub::Trigger::Lock;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Scope::Guard qw( guard );
use Exporter::Tiny qw( );

our @ISA = qw(Exporter::Tiny);
our %EXPORT_TAGS = (
	all      => [qw( Lock RO lock unlock )],
	default  => [qw( Lock )],
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} };
our @EXPORT    = @{ $EXPORT_TAGS{default} };

sub _lock {
	
	if ( ref($_[1]) eq 'ARRAY' ) {
		&Internals::SvREADONLY( $_[1], 1 );
		&Internals::SvREADONLY( \$_, 1 ) for @{$_[1]};
		return;
	}
	
	if ( ref($_[1]) eq 'HASH' ) {
		&Internals::hv_clear_placeholders($_[1]);
		&Internals::SvREADONLY( $_[1], 1 );
		&Internals::SvREADONLY( \$_, 1 ) for values %{$_[1]};
		return;
	}
	
	return;
}

sub Lock () {
	\&_lock;
}

sub RO () {
	'ro', 'trigger', Lock;
}

sub lock ($) {
	_lock(undef, @_);
}

sub unlock ($) {
	my $ref = shift;
	
	if ( ref($ref) eq 'ARRAY' ) {
		&Internals::SvREADONLY( $ref, 0 );
		&Internals::SvREADONLY( \$_, 0 ) for @$ref;
	}
	
	if ( ref($_[1]) eq 'HASH' ) {
		&Internals::hv_clear_placeholders($ref);
		&Internals::SvREADONLY( $ref, 0 );
		&Internals::SvREADONLY( \$_, 0 ) for values %$ref;
	}
	
	return guard { _lock(undef, $ref) };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::Trigger::Lock - a coderef for use in Moose triggers that will lock hashrefs and arrayrefs

=head1 SYNOPSIS

This module provides the antidote for:

   package Foo {
      use Moose;
      
      has bar => (is => 'ro', isa => 'ArrayRef');
   }
   
   my $foo = Foo->new( bar => [1,2,3] );
   push @{ $foo->bar }, 4;   # does not die!

All you need to do is:

   package Foo {
      use Moose;
      use Sub::Trigger::Lock;
      
      has bar => (is => 'ro', isa => 'ArrayRef', trigger => Lock);
   }

Or, a shortcut:

   package Foo {
      use Moose;
      use Sub::Trigger::Lock qw(RO);
      
      has bar => (is => RO, isa => 'ArrayRef');
   }

=head1 TL;DR

Force modifications of your arrayref/hashref attributes to be made via
your documented API.

=head1 DESCRIPTION

This module provides two constants, C<Lock> and C<RO>. The first of
these is the only one exported by default, and the key to understanding
this module. This module also provides the utility functions C<lock>
and C<unlock>, which are not exported by default.

=over

=item C<< Lock >>

C<Lock> is a constant which evaluates to a coderef. The coderef takes
two or more arguments. That is, C<Lock> itself takes no arguments; it
returns a coderef that takes arguments!

The first argument is supposed to be a blessed object, but it is
actually completely ignored.

If the second argument is not a hashref or arrayref, it is also
ignored. Everything is ignored! But if the second argument I<is>
a hashref or arrayref, it will be flagged as read-only.

This is a fairly shallow read-only flag. Attempts to add or remove
keys from the hash, or change the value for any key will throw an
exception. But if the value is reference to some other structure, that
structure will be unaffected.

Similarly, attempts to push, pop, shift, or unshift a read-only array,
or to change the value for any index will throw an exception. Buf if
the values are references to other structures, these will also be
unaffected.

Overall, the effect of C<Lock> is that you can do something like this:

   package Person {
      use Moose;
      
      has name => (is => 'ro', writer => 'set_name');
   }
   
   package Band {
      use Moose;
      use Sub::Trigger::Lock;
      
      has members => (is => 'ro', trigger => Lock);
   }
   
   my $spice_girls = Band->new(
      members => [
         Person->new(name => 'Victoria Adams'),
         Person->new(name => 'Melanie Brown'),
         Person->new(name => 'Emma Bunton'),
         Person->new(name => 'Melanie Chisholm'),
         Person->new(name => 'Geri Halliwell'),
      ],
   );
   
   # This is OK, because deep changes work
   $spice_girls->members->[0]->set_name('Victoria Beckham');
   
   # This is not OK, because shallow changes throw!
   $spice_girls->members->[0] = Person->new(name => 'Johnny Cash');

=item C<< RO >>

C<RO> is a constant that evaluates to the list:

   'ro', 'trigger', Lock,

=item C<< lock($ref) >>

A utility function for locking an arrayref or hashref in the same way
that the C<Lock> coderef would.

=item C<< unlock($ref) >>

A utility function for unlocking an arrayref or hashref.

Note that this returns a I<< guard object >>. You should store this
object in a variable. Once the object is destroyed (e.g. because the
variable has gone out of scope), C<< $ref >> will be automatically
locked again!

This allows you to temporarily unlock a hashref or arrayref in order
to privately manipulate it:

   package Band {
      use Moose;
      use Sub::Trigger::Lock qw( Lock unlock );
      
      has members => (is => 'ro', trigger => Lock);
      
      sub add_members {
         my ($self, @members) = @_;
         my $guard = unlock( $self->members );
         push @{$self->members}, @members;
      }
   }

=back

=head1 IMPLEMENTATION NOTES

This module uses the Perl internal C<< Internals::SvREADONLY >>
function for most of the heavy lifting. This is much, much faster
than ties.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sub-Trigger-Lock>.

=head1 SEE ALSO

L<Exporter::Tiny>, L<Scope::Guard>.

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

