use Test::More;
{ package Local::Dummy1; use Test::Requires 'Moo::Role' };
{ package Local::Dummy2; use Test::Requires 'Mouse::Role' };

{
	package ThisFailsRole;
	use Mouse::Role;
	use Sub::HandlesVia;
}

is( Sub::HandlesVia->_detect_framework('ThisFailsRole'), 'Mouse', 'role ok' );
done_testing;
