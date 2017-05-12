#
# Start by running a script via mod_perl, then switch to running a
# script via mod_persistentperl and you get an "Internal server error".
#
# The GATEWAY_INTERFACE is set to "CGI-Perl" by mod_perl, so in
# perperlcgy when "use CGI" is compiled it thinks it's running under
# mod_perl, and tries to use the Apache module which failes.
#
use lib 't';
use ModTest;

my $libperl	= `apxs -q LIBEXECDIR` . '/libperl.so';
my $docroot	= ModTest::docroot;
my $scr		= 'perperl/mod_perl';

ModTest::test_init(
    5,
    [$scr],
    "
	<IfModule !mod_perl.c>		
	LoadModule perl_module $libperl
	AddModule mod_perl.c		
	</IfModule>			
	<Directory $docroot/mod_perl>	
	DefaultType perl-script 		
	PerlHandler Apache::Registry	
	</Directory>			
    "
);

sub getit { my $which = shift;
    return ModTest::html_get("/$which/mod_perl") =~ /$which/i;
}

if (getit('mod_perl')) {
    print "1..1\n";
    sleep 1;
    if (getit('perperl')) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    # Mod_perl failed, skip this test
    print "1..0\n";
}
