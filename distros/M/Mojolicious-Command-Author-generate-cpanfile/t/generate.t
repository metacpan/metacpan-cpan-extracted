use Mojo::Base -strict;
use Mojo::File qw(path tempdir);
use Test::More 0.99;

require Mojolicious::Command::Author::generate::cpanfile;

ok my $cpanfile = Mojolicious::Command::Author::generate::cpanfile->new, 'constructor';
isa_ok $cpanfile->app, 'Mojolicious', 'command app';
ok $cpanfile->can('run'), 'can run';
ok $cpanfile->description, 'has a description';
like $cpanfile->usage, qr/cpanfile/, 'has usage information';

my $cwd = path;
my $dir = tempdir CLEANUP => 1;

chdir $dir;

my $buffer = '';
{
    open my $handle, '>', \$buffer;
    local *STDOUT = $handle;
    $cpanfile->run;
}
like $buffer, qr/cpanfile/, 'right output';
ok -e $cpanfile->rel_file('cpanfile'), 'cpanfile exists';

chdir $cwd;

done_testing;

