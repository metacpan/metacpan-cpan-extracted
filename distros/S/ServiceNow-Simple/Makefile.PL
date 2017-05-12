use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'ServiceNow::Simple',
    AUTHOR           => q{Greg George <GNG@cpan.org>},
    VERSION_FROM     => 'lib/ServiceNow/Simple.pm',
    ABSTRACT_FROM    => 'lib/ServiceNow/Simple.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'SOAP::Lite'            => 1.06,
        'Crypt::SSLeay'         => 0,
        'IO::Socket::SSL'       => 0,
        'File::Basename'        => 0,
        'MIME::Types'           => 0,
        'MIME::Type'            => 0,
        'MIME::Base64'          => 0,
        'HTTP::Cookies'         => 0,
        'HTTP::Request::Common' => 0,
        'LWP::UserAgent'        => 0,
        'XML::Simple'           => 0,
        'Carp'                  => 0
    },
    PL_FILES => {'Config.PL' => 'config'},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'ServiceNow-Simple-*' },
);

makeTestConfig();

if (!$ENV{AUTOMATED_TESTING})
{
    print "
    Type 'make' (windows: 'nmake' or 'dmake') to build ServiceNow::Simple.
    Type 'make test' to test ServiceNow::Simple before installing.
    Type 'make install' to install ServiceNow::Simple.

    ";
}

exit 0;


sub makeTestConfig
{
    my ($instance, $user, $password);
    my ($i, $u, $p) = ('demo019', 'admin', 'admin');

    if(-e './t/config.cache')
    {
        do './t/config.cache';
        $i = &CCACHE::instance;
        $u = &CCACHE::user;
        $p = &CCACHE::password;
    }

    print "=== ServiceNow::Simple 'make test' configuration. ===

The tests will work with the ServiceNow demo019 instance with user
'admin' and password 'admin'.  You MAY need to add the 'soap' role
to the 'admin' user first and ensure that read and write ACL for table
sys_user_group is set for users with the 'soap' role.  The tests use
the group 'CAB Approval'.

-OR-

Test on your own dev system where you know the user you select below
has the 'soap' role and the sys_user_group table has read/write for
the 'soap' role.

Please enter the following information. This information will be
recorded in ./t/config.cache.  YOU SHOULD REMOVE this file once
you have finished testing as the data is in plain text.

As an alternate, skip testing and install and start trying it out!

If you want to skip the 'make test' step, just hit ENTER
three times. You can configure it later by either re-running
'perl Makefile.PL' or by editting ./t/config.cache

Fair warning: you probably don't want to run 'make test' against a
production ServiceNow instance.

You can try the ServiceNow demo instances, generally something in the
range demo001 to demo026, if you don't have your own instance(s).

";

    $instance = prompt("The instance is the myinstance in http://myinstance.service-now.com/\nInstance name", $i);
    if ($instance eq '') { $instance = $i if ($i ne ''); }

    $user = prompt("Username with the soap role", $u);
    if($user eq '') { $user = $u if ($u ne ''); }

    $password = prompt("Password", $p);;
    if($password eq '') { $password = $p if ($p ne ''); }

    #print "Storing $SERVER / $USERNAME / $PASSWORD ..\n";
    open (FD, '>', './t/config.cache') || die "open of './t/config.cache' failed: $!";
    print FD "package CCACHE;\n";
    print FD "\# enter your instance, soap role username and password below.\n\n";
    print FD qq{sub instance { '$instance' ; }\n};
    print FD qq{sub user     { '$user' ; }\n};
    print FD qq{sub password { '$password' ; }\n};
    print FD "1;\n";
    close(FD);
}
