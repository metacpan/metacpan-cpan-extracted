use 5.005;
use ExtUtils::MakeMaker;
use File::Basename qw/ dirname /;

chdir( dirname($0));

@programs= qw/ npadmin /;
foreach my $program ( @programs ) {
  link "bin/mkscript.PL", "bin/$program.PL";
}

WriteMakefile(
	      NAME =>		'SNMP::NPAdmin',
	      AUTHOR =>		'Robert Lehr <bozzio@the-lehrs.com>',
	      ABSTRACT_FROM =>	'NPAdmin.pm',
	      VERSION_FROM =>	'NPAdmin.pm',
	      PL_FILES =>	{ map { ( "bin/$_.PL" => "bin/$_" ) } @programs },
	      DIR =>		[ 'NPAdmin' ],
	      EXE_FILES	=>	[ map { "bin/$_" } @programs ],
	      clean =>	{
			 FILES => join( " ",
					'$(EXE_FILES)', 
					map { "bin/$_.PL" } @programs
				      )
			},
	     );

#
# $Id: Makefile.PL,v 1.6 2002/11/15 03:56:51 bozzio Exp $
#
