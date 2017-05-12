
use ExtUtils::MakeMaker;
use strict;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence the
# contents of the Makefile that is written.
my $package = "Profile::Log";
(my $pm = $package) =~ s{::}{/}g;
$pm = "lib/$pm.pm";

my ($no_scripts, $no_templates, $TT_INSTDIR);
eval { require Scriptalicious };
if ( $@ ) {
    print STDERR <<"EOF";
****
**** Scriptalicious is required for the post-processing scripts
**** included with this module.  These will not be installed.
****
EOF
    $no_scripts = 1;
} else {

    if ( ($TT_INSTDIR) = map { s/^.*?=//; $_ }
	 grep /^TT_INSTDIR=/, @ARGV ) {
	@ARGV = grep !/^TT_INSTDIR=/, @ARGV;
	print <<"EOF";
Using template installation directory of $TT_INSTDIR
EOF
    } else {

	eval { require Template::Config };
	if ( $@ ) {
	    print STDERR <<"EOF";
****
**** Template Toolkit is required for the SVG visualisation component
**** of this module.  No templates will be installed.
****
EOF
	    $no_templates = 1;
	} else {

	    # FIXME - UNIX specific
	    print <<"EOF";

Where should I stick my templates?
==================================
This module bundles some Template Toolkit templates, which are
normally installed somewhere under /usr/local.  The default for this
module is to install them alongside the Template Toolkit templates
bundled with Template Toolkit.

EOF

	    if ( -d $Template::Config::INSTDIR."/templates" ) {
		$TT_INSTDIR = $Template::Config::INSTDIR."/templates";
		print <<"EOF";
Your Template Toolkit templates are installed in
$TT_INSTDIR

EOF
		$TT_INSTDIR .= "/profile-log";

	    } else {
		$TT_INSTDIR = "/usr/local/share/profile-log";
		print <<"EOF";
I couldn't find a good existing location for templates.  Defaulting to
a different reasonable location instead.

EOF
	    }

	    if ( -t STDIN ) {
		my $response = prompt("Directory to install templates?",
				      $TT_INSTDIR );
		die "wrong answer" unless $response;
		$TT_INSTDIR = $response;
	    } else {
		print <<EOF
STDIN not on a terminal - assuming default is OK.

Override via Makefile parameter TT_INSTDIR if required.
EOF
	    }
	}
    }
}

WriteMakefile
    (
     'NAME'	=> $package,
     # finds $VERSION
     'VERSION_FROM' => $pm,
     'PREREQ_PM' => { YAML => 0.35,
		      'Set::Object' => 1.10,
		      'Time::HiRes' => 0,
		      'List::Util' => 0,
		      'Scalar::Util' => 0,
		    },
     ($TT_INSTDIR ? (macro => {'TT_INSTDIR' => $TT_INSTDIR}) : ()),
     ($no_scripts ? () : ('EXE_FILES' => [ glob("bin/[a-z]*") ]) ),
     ($] ge '5.005')
     ? (
	'AUTHOR' => 'Sam Vilain <samv@cpan.org>',
	'ABSTRACT_FROM' => $pm,
       )
     : (),
    );

package MY;

sub install {
    my $inherited = shift->SUPER::install(@_);

    (
     ($inherited =~ s{^(install :: .*)}{$1 template_install config_install}m)
     &&
     ($inherited =~ s{^(install_(\w+) :: .*)}{$1 config_$2_install}m)
    )
	or die "damn, failed to modify Makefile.";

    $inherited;
}

# FIXME - UNIX specific
sub postamble {
    return <<'Makefile';
template_install ::
	$(NOECHO) umask 022
	-mkdir -p $(DESTDIR)$(TT_INSTDIR)
	cp -r templates/*.tt $(DESTDIR)$(TT_INSTDIR)/

config_install :: config_$(INSTALLDIRS)_install

config__install: config_site_install
        $(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=sit
config_perl_install ::
	$(PERL) -npi -e 's{__.*__}{'$(TT_INSTDIR)'}' $(DESTINSTALLPRIVLIB)/Profile/Log/Config.pm

config_site_install ::
	$(PERL) -npi -e 's{__.*__}{'$(TT_INSTDIR)'}' $(DESTINSTALLSITELIB)/Profile/Log/Config.pm

config_vendor_install ::
	$(PERL) -npi -e 's{__.*__}{'$(TT_INSTDIR)'}' $(DESTINSTALLVENDORLIB)/Profile/Log/Config.pm

Makefile
}
