use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
     NAME         => 'Mojolicious::Plugin::FormFields',
     VERSION_FROM => 'lib/Mojolicious/Plugin/FormFields.pm',
     ABSTRACT_FROM => 'lib/Mojolicious/Plugin/FormFields.pm',
     AUTHOR       => 'Skye Shaw <sshaw AT lucas.cis.temple.edu>',	      
     PREREQ_PM    => { 'Mojolicious' => '2.52',
		       'Mojolicious::Plugin::ParamExpand' => 0, 
		       'Validate::Tiny' => '0.98' },
     LICENSE      => 'perl',
     test         => {TESTS => 't/*.t'},
     (eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
      (META_MERGE  => { resources => { bugtracker => 'http://github.com/sshaw/Mojolicious-Plugin-FormFields/issues',
                                       repository => 'http://github.com/sshaw/Mojolicious-Plugin-FormFields',
				       homepage   => 'http://github.com/sshaw/Mojolicious-Plugin-FormFields'} }) : ())
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

# Include test helpers and/or libs
sub MY::test
{
  package MY;
  my $make = shift->SUPER::test(@_);
  $make .= 'FULLPERLRUN = $(FULLPERL) -I t -I t/lib';
  return $make;
}
