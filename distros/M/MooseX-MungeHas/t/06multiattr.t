=pod

=encoding utf-8

=head1 PURPOSE

Test that C<< has \@attrs => %spec >> works.

=head1 DEPENDENCIES

Test requires Moose 2.0000 or is skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Requires { "Moose" => "2.0000" };
use Test::More;

{
	package Local::Class1;
	use Moose;
	use MooseX::MungeHas qw(is_ro);
	has [qw/ one two /] => sub { "xyz" };
}

my $obj = Local::Class1::->new;
is($obj->one, 'xyz');
is($obj->two, 'xyz');
done_testing;
