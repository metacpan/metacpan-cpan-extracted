use Test::More; 
use Test::DBIx::Class {
    schema_class => 'OpusVL::AppKit::Schema::AppKitAuthDB',
}, 'Role', 'RoleAllowed', 'User';
ok my $u = User->create({ username => 'test', password => 'blah', email => 'test@opusvl.com', name => 'Test', tel => '32312'});
done_testing;

