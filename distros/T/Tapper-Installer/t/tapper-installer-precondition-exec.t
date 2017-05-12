#! /usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More;
use File::Temp qw/tempdir/;
use Test::MockModule;
use Test::Deep;

use Log::Log4perl;

my $string = "
log4perl.rootLogger           = WARN, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


use subs qw/chroot chdir/;
sub chroot { return; }
sub chdir  { return; }

my $tempdir = tempdir( CLEANUP => 1 );
my $config = {paths =>
              {base_dir => $tempdir }
             };


BEGIN {
        use_ok('Tapper::Installer::Precondition::Exec');
}


my $exec_precondition = {
                         command => 'ls -l',
                         options => [ '-k', '-m'],
                        };

my $module = Test::MockModule->new('Tapper::Installer::Precondition::Exec');
$module->mock('file_save', sub {return 0});
$module->mock('log_and_exec', sub { return 0});

my $exec_installer = Tapper::Installer::Precondition::Exec->new($config);
my $retval = $exec_installer->install($exec_precondition);
is($retval, 0, 'Exec success');
done_testing();
