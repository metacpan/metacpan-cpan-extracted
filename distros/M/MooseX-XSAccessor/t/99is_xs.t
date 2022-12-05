=pod

=encoding utf-8

=head1 PURPOSE

Test different ways of calling C<< MooseX::XSAccessor::is_xs() >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;

{
	package Local::Class;
	use Moose;
	BEGIN { eval "use MooseX::XSAccessor" };
	has my_num => (is => "ro", isa => "Int");
	__PACKAGE__->meta->make_immutable;
}

ok MooseX::XSAccessor::is_xs( Local::Class->meta->get_method("my_num") );
ok MooseX::XSAccessor::is_xs( \&Local::Class::my_num );
ok MooseX::XSAccessor::is_xs( "Local::Class::my_num" );

done_testing;
