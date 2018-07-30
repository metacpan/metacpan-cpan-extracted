=pod

=encoding utf-8

=head1 PURPOSE

Test C<< has '+attr' => (default => ...) >> under Moose yields no warnings.

=head1 DEPENDENCIES

Test requires Moose or is skipped.

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Aaron Crane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Requires 'Moose';
use Test::More;

my @warnings;
local $^W = 1;
local $SIG{__WARN__} = sub { push @warnings, shift };

{
	package Local::Base;
	use Moose;
	use MooseX::MungeHas;
	has attr => (is => 'ro', required => 1);
}

{
	package Local::Derived;
	use Moose;
	use MooseX::MungeHas;
	extends 'Local::Base';
	has '+attr' => (default => 17);
}

is_deeply(\@warnings, [], 'no warnings issued')
	or diag explain(\@warnings);
done_testing;

