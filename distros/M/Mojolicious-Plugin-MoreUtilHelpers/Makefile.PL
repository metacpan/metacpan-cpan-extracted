use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::MoreUtilHelpers',
  PREREQ_PM    => { 'Mojolicious' => '6.0',
		    'Lingua::EN::Inflect' => 0 },
  test         => {TESTS => 't/*.t'},
  VERSION_FROM => 'lib/Mojolicious/Plugin/MoreUtilHelpers.pm',
     LICENSE       => 'perl',
     VERSION_FROM  => 'lib/Mojolicious/Plugin/MoreUtilHelpers.pm',
     ABSTRACT_FROM => 'lib/Mojolicious/Plugin/MoreUtilHelpers.pm',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
       (META_MERGE  => { resources => { bugtracker => 'http://github.com/sshaw/Mojolicious-Plugin-MoreUtilHelpers/issues',
                                        repository => 'http://github.com/sshaw/Mojolicious-Plugin-MoreUtilHelpers'} }) : ())
);

# Create README.pod for a repo's GitHub page. Unlike CPAN, GitHub won't
# display the module's POD, it looks for a README.*
sub MY::postamble
{
    my $self = shift;
    return if -r 'README' or ! -r $self->{VERSION_FROM};
    return<<END_MAKE;
README.pod: $self->{VERSION_FROM}
	\@perldoc -uT $self->{VERSION_FROM} > README.pod
END_MAKE
}
