=head1 PURPOSE

Tests the output of the "-trace" feature.

Checks that the C<PERL_MOOX_STRUCT_TRACE> environment variable is honoured.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use if ($] < 5.010), 'Test::More', skip_all => 'need Perl 5.10';
use Test::More;

use 5.010;
use MooX::Struct ();
use IO::Handle;

my $default = "MooX::Struct::Processor"->new(trace => 1);
is($default->trace_handle, \*STDERR);

my $output;
open my $handle, '>', \$output;
my $proc = "MooX::Struct::Processor"->new(trace => 1, trace_handle => $handle);

$proc->process(
	__PACKAGE__,
	Something => ['$foo', announce_foo => sub { say shift->foo } ],
);
my $obj = new_ok Something(), [[1]];

is($output, <<"EXPECTED");
package @{[ Something() ]};
use Moo;
has foo => ('is' => 'ro','isa' => 'ScalarLike');
sub announce_foo { ... }
sub FIELDS { ... }
sub TYPE { ... }
EXPECTED

$output = '';

BEGIN {
	package Local::Role;
	use Moo::Role;
	requires 'foo';
};

$proc->flags->{deparse} = 1;
$proc->process(
	__PACKAGE__,
	SomethingElse => [
		-class       => \'Something::Else',
		-isa         => [Something()],
		-with        => ['Local::Role'],
		announce_foo => sub { my $self = shift; print $self->foo, "\n" },
		'+number', 'random',
	],
);

$obj = new_ok SomethingElse(), [[1]];

like($output, qr{package Something::Else});
like($output, qr{with qw.Local::Role.});
like($output, qr{print \$self->foo});
#like($output, qr{looks_like_number});

{
	local $ENV{PERL_MOOX_STRUCT_TRACE} = 1;
	ok "MooX::Struct::Processor"->new->trace;
}
ok not "MooX::Struct::Processor"->new->trace;

done_testing;
