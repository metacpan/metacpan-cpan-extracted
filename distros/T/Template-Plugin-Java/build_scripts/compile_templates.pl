#!/usr/bin/perl

use strict;
use Template;
use Template::Plugin::Java;

# Does this version of the Template Toolkit support compilation? Only version
# 2.x+ does.
if ($Template::VERSION =~ /^[01]/) {
	exit 0;
}

# Ignore warnings.
local $^W = undef;

opendir T, "templates";
chdir "templates";

my @files;

for (readdir T) {
		next if /^\.*$/;
		next unless /^[A-Z][A-z]+$/;
		next if -e "$_.compiled";
		push @files, $_;
}

chdir "..";

open DUMMY, ">Dummy.xml";
print DUMMY <<EOF;
<dummy/>
EOF
close DUMMY;

for my $template (@files) {
# Template could get compiled due to inclusion in another template.
	next if -e "templates/$_.compiled";

# Ignore exceptions, just need a compile of the templates.
	eval {
		new Template::Plugin::Java (
			file	 => "Dummy.xml",
			template => $template
		);
	};
}

# Delete intermediate files.
for (glob "Dummy.*") {
	unlink $_;
}
