#!/usr/bin/perl -w

use Test::More;
eval { require SVK::Test; 1 }
    or plan skip_all => 'requires SVK for testing.';
SVK::Test->import;
use SVK::Util 'can_run';
$ENV{SVNLOOK} ||= can_run('svnlook')
    or plan skip_all => 'requires svnlook testing.';

plan tests => 3;
use_ok('SVN::Hook');

my ($xd, $svk) = build_test();
our $output;
my ($repospath, $path, $repos) = $xd->find_repos ('//', 1);

my $hook = SVN::Hook->new({repospath => $repospath});

$hook->init($_) for SVN::Hook->ALL_HOOKS;

install_perl_hook($repospath, '_pre-commit/01worky', <<"EOF");
exit 0;
EOF

install_perl_hook($repospath, '_pre-commit/02die', <<"EOF");
die "this is \$0\\n";
EOF

is_output($svk, 'mkdir', [-m => 'foo', '//foo'],
	  [qr'A repository hook failed.*',
	   qr'this is .*02die', '']);

is_deeply( $hook->status,
	   { ( map { $_ => 0 } SVN::Hook->ALL_HOOKS ),
	     'pre-commit' => 2 } );


__END__
use SVN::Hook::CLI;
SVN::Hook::CLI->list($repospath, 'pre-commit');
SVN::Hook::CLI->status($repospath);
