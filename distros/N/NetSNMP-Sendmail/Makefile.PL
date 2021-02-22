# SNMP Sendmail Statistics Module -*- perl -*- 
# Copyright (C) 2015, 2016, 2019 Sergey Poznyakoff <gray@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    'NAME'            => 'NetSNMP::Sendmail',
    'AUTHOR'          => 'Sergey Poznyakoff <gray@gnu.org>',
    'ABSTRACT'        => 'NetSNMP module for Sendmail statistics',
    'LICENSE'         => 'gpl_3',
    'FIRST_MAKEFILE'  => 'Makefile',
    'VERSION_FROM'    => 'sendmail.pl',
    'PM'              => {
	'Sendmail.pm' => '$(INST_LIBDIR)/Sendmail.pm'
    },
    'EXE_FILES'       => [ 'netsnmp-sendmail-setup' ],
    'PREREQ_PM'       => { 'NetSNMP::OID' => 0, 
                           'NetSNMP::agent' => 0, 
                           'NetSNMP::ASN' => 0 },
    MIN_PERL_VERSION => 5.10.0,
    META_MERGE => {
	'meta-spec' => { version => 2 },
	resources => {
	    repository => {
		type => 'git',
		url => 'git://git.gnu.org.ua/netsnmp-sendmail.git',
		web => 'http://git.gnu.org.ua/cgit/netsnmp-sendmail.git/',
	    },
            bugtracker => {
	        web => 'https://puszcza.gnu.org.ua/bugs/?group=netsnmp-sendmail',
		mailto => 'gray+netsnmp-sendmail@gnu.org.ua'
	    }
	},
	provides => Module::Metadata->provides(version => '2', dir => '.')
    }
);

sub MY::postamble {
    return <<'_MAKE_';
NET_SNMP_MIBDIRS = `net-snmp-config --mibdirs`

Sendmail.pm: Sendmail.mib2c sendmail.pl SENDMAIL-STATS.txt
	MIBDIRS=.:${NET_SNMP_MIBDIRS} \
        MIBS="+SENDMAIL-STATS" \
         mib2c -c Sendmail.mib2c -f Sendmail.pm -S prologue=sendmail.pl SENDMAIL-STATS::sendmail

INSTALLMIB = $(PREFIX)/share/snmp/mibs
DESTINSTALLMIB = $(DESTDIR)$(INSTALLMIB)    
    
install:: install-mib

install-mib:
	$(PERLRUN) install-mib.pl SENDMAIL-STATS.txt $(DESTINSTALLMIB)    
_MAKE_
}
    
