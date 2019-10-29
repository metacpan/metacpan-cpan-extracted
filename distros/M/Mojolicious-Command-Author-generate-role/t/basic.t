use Mojo::Base -strict;

use Test::More;
use Mojo::File qw(curfile path tempdir);
use lib curfile->sibling('lib')->to_string;

use Mojolicious ();

# generate role
require Mojolicious::Command::Author::generate::role;
my $role_cmd = Mojolicious::Command::Author::generate::role->new;
my $cwd = path;

ok $role_cmd->description, 'has a description';
like $role_cmd->usage, qr/role/, 'has usage information';
my $dir = tempdir CLEANUP => 1;
chdir $dir;
my $buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $role_cmd->run;
}
like $buffer, qr/MyRole\.pm/, 'right output';
ok -e $role_cmd->rel_file('MyRole/lib/MyRole.pm'), 'class exists';
ok -e $role_cmd->rel_file('MyRole/t/basic.t'), 'test exists';
ok -e $role_cmd->rel_file('MyRole/Makefile.PL'), 'Makefile.PL exists';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $role_cmd->run('Mojo::Promise', 'Fluffy');
}
like $buffer, qr/Fluffy\.pm/, 'right output';
ok -e $role_cmd->rel_file('Mojo-Promise-Role-Fluffy/lib/Mojo/Promise/Role/Fluffy.pm'), 'class exists';
ok -e $role_cmd->rel_file('Mojo-Promise-Role-Fluffy/t/basic.t'), 'test exists';
ok -e $role_cmd->rel_file('Mojo-Promise-Role-Fluffy/Makefile.PL'), 'Makefile.PL exists';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $role_cmd->run('-f', 'Mojo::Promise', 'MyOtherRole');
}
like $buffer, qr/MyOtherRole\.pm/, 'right output';
ok -e $role_cmd->rel_file('MyOtherRole/lib/MyOtherRole.pm'), 'class exists';
ok -e $role_cmd->rel_file('MyOtherRole/t/basic.t'), 'test exists';
ok -e $role_cmd->rel_file('MyOtherRole/Makefile.PL'), 'Makefile.PL exists';
chdir $cwd;

done_testing();
