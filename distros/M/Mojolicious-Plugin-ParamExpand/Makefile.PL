use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
     NAME         => 'Mojolicious::Plugin::ParamExpand',
     VERSION_FROM => 'lib/Mojolicious/Plugin/ParamExpand.pm',
     ABSTRACT_FROM => 'lib/Mojolicious/Plugin/ParamExpand.pm',
     AUTHOR       => 'Skye Shaw <skye.shaw AT gmail.com>',
     PREREQ_PM    => { 'Mojolicious' => '2.52',
		       'CGI::Expand' => 0 },
     LICENSE      => 'perl',
     MAN3PODS	  => {},
     test         => {TESTS => 't/*.t'},
     (eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
       (META_MERGE  => { resources => { bugtracker => 'http://github.com/sshaw/Mojolicious-Plugin-ParamExpand/issues',
					repository => 'http://github.com/sshaw/Mojolicious-Plugin-ParamExpand',
					homepage   => 'http://github.com/sshaw/Mojolicious-Plugin-ParamExpand' } }) : ())
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
