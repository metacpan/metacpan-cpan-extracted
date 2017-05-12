package MooseX::Does::Delegated;

use 5.008;
use strict;
use warnings;
use if $] < 5.010, 'UNIVERSAL::DOES';

BEGIN {
	$MooseX::Does::Delegated::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::Does::Delegated::VERSION   = '0.004';
}

use Moose::Role;

around DOES => sub {
	my ($orig, $self, $role) = @_;
	return 1 if $self->$orig($role);
	return unless blessed($self);
	for my $attr ($self->meta->get_all_attributes) {
		next unless $attr->has_handles;
		my $handles = $attr->handles;
		next if ref $handles;
		next unless $attr->has_value($self) || $attr->is_lazy;
		return 1 if $role eq $handles;
		return 1 if Class::MOP::class_of($handles)->does_role($role);
	}
	return;
};

# Allow import method to work, yet hide it from role method list.
our @ISA = do {
	package # Hide from CPAN indexer too.
	MooseX::Does::Delegated::__ANON__::0001;
	use Moose::Util qw(ensure_all_roles);
	sub import {
		no warnings qw(uninitialized);
		my $class = shift;
		ensure_all_roles('Moose::Object', $class)
			if $_[0] =~ /^[-](?:everywhere|rafl)/;
	}
	__PACKAGE__;
};

no Moose::Role;

__PACKAGE__
__END__

=head1 NAME

MooseX::Does::Delegated - allow your class's DOES method to respond the affirmative to delegated roles

=head1 SYNOPSIS

   use strict;
   use Test::More;
   
   {
      package HttpGet;
      use Moose::Role;
      requires 'get';
   };
   
   {
      package UserAgent;
      use Moose;
      with qw( HttpGet );
      sub get { ... };
   };
   
   {
      package Spider;
      use Moose;
      has ua => (
         is         => 'ro',
         does       => 'HttpGet',
         handles    => 'HttpGet',
         lazy_build => 1,
      );
      sub _build_ua { UserAgent->new };
   };
   
   my $woolly = Spider->new;
   
   # Note that the default Moose implementation of DOES
   # ignores the fact that Spider has delegated the HttpGet
   # role to its "ua" attribute.
   #
   ok(     $woolly->DOES('Spider') );
   ok( not $woolly->DOES('HttpGet') );
   
   Moose::Util::apply_all_roles(
      'Spider',
      'MooseX::Does::Delegated',
   );
   
   # Our reimplemented DOES pays attention to delegated roles.
   #
   ok( $woolly->DOES('Spider') );
   ok( $woolly->DOES('HttpGet') );
   
   done_testing;

=head1 DESCRIPTION

According to L<UNIVERSAL> the point of C<DOES> is that it allows you
to check whether an object does a role without caring about I<how>
it does the role.

However, the default Moose implementation of C<DOES> (which you can
of course override!) only checks whether the object does the role via
inheritance or the application of a role to a class.

This module overrides your object's C<DOES> method, allowing it to
respond the affirmative to delegated roles. This module is a standard
Moose role, so it can be used like this:

   with qw( MooseX::Does::Delegated );

Alternatively, if you wish to apply this role ubiqitously (i.e. to all
Moose objects in your application) - as is your prerogative - you can use:

   use MooseX::Does::Delegated -everywhere;

This will apply the role to the Moose::Object base class.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Does-Delegated>.

=head1 SEE ALSO

L<Moose::Manual::Delegation>.

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

