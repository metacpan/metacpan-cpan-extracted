use Module::Build;
my $filename = shift;

my $mb = Module::Build->current();

if ( $mb->feature('rsync_support') and $mb->notes('rsynctests') ) {
    my $ssh = '';
    if ( $mb->feature('rsyncsshtests') ) {
	$ssh = "'rsync-ssh' => 1";
    }
    open my $FILE, '>', $filename;
    print {$FILE} <<"EOF";
require SVN::Notify;
use Test::More;
require "t/coretests.pm";

SKIP: {
    my \$SVNNOTIFY = \$ENV{'SVNNOTIFY'} || SVN::Notify->find_exe('svnnotify');
    skip "Cannot locate svnnotify binary!", 78
    	unless defined(\$SVNNOTIFY);

    reset_all_tests();
    run_tests(\$SVNNOTIFY, 'rsync-host' => 'localhost', $ssh);
    reset_all_tests();
    run_tests("\$SVNNOTIFY --minimal", 'rsync-host' => 'localhost', $ssh);
}
EOF
    close $FILE;
}
