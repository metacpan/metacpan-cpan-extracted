use ExtUtils::MakeMaker;
WriteMakefile(NAME => 'NcFTPd::Log::Parse',
	      VERSION_FROM => 'lib/NcFTPd/Log/Parse.pm');

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

