use Test::More tests => 5;

BEGIN {
    use_ok('Role::_Multiton');
    use_ok('Role::Multiton');
    use_ok('Role::Singleton');
    use_ok('Role::Multiton::New');
    use_ok('Role::Singleton::New');
}

diag("Testing Role::Multiton $Role::Multiton::VERSION");
