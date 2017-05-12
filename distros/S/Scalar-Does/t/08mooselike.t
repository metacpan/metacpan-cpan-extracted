=head1 PURPOSE

Test Scalar::Does::MooseTypes.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Scalar::Does qw(does);
use Scalar::Does::MooseTypes -constants;

my $var = "Hello world";

ok does(\$var, ScalarRef);
ok does([], ArrayRef);
ok does(+{}, HashRef);
ok does(sub {0}, CodeRef);
ok does(\*STDOUT, GlobRef);
ok does(\(\"Hello"), Ref);
ok does(\*STDOUT, FileHandle);
ok does(qr{x}, RegexpRef);
ok does(1, Str);
ok does(1, Num);
ok does(1, Int);
ok does(1, Defined);
ok does(1, Value);
ok does(undef, Undef);
ok does(undef, Item);
ok does(undef, Any);
ok does('Scalar::Does', ClassName);
ok does('Scalar::Does', RoleName);

ok does(undef, Bool);
ok does('', Bool);
ok does(0, Bool);
ok does(1, Bool);
ok !does(7, Bool);
ok does(\(\"Hello"), ScalarRef);

ok !does([], Str);
ok !does([], Num);
ok !does([], Int);
ok  does("4x4", Str);
ok !does("4x4", Num);
ok !does("4.2", Int);

ok !does(undef, Str);
ok !does(undef, Num);
ok !does(undef, Int);
ok !does(undef, Defined);
ok !does(undef, Value);

{
	package Local::Class1;
	use strict;
}

{
	no warnings 'once';
	$Local::Class2::VERSION = 0.001;
	@Local::Class3::ISA     = qw(UNIVERSAL);
	@Local::Dummy1::FOO     = qw(UNIVERSAL);
}

{
	package Local::Class4;
	sub XYZ () { 1 }
}

ok !does(undef, ClassName);
ok !does([], ClassName);
ok  does("Local::Class$_", ClassName) for 2..4;
ok !does("Local::Dummy1", ClassName);

done_testing;
