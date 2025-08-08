use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
my $tmp = File::Temp->newdir;

use Sys::Export::Unix::UserDB;
use File::Spec::Functions qw(catfile catdir);

subtest 'constructor and attributes' => sub {
   my $db = Sys::Export::Unix::UserDB->new;
   isa_ok($db, 'Sys::Export::Unix::UserDB');
   
   is(ref $db->users, 'HASH', 'users is a hashref');
   is(ref $db->uids, 'HASH', 'uids is a hashref');
   is(ref $db->groups, 'HASH', 'groups is a hashref');
   is(ref $db->gids, 'HASH', 'gids is a hashref');
   
   # Test constructor with initial values
   my $db2 = Sys::Export::Unix::UserDB->new(
      users => { test => { uid => 1, group => 'test' } },
      groups => { test => { gid => 2 } },
   );
   is($db2->users->{test}, object { call uid => 1; }, 'constructor accepts initial users');
   is($db2->groups->{test}, object { call gid => 2; }, 'constructor accepts initial groups');
   
   # Test invalid attribute rejection
   like(dies { Sys::Export::Unix::UserDB->new(invalid => 'value') }, 
       qr/Unknown /, 'rejects unknown attributes');
};

subtest 'user object creation and methods' => sub {
   my $user = Sys::Export::Unix::UserDB::User->new(
      name => 'testuser',
      uid => 1001,
      group => 'testuser',
      passwd => 'x',
      gecos => 'Test User',
      dir => '/home/testuser',
      shell => '/bin/bash',
      groups => ['wheel', 'users']
   );
   
   isa_ok($user, 'Sys::Export::Unix::UserDB::User');
   is($user->name, 'testuser', 'name accessor works');
   is($user->uid, 1001, 'uid accessor works');
   is($user->group, 'testuser', 'gid accessor works');
   is($user->passwd, 'x', 'passwd accessor works');
   is($user->gecos, 'Test User', 'gecos accessor works');
   is($user->dir, '/home/testuser', 'home accessor works');
   is($user->shell, '/bin/bash', 'shell accessor works');
   is($user->groups, { wheel => 1, users => 1 }, 'groups accessor works');
   
   # Test writable attributes
   $user->passwd('newpass');
   is($user->passwd, 'newpass', 'passwd is writable');
   
   $user->gecos('New GECOS');
   is($user->gecos, 'New GECOS', 'gecos is writable');
   
   # Test group management
   $user->add_group('admin');
   is($user->groups, { wheel => 1, users => 1, admin => 1 }, 'add_group works');
   
   $user->add_group('wheel');  # duplicate
   is($user->groups, { wheel => 1, users => 1, admin => 1 }, 'add_group ignores duplicates');
   
   $user->remove_group('users');
   is($user->groups, { wheel => 1, admin => 1 }, 'remove_group works');
   
   # Test clone
   my $cloned = $user->clone;
   isa_ok($cloned, 'Sys::Export::Unix::UserDB::User');
   is($cloned->name, 'testuser', 'clone preserves name');
   is($cloned->groups, { wheel => 1, admin => 1 }, 'clone preserves groups');
   
   # Verify it's a deep clone
   $cloned->add_group('test');
   isnt($user->groups, $cloned->groups, 'clone is deep copy');
   
   # Test required fields
   like(dies { Sys::Export::Unix::UserDB::User->new(uid => 1001, group => 'testuser') },
       qr/User 'name' is required/, 'name is required');
   like(dies { Sys::Export::Unix::UserDB::User->new(name => 'test', group => 'testuser') },
       qr/User 'uid' is required/, 'uid is required');
   like(dies { Sys::Export::Unix::UserDB::User->new(name => 'test', uid => 1001) },
       qr/User primary 'group' is required/, 'group is required');
};

subtest 'group object creation and methods' => sub {
   my $group = Sys::Export::Unix::UserDB::Group->new(
      name => 'testgroup',
      gid => 1001,
      passwd => 'x'
   );
   
   isa_ok($group, 'Sys::Export::Unix::UserDB::Group');
   is($group->name, 'testgroup', 'name accessor works');
   is($group->gid, 1001, 'gid accessor works');
   is($group->passwd, 'x', 'passwd accessor works');
   
   # Test writable attributes
   $group->passwd('newpass');
   is($group->passwd, 'newpass', 'passwd is writable');
   
   # Test clone
   my $cloned = $group->clone;
   isa_ok($cloned, 'Sys::Export::Unix::UserDB::Group');
   is($cloned->name, 'testgroup', 'clone preserves name');
   is($cloned->gid, 1001, 'clone preserves gid');
   
   # Test required fields
   like(dies { Sys::Export::Unix::UserDB::Group->new(gid => 1001) },
       qr/Group 'name' is required/, 'name is required');
   like(dies { Sys::Export::Unix::UserDB::Group->new(name => 'test') },
       qr/Group 'gid' is required/, 'gid is required');
};

subtest 'add_user and add_group methods' => sub {
   my $db = Sys::Export::Unix::UserDB->new;
   
   # Test add_group with name
   $db->add_group('testgroup', gid => 1001);
   ok($db->group('testgroup'), 'group was added');
   is($db->groups->{testgroup}->gid, 1001, 'group has correct gid');
   
   # Test add_user with name
   $db->add_user('testuser', uid => 1001, group => 'testgroup');
   ok($db->user('testuser'), 'user was added');
   is($db->users->{testuser}->uid, 1001, 'user has correct uid');
   is($db->users->{testuser}->groups, {}, 'user starts with empty groups');
   
   # Test add_user with user object
   $db->add_user($db->user('testuser'), name => 'cloneuser', uid => 1002);
   ok($db->user('cloneuser'), 'user object was cloned and added');
   is($db->users->{cloneuser}->uid, 1002, 'cloned user has correct uid');
   
   # Test add_group with group object
   $db->add_group($db->group('testgroup'), name => 'clonegroup', gid => 1003);
   ok($db->group('clonegroup'), 'group object was cloned and added');
   is($db->groups->{clonegroup}->gid, 1003, 'cloned group has correct gid');
};

subtest 'conflict detection' => sub {
   my $db = Sys::Export::Unix::UserDB->new;
   
   # Add initial user and group
   $db->add_group('group1', gid => 1001);
   $db->add_user('user1', uid => 1001, group => 'group1');
   
   # Test name conflict error
   like(dies { $db->add_user('user1', uid => 1002, group => 'group1') },
       qr/Username 'user1' already exists/, 'name conflict detected');
   
   like(dies { $db->add_group('group1', gid => 1002) },
       qr/Group name 'group1' already exists/, 'group name conflict detected');
   
   # Test UID/GID conflict warning
   like(warning { $db->add_user('user2', uid => 1001, group => 'group1') },
       qr/UID 1001 already exists/, 'UID conflict warning');
   
   like(warning { $db->add_group('group2', gid => 1001) },
       qr/GID 1001 already exists/, 'GID conflict warning');
};

subtest 'existence checking methods' => sub {
   my $db = Sys::Export::Unix::UserDB->new;
   
   $db->add_group('testgroup', gid => 1002);
   $db->add_user('testuser', uid => 1001, group => 'testgroup');
   
   ok($db->user('testuser'), 'user returns true for existing user');
   ok(!$db->user('nonexistent'), 'user returns false for non-existing user');
   ok($db->has_user('testuser'), 'has_user returns true for existing user');
   ok(!$db->has_user('nonexistent'), 'has_user returns false for non-existing user');
   
   ok($db->group('testgroup'), 'group returns true for existing group');
   ok(!$db->group('nonexistent'), 'group returns false for non-existing group');
   ok($db->has_group('testgroup'), 'has_group returns true for existing group');
   ok(!$db->has_group('nonexistent'), 'has_group returns false for non-existing group');
   
   ok($db->user(1001), 'user returns true for existing uid');
   ok(!$db->user(9999), 'user returns false for non-existing uid');
   ok($db->has_user(1001), 'has_user returns true for existing uid');
   ok(!$db->has_user(9999), 'has_user returns false for non-existing uid');
   
   ok($db->group(1002), 'group returns true for existing gid');
   ok(!$db->group(9999), 'group returns false for non-existing gid');
   ok($db->has_group(1002), 'has_group returns true for existing gid');
   ok(!$db->has_group(9999), 'has_group returns false for non-existing gid');
};

subtest 'clone method' => sub {
   my $db = Sys::Export::Unix::UserDB->new;
   
   $db->add_group('testgroup', gid => 1001);
   $db->add_user('testuser', uid => 1001, group => 'testgroup');
   $db->users->{testuser}->add_group('testgroup');
   
   my $cloned = $db->clone;
   isa_ok($cloned, 'Sys::Export::Unix::UserDB');
   
   # Verify it's a deep clone
   ok($cloned->user('testuser'), 'cloned db has user');
   ok($cloned->group('testgroup'), 'cloned db has group');
   is($cloned->users->{testuser}->groups, { testgroup => 1 }, 'cloned user has groups');
   
   # Modify original and verify clone is unchanged
   $db->add_user('newuser', uid => 1002, group => 'testgroup');
   ok($db->user('newuser'), 'original has new user');
   ok(!$cloned->user('newuser'), 'clone does not have new user');
};

subtest 'load from files' => sub {
   my $test_dir = catdir($tmp, 'test_etc');
   mkdir $test_dir;
   
   # Create test passwd file
   mkfile(catfile($test_dir, 'passwd'), <<~'END');
      root:x:0:0:root:/root:/bin/bash
      daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
      testuser:x:1001:1001:Test User:/home/testuser:/bin/bash
      alice:x:1002:1002:Alice:/home/alice:/bin/bash
      END
   
   # Create test group file
   mkfile(catfile($test_dir, 'group'), <<~'END');
      root:x:0:
      daemon:x:1:
      testgroup:x:1001:testuser,alice
      wheel:x:1002:alice
      END
   
   # Create test shadow file
   mkfile(catfile($test_dir, 'shadow'), <<~'END');
      root:!:19000:0:99999:7:::
      testuser:$6$salt$hash:19000:0:99999:7:::
      END
   
   my $db = Sys::Export::Unix::UserDB->new(load => $test_dir);
   
   # Verify users loaded
   is(
      $db->users,
      {  root => object {
            call uid => 0;
            call group => 'root';
            call passwd => '!';
         },
         daemon => object {
            call uid => 1;
            call group => 'daemon';
            call passwd => undef;
         },
         testuser => object {
            call uid => 1001;
            call group => 'testgroup';
            call groups => { testgroup => 1 };
            call dir => '/home/testuser';
            call shell => '/bin/bash';
            call passwd => '$6$salt$hash';
            call pw_change_time => 19000 * 86400;
         },
         alice => object {
            call uid => 1002;
            call group => 'wheel';
            call groups => { testgroup => 1, wheel => 1 };
            call passwd => undef;
         },
      },
      'users loaded'
   );
   is(
      $db->groups,
      {  root      => object { call gid => 0; },
         daemon    => object { call gid => 1; },
         testgroup => object { call gid => 1001; },
         wheel     => object { call gid => 1002; },
      },
      'groups loaded'
   );
   
   # Test loading non-existent directory
   like(dies { $db->load('/nonexistent') }, qr/not found/, 'dies on missing files');
};

subtest 'save to files' => sub {
   my $db = Sys::Export::Unix::UserDB->new;
   
   # Add test data
   $db->add_group('testgroup', gid => 1001);
   $db->add_group('wheel', gid => 1002);
   $db->add_user('testuser', uid => 1001, group => 'testgroup', gecos => 'Test User', 
              dir => '/home/testuser', shell => '/bin/bash');
   $db->add_user('alice', uid => 1002, group => 'wheel', gecos => 'Alice', 
              dir => '/home/alice', shell => '/bin/bash');
   
   # Add group memberships
   $db->users->{testuser}->add_group('testgroup');
   $db->users->{alice}->add_group('testgroup');
   $db->users->{alice}->add_group('wheel');
   
   # Add shadow data
   $db->users->{testuser}->pw_change_time(19000 * 86400);
   $db->users->{testuser}->passwd('$6$salt$hash');
   
   # Test saving to hashref
   my %files;
   $db->save(\%files);
   
   like($files{passwd}, qr/testuser:x:1001:1001:Test User:\/home\/testuser:\/bin\/bash/, 
       'passwd file contains testuser');
   like($files{group}, qr/testgroup:.*:1001:alice/,
       'group file contains membership');
   like($files{shadow}, qr/testuser:\$6\$salt\$hash:19000/, 
       'shadow file contains testuser');
   
   # Test saving to directory
   my $save_dir = catdir($tmp, 'save_test');
   mkdir $save_dir;
   $db->save($save_dir);
   
   ok(-f catfile($save_dir, 'passwd'), 'passwd file created');
   ok(-f catfile($save_dir, 'group'), 'group file created');
   ok(-f catfile($save_dir, 'shadow'), 'shadow file created');
   
   my $saved_passwd = slurp(catfile($save_dir, 'passwd'));
   like($saved_passwd, qr/testuser:x:1001:1001/, 'saved passwd contains testuser');
   
   my $saved_group = slurp(catfile($save_dir, 'group'));
   like($saved_group, qr/testgroup:.*?:1001:alice/, 'saved group contains membership');
};

subtest 'roundtrip load and save' => sub {
   # Create original test data
   my $orig_dir = catdir($tmp, 'orig');
   mkdir $orig_dir;
   
   my $passwd_data = <<~'END';
      root:*:0:0:root:/root:/bin/bash
      testuser:x:1001:1001:Test User:/home/testuser:/bin/bash
      alice:x:1002:1002:Alice:/home/alice:/bin/bash
      END
   mkfile(catfile($orig_dir, 'passwd'), $passwd_data);
   
   my $group_data = <<~'END';
      root:*:0:
      wheel:*:10:alice
      users:*:100:alice,testuser
      testuser:*:1001:
      alice:*:1002:
      END
   mkfile(catfile($orig_dir, 'group'), $group_data);
   
   my $shadow_data = <<~'END';
      testuser:$6$salt$hash:19000:0:99999:7:::
      alice:!:19001::::::
      END
   mkfile(catfile($orig_dir, 'shadow'), $shadow_data);
   
   # Load, then save
   my $db = Sys::Export::Unix::UserDB->new;
   $db->load($orig_dir);
   
   my $save_dir = catdir($tmp, 'roundtrip');
   mkdir $save_dir;
   $db->save($save_dir);
   
   is( slurp(catfile($save_dir, 'passwd')), $passwd_data, 'passwd' );
   is( slurp(catfile($save_dir, 'group')),  $group_data,  'group' );
   is( slurp(catfile($save_dir, 'shadow')), $shadow_data, 'shadow' );
};

subtest 'auto import from host' => sub {
   my ($user0, $group0);
   # presume every host has a 'root' user and group
   # This always throws an exception on Win32 "The getpwman function is unimplemented"
   unless (eval {
      $user0= getpwuid 0;
      $group0= getgrgid 0;
      0 == (getpwnam($user0)//-1) && 0 == (getgrnam($group0)//-1)
   }) {
      note "error checking uid/gid 0: $@";
      skip_all "This host doesn't have a root user?";
   }

   my $db = Sys::Export::Unix::UserDB->new(auto_import => 1);
   is( $db->user($user0),
      object {
         call uid => 0;
         call group => $group0;
      },
      "auto-loaded user '$user0'"
   );
   is( $db->group($group0),
      object {
         call gid => 0;
      },
      "auto-loaded group '$group0'"
   );
};

done_testing;
