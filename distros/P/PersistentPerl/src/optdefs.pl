#
# Generate C-code and documentation from the optdefs file
#
#
# Copyright (C) 2003  Sam Horrocks
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#
$^W = 1;
use strict;
use Text::Wrap qw(wrap $columns);

my %context = (
    'mod_persistentperl'	=>1,
    'perperl'		=>1,
    'module'		=>1,
    'all'		=>[qw(mod_persistentperl perperl module)],
    'frontend'		=>[qw(perperl mod_persistentperl)],
);

my %ctype = (
    'whole'	=>'i',
    'natural'	=>'i',
    'toggle'	=>'i',
    'str'	=>'c',
);
my @type = sort keys %ctype;

my $INFILE	= "optdefs";
my $INSTALLBIN	= shift;
$columns = 68;		# For the wrap function

die "Usage: $0 installbin-directory\n" unless $INSTALLBIN;


#
# Slurp the optdefs file into @options as a list of hashes
#
my(@options, $curopt);
my $startnew = 1;
open(F, $INFILE) || die "${INFILE}: $!\n";
while (<F>) {
    next if /^#/;
    if (/\S/) {
	chop;
	s/\$INSTALLBIN/$INSTALLBIN/g;
	@_ = split(' ', $_, 2);
	next if @_ < 2;
	if ($startnew) {
	    push(@options, $curopt = {});
	    $startnew = 0;
	}
	$curopt->{$_[0]} .= " " if exists $curopt->{$_[0]};
	$curopt->{$_[0]} .= $_[1];
    } else {
	$startnew = 1;
    }
}
close(F);

# Process/Check the input
for (my $i = 0; $i <= $#options; ++$i) {
    my $opt = $options[$i];

    if (!$opt->{option}) {
	die sprintf("Missing option name in entry #%d in $INFILE file\n", $i+1);
    }
    if (!grep {lc($opt->{type}) eq $_} @type) {
	die "Bad type $opt->{type} for option entry $opt->{option}\n";
    }
    
    if ($opt->{context}) {
	my %c;
	foreach my $c (split(' ', $opt->{context})) {
	    my $val = $context{$c};
	    if (!$val) {
		die "Invalid context name $c for option entry $opt->{option}\n";
	    }
	    foreach my $x (ref($val) ? @$val : $c) {
		$c{$x} = 1;
	    }
	}
	$opt->{context} = \%c;
    }
}

# Sort by name - required for the bsearch call in perperl_opt.c
@options = sort {uc($a->{option}) cmp uc($b->{option})} @options;

#
# Write perperl_optdefs.c
#
&open_file('perperl_optdefs.c');
print "\n#include \"perperl.h\"\n\n";

# Make storage for integer option values
foreach my $opt (@options) {
    if ($ctype{$opt->{type}} eq 'i') {
	printf "static int value_%s = %d;\n",
	    $opt->{option}, $opt->{defval} || 0;
    }
}

print "\nOptRec perperl_optdefs[] = {\n";
foreach my $opt (@options) {
    my @toprint = (
	["\"%s\"",	uc($opt->{option})],
	["%s",		($ctype{$opt->{type}} eq 'c'
	    ? defined($opt->{defval}) ? "\"$opt->{defval}\"" : 'NULL'
	    : "&value_$opt->{option}")
	],
	["'%s'",	$opt->{letter} || "\\0"],
	["OTYPE_%s",	uc($opt->{type})],
	["%d",		0],
	["%d",		length($opt->{option})],
    );
    my $fmt = "\t{\n". join('', map {"\t\t".$_->[0].",\n"} @toprint) . "\t},\n";
    printf $fmt, map {$_->[1]} @toprint;
}
print "};\n";

#
# Write perperl_optdefs.h
#
&open_file('perperl_optdefs.h');
for (my $i = 0; $i <= $#type; ++$i) {
    printf "#define OTYPE_%s %d\n", uc($type[$i]), $i;
}
printf "\n#define PERPERL_NUMOPTS %d\n\n", scalar @options;
for (my $i = 0; $i <= $#options; ++$i) {
    my $opt = $options[$i];
    my $nm = uc($opt->{option});

    printf "#define OPTVAL_%s %s_OPTVAL(perperl_optdefs + %d)\n",
	$nm, $ctype{$opt->{type}} eq 'i' ? 'INT' : 'STR', $i;
    printf "#define OPTREC_%s perperl_optdefs[%d]\n", $nm, $i;
}
print "\n";
print "extern OptRec perperl_optdefs[PERPERL_NUMOPTS];\n\n";
print "#define OPTIDX_FROM_LETTER(var, letter) switch(letter) {\\\n";
for (my $i = 0; $i <= $#options; ++$i) {
    my $opt = $options[$i];

    if ($opt->{letter}) {
	printf "    case '%s': var = $i; break;\\\n", $opt->{letter}, $i;
    }
}
print "    default: var = -1; break;}\n\n";


sub quote { my $x = shift;
    $x =~ s/"/\\"/g;
    return $x;
}

#
# Write mod_persistentperl_cmds.c
#
&open_file("mod_persistentperl_cmds.c");
print "static const command_rec cgi_cmds[] = {\n";
for (my $i = 0; $i <= $#options; ++$i) {
    my $opt = $options[$i];

    next unless $opt->{context} && $opt->{context}{mod_persistentperl};

    printf "    {\n\t\"Persistent%s\", set_option, (void*)(perperl_optdefs + %d), OR_ALL, TAKE1,\n\t\"%s\"\n    },\n",
	$opt->{option}, $i, &quote($opt->{desc});
}
print "{NULL}\n};\n";

#
# Write mod_persistentperl2_cmds.c
#
&open_file("mod_persistentperl2_cmds.c");
print "static const command_rec cgi_cmds[] =\n{\n";
for (my $i = 0; $i <= $#options; ++$i) {
    my $opt = $options[$i];

    next unless $opt->{context} && $opt->{context}{mod_persistentperl};
    
    printf "AP_INIT_TAKE1(\"Persistent%s\", set_option, (void*)(perperl_optdefs+%d), RSRC_CONF,\n     \"%s\"),\n",
	$opt->{option}, $i, &quote($opt->{desc});
}
print "    {NULL}\n};\n";

#
# Write PersistentPerl.pm
#
&open_file('PersistentPerl.pm', 1);
open(I, '<PersistentPerl.src') || die "PersistentPerl.src: $!\n";
my $doprint = 1;
while (<I>) {
    if (/^SP_DIRECTIVE\s+(\S+)\s*$/) {
	my $directive = $1;
	if ($directive eq 'INSERT_OPTIONS_POD_HERE') {
	    &insert_pod_options;
	}
	elsif ($directive eq 'BEGIN_ONLY_IN_SP') {
	    $doprint = !('PersistentPerl' eq 'PersistentPerl');
	}
	elsif ($directive eq 'END_ONLY_IN_SP') {
	    $doprint = 1;
	}
    } else {
	if ($doprint) {print;}
    }
}
close I;

close F;

sub insert_pod_options {
    foreach my $opt (@options) {
	next unless $opt->{context};
	my $cmdline = 'N/A';
	if ($opt->{letter}) {
	    my $arg = '';
	    if ($opt->{type} ne 'toggle') {
		$arg = $ctype{$opt->{type}} eq 'c' ? '<string>' : '<number>'
	    }
	    $cmdline = sprintf("-%s%s", $opt->{letter}, $arg);
	}
	printf "=item %s\n\n", $opt->{option};
	printf "    Command Line    : %s\n", $cmdline;
	if ($opt->{type} ne 'toggle') {
	    my $defval = defined($opt->{defval}) ? $opt->{defval} : '';
	    if ($ctype{$opt->{type}} eq 'c') {
		$defval = "\"$defval\"";
	    }
	    printf "    Default Value   : %s%s\n",
		$defval,
		defined($opt->{defdesc}) ? " ($opt->{defdesc})" : '';
	}
	printf "    Context         : %s\n",
	    join(', ', sort keys %{$opt->{context}});
	printf "\n";
	printf "    Description:\n\n";
	printf "%s\n\n", wrap("\t", "\t", $opt->{desc});
    }
}


sub open_file { my($fname, $use_pound) = @_;
    print STDERR "Writing $fname\n";
    open(F, ">$fname");
    select F;
    my($combeg, $comend) = $use_pound ? ('#', '') : ('/*', '*/');
    print "$combeg Automatically generated by $0 - DO NOT EDIT! $comend\n\n";
}
