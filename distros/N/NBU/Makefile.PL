use ExtUtils::MakeMaker;


my %args = (
            'NAME'	      => 'NBU',
            'VERSION'         => '0.95',
	    'PREREQ_PM' => { 
	      Getopt::Std           => '1.02',
	      IPC::Open2            => '1.01',
	      Date::Parse           => '2.27',
	      Time::Local           => '1.11',
	      Curses                => '1.16',
	      XML::XPath            => '1.13',
	    },

            'EXE_FILES'       => [
               'bin/coverage.pl',
               'bin/nbutop.pl',
               'bin/history.pl',
               'bin/robot-snapshot.pl',
               'bin/drive-watch.pl',
               'bin/js.pl',
               'bin/volume-status.pl',
               'bin/volume-list.pl',
               'bin/scratch.pl',
               'bin/refresh.pl',
               'bin/toc.pl',
               'bin/policy-list.pl',
               'bin/policy-space.pl',
	       'bin/vu.pl',
	       'bin/sla.pl',
	       'bin/volume-use.pl',
	       'bin/robot-status.pl',
	       'bin/client-list.pl',
            ],
            
            dist              => {
              DIST_DEFAULT => 'all tardist',
              COMPRESS     => 'gzip -vf',
              SUFFIX       => '.gz',
            },
            
            clean             => {
              FILES        => '*~',
            },
            
            realclean         => {
              FILES        => '*~ examples/*~ bin/*~ lib/*~ lib/NBU/*~',
            },

            );

WriteMakefile(%args);

package MY;

sub libscan {
  my $self = shift;
  my $path = shift;
  ($path =~ / \bCVS\b | \~$ /x) ? undef : $path;
}

1;
