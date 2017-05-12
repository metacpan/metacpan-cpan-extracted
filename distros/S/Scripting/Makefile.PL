# $Source: /Users/clajac/cvsroot//Scripting/Makefile.PL,v $
# $Author: clajac $
# $Date: 2003/07/21 07:44:47 $
# $Revision: 1.4 $

use ExtUtils::MakeMaker qw(WriteMakefile prompt);
use strict;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %params = (
	      'NAME'          => 'Scripting',
	      'VERSION_FROM'  => 'Scripting.pm',
	      'ABSTRACT_FROM' => 'Scripting.pm',
	      'AUTHOR'        => 'Claes Jacobsson <claesjac@cpan.org>',
	      'PREREQ_PM'     => {
				  'Attribute::Handlers' => 0.78,
				  'Carp'                => 0,
				  'IO::Dir'             => 0,
				  'IO::File'            => 0,
				  'File::Spec'          => 0,
				  'Digest::SHA1'        => 2.02,
				  'File::Find::Rule'    => 0.10,
				  'DB_File'             => 1.72
				 }
	     );

if(prompt("Do you want JavaScript support?", "y") =~ /^y/i) {
  $params{PREREQ_PM}->{JavaScript} = 0.52;
}

if(prompt("Do you want to install the sign_script.pl tool?", "y") =~ /^y/i) {
  $params{EXE_FILES} = [ 'tools/sign_script.pl' ];
}

WriteMakefile(%params);
