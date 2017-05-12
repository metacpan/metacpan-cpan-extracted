use 5.008;
use strict;
use warnings;

package Role::Commons::ObjectID;

BEGIN {
	use Moo::Role;
	$Role::Commons::ObjectID::AUTHORITY = 'cpan:TOBYINK';
	$Role::Commons::ObjectID::VERSION   = '0.104';
}

# deliberately load this *after* Moo::Role
use Object::ID qw( object_id );

our $setup_for_class = sub {
	my ($role, $package, %args) = @_;
};

1;

__END__

=head1 NAME

Role::Commons::Authority - an object method providing a unique identifier

=head1 SYNOPSIS

   use v5.14;
   
   package Person 1.0 {
      use Moo;
      use Role::Commons -all;
      has name => (is => 'ro');
   };
   
   my $bob1 = Person->new(name => "Bob");
   my $bob2 = Person->new(name => "Bob");
   
   say $bob1->object_id;  # an identifier
   say $bob2->object_id;  # a different identifier

=head1 DESCRIPTION

This is a tiny shim between L<Object::ID> and L<Role::Commons> (and hence
L<Moo::Role>/L<Moose::Role> too).

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Role-Commons>.

=head1 SEE ALSO

L<Role::Commons>,
L<Object::ID>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

