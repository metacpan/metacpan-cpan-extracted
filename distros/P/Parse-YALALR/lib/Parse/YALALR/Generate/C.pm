package Parse::YALALR::Generate::C;

use Parse::YALALR::Build;
use strict;

sub new {
    my ($class, $parser) = @_;
    bless { parser => $parser }, $class;
}

sub write_table {
    my $self = shift;
    my ($out, $tablevarname) = @_;

    my $nsyms = @{$self->{parser}->{tokens}} + @{$self->{parser}->{nonterminals}};

    print $out "static int $tablevarname\[]\[$nsyms] = {\n";
    my $first = 1;
    foreach (@{$self->{table}}) {
	if (!$first) {
	    print $out ",\n    { ", join(", ", @$_), " }";
	} else {
	    print $out "    { ", join(", ", @$_), " }";
	}
	undef $first;
    }
    print $out "\n};\n";
}

sub generate_table {
    my $self = shift;
    my Parse::YALALR::Build $parser = $self->{parser};
    
    my $nsyms = @{$parser->{tokens}} + @{$parser->{nonterminals}};
    my @table;

    my %revrules;
    my $i = 0;
    for (@{$parser->{rules}}) {
	$revrules{$_} = $i;
	$i++;
    }

    for my $state (@{$parser->{states}}) {
	my $statenum = $state->{id} + 1;
	my $symnum = 0;
	for my $action (@{$state->{actions}}) {
	    if (!defined $action) {
		$table[$statenum][$symnum] = 0; # Error
	    } elsif (ref $action) {
		# Reduce
		print "action[0] = $action->[0]\n";
		$table[$statenum][$symnum] = -($revrules{$action->[0]} + 1);
	    } else {
		# Shift
		$table[$statenum][$symnum] = $action + 1;
	    }
	} continue {
	    $symnum++;
	};
	
	for my $i ($symnum .. $nsyms - 1) {
	    $table[$statenum][$i] = 0;
	}
    }

    $table[0] = [ (0) x $nsyms ];

    $self->{table} = \@table;
}

sub write_rules {
    my $self = shift;
    my ($out, $rulevarbase) = @_;
    my $parser = $self->{parser};
    my $grammar = $parser->{grammar};
    my $nil = $parser->{nil};

    my @sizes;
    my @lhses;
    my @rules;

    my $size;
    my $i = 0;
    foreach (@$grammar) {
	if (!defined $size) {
	    push(@lhses, $_);
	    push(@rules, $i);
	    $size = 0;
	} elsif ($_ == $nil) {
	    push(@sizes, $size);
	    undef $size;
	} else {
	    $size++;
	}
    } continue {
	$i++;
    }

    print $out "static int ${rulevarbase}_size[] = {\n";
    print $out "0,\n";
    print $out join(", ", @sizes);
    print $out "\n};\n\n";

    print $out "static int ${rulevarbase}_symbol[] = {\n";
    print $out "0,\n";
    print $out join(", ", @lhses);
    print $out "\n};\n\n";

    print $out "static char* ${rulevarbase}_desc[] = {\n";
    print $out "\"INTERNAL ERROR RULE DESCRIPTION\",\n";
    foreach (@rules) {
	print $out '"'.$parser->dump_rule($_).'",'."\n";
    }
    print $out "\"\"\n};\n\n";
}

sub write_valtype {
    my $self = shift;
    my ($out, $varname) = @_;
    print $out "typedef int VALTYPE;\n";
}

sub write_symboldescs {
    my $self = shift;
    my ($out, $varname) = @_;

    my $first = 1;
    print $out "static char* $varname\[\] = {\n";
    for my $sym (@{$self->{parser}->{symmap}->{values}}) {
	$sym =~ s/\\/\\\\/g;
	$sym =~ s/\"/\\\"/g;
	print $out ",\n" unless $first;
	$first = 0;
	print $out "    \"$sym\"";
    }
    print $out "};\n\n";
}

sub write_tokmap {
    my $self = shift;
    my ($out, $varname) = @_;

    print $out "static int $varname\[\] = {\n";
    my @vals;
    for my $sym (@{$self->{parser}->{symmap}->{values}}) {
	if (substr($sym, 0, 1) eq "'") {
	    $vals[ord(substr($sym, 1, 1))] = $self->{parser}->{symmap}->get_index($sym);
	}
    }

    my $first = 1;
    for (0..$#vals) {
	print $out ",\n    " unless $first;
	$first = 0;
	if (defined $vals[$_]) {
	    print $out "$vals[$_]";
	} else {
	    print $out "-1";
	}
    }
    print $out "};\n\n";
}

sub write_all {
    my $self = shift;
    my ($out) = @_;
    print $out "static int EOF_token = ", $self->{parser}->{end}, ";\n";
    $self->write_table($out, "table");
    $self->write_rules($out, "rule");
    $self->write_valtype($out, "VALTYPE");
    $self->write_symboldescs($out, "symbol_desc");
    $self->write_tokmap($out, "tokmap");
}

sub write_header {
    my $self = shift;
    my ($out) = @_;

    for my $sym (@{$self->{parser}->{symmap}->{values}}) {
	next if substr($sym, 0, 1) eq "'";
	next if substr($sym, 0, 1) eq "<";
	next if substr($sym, 0, 1) eq "@";
	my $symval = $self->{parser}->{symmap}->get_index($sym) + 256;
	print $out "#define $sym $symval\n";
    }
}

1;
