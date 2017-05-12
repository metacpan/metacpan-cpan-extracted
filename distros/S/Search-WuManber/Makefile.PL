#
# Makefile.PL for Search::WuManber
# Distributable under the terms of GPLv2
#
# 2007-04-12, jw, V0.1  -- initial draft
# 2010-01-08, jw, V0.20 -- continued. Works smooth now.
# 2010-01-18, jw, V0.22 -- added case_sensitive, return_string options.
#

use ExtUtils::MakeMaker;

WriteMakefile(
 NAME		=> 'Search::WuManber',
 VERSION_FROM	=> 'WuManber.pm',		# finds $VERSION
 PREREQ_PM      => {}, 				# e.g., Module::Name => 1.1
# ABSTRACT_FROM  => 'WuManber.pm', 		# retrieve abstract from module (since 5.004)
 AUTHOR         => 'Juergen Weigert <jw@suse.de>',
 LIBS		=> [''],			# e.g. '-lm'
 OBJECT		=> 'WuManber.o wumanber_impl.o',
 DEFINE		=> '',				# e.g. -DHAVE_FOO
 INC		=> '',				# e.g. -I/usr/include/foo
 clean          => { FILES => ['Search-WuManber-*', '*.orig'] },
);

