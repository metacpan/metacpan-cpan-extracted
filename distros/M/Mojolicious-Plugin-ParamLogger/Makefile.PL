use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::ParamLogger',
  VERSION_FROM => 'lib/Mojolicious/Plugin/ParamLogger.pm',
  AUTHOR       => 'Skye Shaw',
  PREREQ_PM    => {'Mojolicious' => '2.15'},
  test         => {TESTS => 't/*.t'},
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
     (META_MERGE  => { resources => { bugtracker => 'http://github.com/sshaw/Mojolicious-Plugin-ParamLogger/issues',
				      repository => 'http://github.com/sshaw/Mojolicious-Plugin-ParamLogger',
				      homepage   => 'http://github.com/sshaw/Mojolicious-Plugin-ParamLogger'} }) : ())
);

# Create README.pod for a repo's GitHub page. Unlike CPAN, GitHub won't
# display the module's POD, it looks for a README.*
use Config;
sub MY::postamble
{
  my $self = shift;
  return if -r 'README' or ! -r $self->{VERSION_FROM};
  return<<END_MAKE;
README.pod: $self->{VERSION_FROM}
	\@$Config{bin}/perldoc -uT $self->{VERSION_FROM} > README.pod
END_MAKE
}


