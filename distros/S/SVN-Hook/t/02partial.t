#!/usr/bin/perl -w

use Test::More;
eval { require SVK::Test; 1 }
    or plan skip_all => 'requires SVK for testing.';
SVK::Test->import;
use SVK::Util 'can_run';
$ENV{SVNLOOK} ||= can_run('svnlook')
    or plan skip_all => 'requires svnlook testing.';
plan tests => 4;
use_ok('SVN::Hook');
use File::Temp 'tempdir';
use File::Path 'mkpath';

my ($xd, $svk) = build_test();
our $output;
my ($repospath, $path, $repos) = $xd->find_repos ('//', 1);

my $hook = SVN::Hook->new({repospath => $repospath});

$hook->init($_) for SVN::Hook->ALL_HOOKS;

my $tmpdir = tempdir( CLEANUP => 1 );

SVN::Hook->_install_perl_hook($hook->hook_path('_pre-commit/partial'), <<'EOF');
use SVN::Hook::Redispatch {
  'foo'     => 'foo_scripts',
  'foo/bar' => 'foobar_scripts',
  'bar'     => 'bar_scripts',
}, @ARGV;
exit 0;
EOF

SVN::Hook->_install_perl_hook($hook->hook_path('_pre-commit/00worky_log'), <<"EOF");
open my \$fh, '>>', "$tmpdir/worky";
print \$fh "this is worky \$ARGV[1]\\n";
EOF

mkpath [$hook->hook_path('_pre-commit/foo_scripts')];

SVN::Hook->_install_perl_hook($hook->hook_path('_pre-commit/foo_scripts/00worky_log'), <<"EOF");
open my \$fh, '>>', "$tmpdir/worky";
print \$fh "this is foo worky \$ARGV[1]\\n";
EOF

SVN::Hook->_install_perl_hook($hook->hook_path('_pre-commit/foo_scripts/die'), <<"EOF");
die "this is foo die";
EOF

is_output($svk, 'mkdir', [-m => 'foo', '//foo'],
	  [qr'Committed']);

is_output($svk, 'mkdir', [-m => 'foo', '//foo/shouldtrigger'],
	  [qr'A repository hook failed.*',
	   qr'this is foo die', '']);

is_file_content("$tmpdir/worky", 'this is worky 0-1
this is worky 1-1
this is foo worky 1-1
');
