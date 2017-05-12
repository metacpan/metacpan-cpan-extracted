# $Id: Makefile.PL 263 2004-05-09 22:27:04Z sungo $
use ExtUtils::MakeMaker;

my $prompt = <<EOP;
Some of the tests for this module require usage of the network.
They will cause a program to listen on 127.0.0.1 port 31337 so
the functionality of the user interface can be tested.
Would you like to run these network tests?
EOP
my $ret = prompt($prompt."(Any text other than Y or y will be be taken as a no)","n");

my $marker = 'run_network_tests';

if($ret =~ /^Y$/i) {
    open(SAFE,"+>$marker");
    print SAFE 1;
    close SAFE;
} else {
    unlink $marker if -f $marker;
}

WriteMakefile(
    NAME => 'POE::Component::ControlPort',
    AUTHOR => 'Matt Cashner (sungo@pobox.com)',
    VERSION_FROM => 'VERSION',
    PREREQ_PM => {
        'POE'               => '0.2802',
        'Authen::Libwrap'   => 0,
        'Params::Validate'  => 0,
        'Sys::Hostname'     => 0,
        'File::Basename'    => 0,
        'Carp'              => 0,
        'Test::More'        => 0,
    },
    dist => {
        PREOP => 'svn log > ${DISTVNAME}/Changes',
    },
    clean => {
        FILES => 'run_network_tests',
    },
);
