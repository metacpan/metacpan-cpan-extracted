use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.7 2003/06/14 20:05:11 lem Exp $

WriteMakefile(
    'NAME'		=> 'Net::DNS::Method',
    'VERSION_FROM'	=> 'lib/Net/DNS/Method.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
      File::Find => 0,
      NetAddr::IP => 3.00,
      Net::DNS => 0.38,		# Needs safe_push
  }, # e.g., Module::Name => 1.1
);

