#!/usr/bin/perl -w

# Makefile.PL for Net::ICal::VTIMEZONES
# $Id: Makefile.PL,v 1.7 2001/11/25 23:04:42 srl Exp $
# 
use strict;
use ExtUtils::MakeMaker;

print 
"-------------------------------------------------------------------
Thanks for your interest in Net::ICal::VTIMEZONES.  
You should know that this is an ALPHA RELEASE. That means that IT
MAY NOT WORK FOR YOU. If it doesn't, please send us a bug report.

IMPORTANT: please read the README file before running 'make';
this module's installer is nonstandard and does things you may
not expect. 

- The Reefknot team (http://reefknot.sf.net)
-------------------------------------------------------------------
";

# This inserts an "install vtimezones" step into the make. 
# Quite probably, this should be a step at the "make install"
# level; patches welcome. Also, we need a way to uninstall these
# files. 
{
    package MY;
    sub top_targets {
        my($self) = @_;
        my $out = "VTIMEZONE_INSTALLER = ./install_vtimezones.pl\n";

        $out .= $self->SUPER::top_targets(@_);
        # insert the vtimezone_installer into the main targets
        $out =~ s/^(pure_all\b.*)/$1 install_vtimezones/m;

        # describe how to run install_vtimezones as part of the
        # make process.
        $out .= "\n\ninstall_vtimezones : \n";
        $out .= "\tif [ ! -e \$(PREFIX)/share ]; then mkdir \$(PREFIX)/share; fi; ";
        $out .= "\$(VTIMEZONE_INSTALLER) --PREFIX=\$(PREFIX)/share ";
       
        return $out;
    }
}

WriteMakefile(
		'MAKEFILE'=> 'Makefile',
		'VERSION' => '0.02',
		'NAME'    => 'Net::ICal::VTIMEZONES', 
       	'PM' => 
           {'lib/Net/ICal/Config.pm' => '$(INST_LIBDIR)/Config.pm',
           'lib/Net/ICal/VTIMEZONES.pm' => '$(INST_LIBDIR)/VTIMEZONES.pm'},

        dist => {
			COMPRESS     =>'gzip',
			SUFFIX       =>'gz',
		},
	);


