use ExtUtils::MakeMaker;

unless($] >= 5.004)
{
  print<<"EOF";

       *** FATAL ERROR: TIME TO UPGRADE! ***

Net::Hotline requires Perl version 5.004 or higher.
The times, they are a-changing...

EOF

  exit(1);
}

WriteMakefile('NAME'         => 'Net::Hotline',
              'PMLIBDIRS'    => [ 'lib/Net/', 'lib/Net/Hotline',
                                  'lib/Net/Hotline/Protocol' ],
              'PREREQ_PM' =>
              {
                'IO::File'   => 0,
                'IO::Socket' => 0,
                'Carp'       => 0
              },
              'VERSION_FROM' => 'lib/Net/Hotline.pm',
              'dist' => { 'COMPRESS' => 'gzip' });
