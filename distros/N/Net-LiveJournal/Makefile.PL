use ExtUtils::MakeMaker;
WriteMakefile( 'NAME' => 'Net::LiveJournal',
               'VERSION_FROM' => 'lib/Net/LiveJournal.pm',
               'PREREQ_PM'              => {
                   'LWP::UserAgent' => 0,
               },
               ($] >= 5.005 ?
                (ABSTRACT_FROM => 'lib/Net/LiveJournal.pm',
                 AUTHOR     => 'Brad Fitzpatrick <brad@danga.com>') : ()),
               );

