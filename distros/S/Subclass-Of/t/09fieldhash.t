=pod

=encoding utf-8

=head1 PURPOSE

Test inside-out attributes in subclasses.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use lib "t/lib";
use lib "lib";

use strict;
use warnings;
use Test::More;

use Subclass::Of "Local::Perl::Class",
	-as => "MyClass",
	-has => [
		counter => [ is => 'rw', fieldhash => 1 ],
	];

my $obj = MyClass->new;
$obj->counter(999);
ok not exists $obj->{counter};
is $obj->counter, 999;

done_testing;

