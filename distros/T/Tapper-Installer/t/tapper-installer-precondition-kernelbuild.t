use strict;
use warnings;

use Test::More;
use Log::Log4perl;

use Tapper::Installer::Precondition::Kernelbuild;

my $string = "
log4perl.rootLogger           = WARN, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


my $builder = Tapper::Installer::Precondition::Kernelbuild->new();
is($builder->fix_git_url('git://osrc/tip.git'),'git://wotan.amd.com/tip.git','Fix with osrc');
is($builder->fix_git_url('git://osrc.amd.com/tip.git'),'git://wotan.amd.com/tip.git','Fix with osrc.amd.com');
is($builder->fix_git_url('git://osrc.osrc.amd.com/tip.git'),'git://wotan.amd.com/tip.git','Fix with osrc.osrc.amd.com');
is($builder->fix_git_url('git://wotan/tip.git'),'git://wotan/tip.git','No fix with wotan');
is($builder->fix_git_url('git://bullock/tip.git'),'git://bullock/tip.git','No fix with bullock');
is($builder->fix_git_url('ssh://osrc/tip.git'),'ssh://osrc/tip.git','No fix without git prefix');

done_testing();
