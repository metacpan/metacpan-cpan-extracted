use ExtUtils::MakeMaker;

WriteMakefile(
              NAME             => 'Net::Gnats',
              VERSION_FROM     => 'lib/Net/Gnats.pm',
              AUTHOR           => 'Richard Elberger <riche@cpan.org>, ',
              ABSTRACT         => 'Interface to GNU Gnats Daemon',
              MIN_PERL_VERSION => '5.010_000',
              PREREQ_PM        => { 'strictures' => 0 },
              TEST_REQUIRES    => { 'Test::MockObject' => 0 }, );
