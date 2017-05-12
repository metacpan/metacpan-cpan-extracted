
package XMLTests;

BEGIN { *$_ = \&{"main::$_"} for qw(ok diag) }
use Scriptalicious;
use File::Find;
use FindBin qw($Bin);
use strict;
use YAML qw(Load Dump);

our $grep;
getopt_lenient( "test-grep|t=s" => \$grep );

sub find_tests {
	my $group = shift;
	my @tests;
	find(
		sub {
			if (m{\.(?:x|ya)ml$}
				&&
				(!$grep||$File::Find::name=~m{$grep})
				)
			{   my $name = $File::Find::name;
				$name =~ s{^\Q$Bin\E/}{} or die;
				push @tests, $name;
			}
		},
		"$Bin/$group"
	);
	@tests;
}

sub read_xml {
	my $test = shift;
	open XML, "<$Bin/$test";
	binmode XML, ":utf8";
	my $xml = do {
		local($/);
		<XML>;
	};
	close XML;
	$xml;
}

sub read_yaml {
	my $test = shift;
	open YAML, "<$Bin/$test";
	binmode YAML, ":utf8";
	my $yaml = do {
		local($/);
		<YAML>;
	};
	close YAML;
	my $obj = Load($yaml);
	if (wantarray) {
		return ($obj, $yaml);
	}
	else {
		return $obj;
	}
}

sub parse_test {
	my $class = shift;
	my $xml = shift;
	my $test_name = shift;
	my $lax = shift // 0;
	
	my $object = eval { $class->parse($xml, $lax) };
	my $ok = ok($object, "$test_name - parsed OK");
	if ( !$ok ) {
		diag("exception during parsing: $@");
	}
	if ( $ok and ($main::VERBOSE//0)>0) {
		diag("read: ".Dump($object));
	}
	$object;
}

sub parsefail_test {
	my $class = shift;
	my $xml = shift;
	my $test_name = shift;
	my $object = eval { $class->parse($xml) };
	my $error = $@;
	my $ok = ok(!$object&&$error, "$test_name - exception raised");
	if ( !$ok ) {
		diag("parsed to: ".Dump($object));
	}
	if ( $ok and ($main::VERBOSE||0)>0) {
		diag("error: ".Dump($error));
	}
	$error;
}

sub emit_test {
	my $object = shift;
	my $test_name = shift;
	start_timer;
	my $r_xml = eval { $object->to_xml };
	my $time = show_elapsed;
	ok($r_xml, "$test_name - emitted OK ($time)")
		or do {
		diag("exception during emitting: $@");
		return undef;
		};
	if (($main::VERBOSE||0)>0) {
		diag("xml: ".$r_xml);
	}
	return $r_xml;
}

sub xml_compare_test {
	my $xml_compare = shift;
	my $r_xml = shift;
	my $xml = shift;
	my $test_name = shift;

	my $is_same = $xml_compare->is_same($r_xml, $xml);
	ok($is_same, "$test_name - XML output same")
		or diag("Error: ".$xml_compare->error);

}

1;

# Copyright (C) 2009, 2010  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
