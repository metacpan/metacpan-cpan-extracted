# This -*- perl -*- script writes the Makefile for RCGI
# $Id: Makefile.PL,v 1.0 1998/3/13 22:30:00 aas Exp $
use ExtUtils::MakeMaker;
require 5.004;

#--- Configuration section ---

#--- End Configuration - You should not have to change anything below this line

die qq{

Your perl is too old for this version of RCGI

Please upgrade your perl.

} if $] < 5.004;
$Verbose = 1;

# Check for non-standard modules that are used by this library.
$| = 1;
my $missing_modules = 0;

print "Checking for HTTP::Request::Common..";
eval {
    require HTTP::Request::Common;
#    #HTTP::Request::Common->require_version('2.00');
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
    $@
	The HTTP::Request::Common module is needed by RCGI.
EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print "Checking for LWP::UserAgent..";
eval {
    require LWP::UserAgent;
#    #HTTP::Request::Common->require_version('2.00');
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
    $@
	The LWP::UserAgent module is needed by RCGI.
EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print "Checking for LWP::Simple..";
eval {
    require LWP::Simple;
#    #HTTP::Request::Common->require_version('2.00');
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
    $@
	The LWP::Simple module is needed by RCGI.
EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print "Checking for URI::URL..";
eval {
    require URI::URL;
#    #HTTP::Request::Common->require_version('2.00');
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
    $@
	The URI::URL module is needed by RCGI.
EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print "Checking for CGI..";
eval {
    require CGI;
#    #HTTP::Request::Common->require_version('2.00');
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
    $@
	The CGI module is needed by RCGI.
EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print "Checking for Data::Dumper..";
eval {
    require Data::Dumper;
#    #HTTP::Request::Common->require_version('2.00');
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
    $@
	The Data::Dumper module is needed by RCGI.
EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

WriteMakefile(
	      'NAME'		=> 'RCGI',
	      'DISTNAME'	=> 'RCGI',
	      'VERSION_FROM'	=> 'RCGI.pm',
	      'PMLIBDIRS'       => [ 'Data' ],
	      'clean'       => { FILES => 'RCGI.html' },
	      'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

package MY;

sub MY::test_via_harness { "" }

sub MY::test_via_script {
	my( $self, $perl, $script ) = @_;
	my $res;

	$res = $self->MM::test_via_script( $perl, $script );
	$res =~ s/(test.pl)/$1 -p $perl/;
	$res;
}

sub manifypods
{
    my $self = shift;
    local($_) = $self->SUPER::manifypods(@_);
    my($pod2man_exe) = /POD2MAN_EXE\s*\=\s*(.*)\n/m;
    $pod2man_exe =~ s/^\s*//;
    $pod2man_exe =~ s/\s*$//;
    my($pod2html_exe) = $pod2man_exe;
    $pod2html_exe =~ s/2man/2html/;
    $_  
#    . "\n\t$pod2html_exe --infile=RCGI.pm --outfile=RCGI.html --index\n\trm -f pod2html-*cache\n";
}

sub MY::postamble {
' 
schema_cache :: 
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) \
		cache/make_cache_dir.pl
'
}
