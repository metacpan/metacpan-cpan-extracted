=pod

=encoding utf-8

=head1 PURPOSE

Test the C<< -lazy >> option.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use lib "t/lib";
use lib "lib";

use strict;
use warnings;
use Test::More;

use Subclass::Of "Local::Perl::Class" => (
	-lazy,
	-methods => [
		xyz => sub { 42 },
	],
);

ok not 'Local::Perl::Class::__SUBCLASS__::0001'->can('foo');
ok not 'Local::Perl::Class::__SUBCLASS__::0001'->can('xyz');

is(Subclass::Of::_alias_to_package_name(\&Class), '(unknown package)');

# generates the class
is(Class, 'Local::Perl::Class::__SUBCLASS__::0001');

ok 'Local::Perl::Class::__SUBCLASS__::0001'->can('foo');
ok 'Local::Perl::Class::__SUBCLASS__::0001'->can('xyz');

is(Subclass::Of::_alias_to_package_name(\&Class), 'Local::Perl::Class::__SUBCLASS__::0001');

# memoized
is(Class, 'Local::Perl::Class::__SUBCLASS__::0001');

done_testing;

