use ExtUtils::MakeMaker;

my $found;
my @modz = qw|Crypt::OpenSSL::Random Crypt::URandom|;
for(@modz) { 
  if(eval "require $_; 1") { 
    $found = 1;
    last;
  }
}

unless($found) {
  warn<<END;

Neither $modz[0] or $modz[1] are installed. In order to generate a secret 
you must install one of these modules or, when running the command, specify an alternate
generator via the `-g` option. 

See `mojo secret --help` for more info.

END
}

WriteMakefile(
    NAME => 'Mojolicious::Command::secret',
    AUTHOR => 'Skye Shaw <skye.shaw AT gmail.com>',
    VERSION_FROM => 'lib/Mojolicious/Command/secret.pm',
    ABSTRACT_FROM => 'lib/Mojolicious/Command/secret.pm',
    PREREQ_PM => { 'Mojolicious' => '4.63' },
    LICENSE => 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
      (META_MERGE  => { resources => { bugtracker => 'http://github.com/sshaw/Mojolicious-Command-secret/issues',
                                       repository => 'http://github.com/sshaw/Mojolicious-Command-secret',
                                       homepage   => 'http://github.com/sshaw/Mojolicious-Command-secret'} }) : ())
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
