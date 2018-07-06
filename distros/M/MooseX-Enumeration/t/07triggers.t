=pod

=encoding utf-8

=head1 PURPOSE

Test that MooX::Enumeration works with triggers.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008001;
use strict;
use warnings;
use Test::More tests => 5;

my $var = 0;

{
	package Local::Test;
	use Moose;
	
	has status => (
		traits  => ['Enumeration'],
		is      => 'ro',
		enum    => [qw/ foo bar baz /],
		builder => '_build_status',
		lazy    => !!1,
		handles => {
			is_foo            => [ is => "foo" ],
			is_bar            => [ is => "bar" ],
			is_baz            => [ is => "baz" ],
			assign_bar_if_foo => [ assign => "bar", "foo" ],
		},
		trigger => sub { ++$var },
	);
	
	sub _build_status { "foo" }
};

ok( Local::Test->new->is_foo, "lazy defaults work with is, 1");
ok(!Local::Test->new->is_bar, "lazy defaults work with is, 2");
ok(!Local::Test->new->is_baz, "lazy defaults work with is, 3");

#require B::Deparse;
#::diag(
#	B::Deparse->new->coderef2text( Local::Test->can('assign_bar_if_foo') )
#);

ok(Local::Test->new->assign_bar_if_foo->is_bar, "lazy defaults work with assign");

is($var, 1, "trigger worked");  # trigger

