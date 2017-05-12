
use 5.008003;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'TaskForest',
    #VERSION_FROM => 'lib/TaskForest.pm', # finds \$VERSION
    VERSION      => '1.37',
    AUTHOR       => 'Aijaz A. Ansari (v-cpan@enoor.com)',
    ABSTRACT     => 'Simple, powerful task scheduler',
    PREREQ_PM    => {
                     'Test::Simple'    => 0.44,
                     'DateTime'        => 0,
                     'Config::General' => 2.38,
                     'Log::Log4perl'   => 1.16,
                     'HTTP::Daemon'    => 5.818,
                     'HTTP::Status'    => 5.817,
                     'HTTP::Response'  => 5.820,
                     'HTTP::Request'   => 5.818,
                     'Net::SMTP'       => 2.31,
                     
                    },
    INSTALLSITEBIN => "bin",
    INSTALLSCRIPT => "bin",
    INSTALLBIN => "bin",
    EXE_FILES => ["run",
                  "run_with_log",
                  "taskforest",
                  "status",
                  "rerun",
                  "mark",
                  "taskforestd",
                  "gen_passwd",
                  "taskforestdssl",
                  "hold",
                  "release",
                  "testSmtpServer",
    ],
);

#FULL_PERL!
#my $path_to_perl = prompt("Please enter the path to your perl: ", "/usr/local/bin/perl");
