=head1 PURPOSE

Checks some places where MooX::Struct::Processor is expected to fail.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use MooX::Struct ();

ok not eval {
	"MooX::Struct::Processor"->new(flags => 1);
};

ok not eval {
	"MooX::Struct::Processor"->new(class_map => 1);
};

ok not eval {
	"MooX::Struct::Processor"->new->process(
		__PACKAGE__,
		Foo => [ -monkey => ['Albert'] ],
	);
	Foo();
};
like($@, qr{option '-monkey' unknown});

done_testing;
