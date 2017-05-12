#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

use t::TestCerts;
use ExtUtils::MakeMaker;

use File::Find;
my %PM;
find(
	sub {
		m{\.(pm|pod)$} && do {
			(my $inst_name = $File::Find::name)
				=~ s{lib}{\$(INST_LIBDIR)};
			$PM{$File::Find::name} = $inst_name;
		},
	},
	"lib",
       );

WriteMakefile(
	NAME => "Net-SSLeay-OO",
	ABSTRACT => "OO Calling Method for Net::SSLeay",
	AUTHOR => "Catalyst SRS Team <team-srs\@catalyst.net.nz>",
	VERSION_FROM => "lib/Net/SSLeay/OO.pm",
	LICENSE => "artistic",
	PREREQ_PM => {
		#"perl" => 5.008005);
		"Moose" => 0.54,
		"Net::SSLeay" => 1.35,
	},
	PM => \%PM,
);

