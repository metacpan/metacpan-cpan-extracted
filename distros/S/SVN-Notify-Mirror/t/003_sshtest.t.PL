use Module::Build;
my $filename = shift;

my $mb = Module::Build->current();

if ( $mb->feature('ssh_support') and $mb->notes('sshtests') ) {
    open my $FILE, '>', $filename;
    print {$FILE} <<"EOF";
require SVN::Notify;
use Test::More;
require "t/coretests.pm";

SKIP: {
    my \$SVNNOTIFY = \$ENV{'SVNNOTIFY'} || SVN::Notify->find_exe('svnnotify');
    skip "Cannot locate svnnotify binary!", 54
    	unless defined(\$SVNNOTIFY);

    reset_all_tests();
    run_tests(\$SVNNOTIFY, 'ssh-host' => 'localhost' );
    reset_all_tests();
    run_tests("\$SVNNOTIFY --minimal", 'ssh-host' => 'localhost' );
}
EOF
    close $FILE;
}
