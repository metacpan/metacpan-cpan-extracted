# $Id: Makefile.PL,v 1.12 2006/05/08 10:55:09 mike Exp $

# If you want to build this module against a YAZ build that's not been
# installed in one of the usual places, just give a full path to where
# your YAZ build's yaz-config script is in the line below.  For example:
#	my $yazconf = "/home/me/stuff/yaz-2.0.4/yaz-config";

my $yazconf = "yaz-config";
my $yazinc = `$yazconf --cflags`;
my $yazlibs = `$yazconf --libs`;
if (!$yazinc || !$yazlibs) {
    die "ERROR: Unable to call script 'yaz-config': is YAZ installed?";
}

print <<__EOT__;

	WARNING.  You should not be using this module unless you need
	this precise API for compatibility reasons.  New applications
	should use the ZOOM-Perl module (Net::Z3950::ZOOM) instead.
		http://search.cpan.org/~mirk/Net-Z3950-ZOOM/

__EOT__

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::Z3950',
    'VERSION_FROM' => 'Z3950.pm', # finds $VERSION
    'LIBS'	=> [ $yazlibs ],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
#	Some systems like to be told:  'DEFINE' => '-D_GNU_SOURCE'
#	Apparently RedHat 8.0 (but NOT 7.3) is one of these.
    'INC'	=> $yazinc,
    'PREREQ_PM' => { Event => 0.77 },
    'MYEXTLIB'	=> 'yazwrap/libyazwrap$(LIB_EXT)',
    'AUTHOR'    => 'Mike Taylor <mike@perl.z3950.org>',
    'ABSTRACT'  => 'Build clients for the Z39.50 info. retrieval protocol',
);


#   ###	I put this bit here basically because the "perlxstut" (XS
#	Tutorial) manual told me to, but frankly I don't understand
#	the MakeMaker.  It seems that this is superfluous, because the
#	generated Makefile in any case recurses to yazwrap at the drop
#	of a hat -- including, for example, when doing a "make test",
#	which is _not_ what I want.  Never mind, it's not the end of
#	the world.
#
sub MY::postamble {
    '$(MYEXTLIB): yazwrap/Makefile
	cd yazwrap && $(MAKE) INC=$(PASTHRU_INC) $(PASTHRU)';
}

sub MY::post_constants {
    'PASTHRU_INC=$(INC)'
}
