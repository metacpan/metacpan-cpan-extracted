=head1 PURPOSE

Check that usage of L<MooX::CaptainHook> does not automatically load
L<Moose> or L<Class::MOP>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 1;

{
	package Local::Role;
	use Moo::Role;
	use MooX::CaptainHook qw( on_application on_inflation is_role );
	
	on_application { 1 };
	on_inflation { 1 };
	
	is_role(__PACKAGE__);
}

{
	package Local::Class;
	use Moo; with 'Local::Role';
	use MooX::CaptainHook qw( on_application on_inflation is_role );
	
	on_application { 1 };
	on_inflation { 1 };
	
	is_role(__PACKAGE__);
}

ok not $INC{'Class/MOP.pm'};
