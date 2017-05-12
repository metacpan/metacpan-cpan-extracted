use ExtUtils::MakeMaker;

WriteMakefile(
     NAME          => 'Mojolicious::Plugin::DigestAuth',
     AUTHOR        => 'Skye Shaw <sshaw AT lucas.cis.temple.edu>',	      
     PREREQ_PM     => { 'Mojolicious' => '2.20' },
     LICENSE       => 'perl',
     VERSION_FROM  => 'lib/Mojolicious/Plugin/DigestAuth.pm',
     ABSTRACT_FROM => 'lib/Mojolicious/Plugin/DigestAuth.pm',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
       (META_MERGE  => { resources => { bugtracker => 'http://github.com/sshaw/Mojolicious-Plugin-DigestAuth/issues',
                                        repository => 'http://github.com/sshaw/Mojolicious-Plugin-DigestAuth'} }) : ())     
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
