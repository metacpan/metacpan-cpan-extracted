package Parse::Vipar::Rules;

use Parse::Vipar::ViparText;
use Parse::Vipar::Util;
use Parse::Vipar::Common;
use Parse::YALALR::Common qw(makestart makeend);

BEGIN { *{__PACKAGE__."::new"} = \&Parse::Vipar::subnew; }

use strict;

sub layout_view {
    my $self = shift;
    my ($view) = @_;

    $view->{rules_l} = $view->{rules_f}->Label(-text => "Rules View")
      ->pack(-side => 'top');
    
    $view->{rules_t} = $view->{rules_f}->Scrolled('ViparText',
						  -width => PANEWIDTH,
						  -scrollbars => "oe")
      ->pack(-side => 'top');

    $view->{rules_t}->configure(-cursor => 'top_left_arrow');
    $self->{_t} = $view->{rules_t};

    return $view;
}

sub unrestrict {
    my $self = shift;
    $self->fillin(undef, undef);
}

sub rule_pre_handler {
    my ($tagged, $parser) = @_;
    my $id = $tagged->{id};
    $tagged->{body} = [ makestart("wholerule_$id"),
                        makestart("rule_$id"),
                        "Rule $tagged->{rulenum}: ",
                        makeend("rule_$id"),
                        @{$tagged->{body}},
                        makeend("wholerule_$id") ];
}

sub makestart { return bless [ @_ ], 'start' }
sub makeend { return bless [ @_ ], 'end' }

sub fillin {
    my $self = shift;
    my ($rules) = @_;

    my $t = $self->{_t};
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    my $grammar = $parser->{grammar};

    $rules ||= $parser->{rules};
    
    $t->delete("1.0", "end");
    my $default_bg = $t->configure('-background')->[3];

    local $t->map->{pre}->{rule} = \&rule_pre_handler;

    my %symbols;
    my $str;
    foreach my $ruleidx (@$rules) {
	my $lhs = $grammar->[$ruleidx];

	my @symbols = ($lhs);
	my $str = '';

        my $rulenum = $parser->{rulenum}->{$ruleidx};
        $str .= "<rule id=$ruleidx rulenum=$rulenum>";
        $str .= "<lhs><sym id=$lhs>$E{$parser->dump_sym($lhs)}</sym></lhs>";
        $str .= " &arrow; ";

	my $idx = $ruleidx;
	while ((my $rhs = $grammar->[++$idx]) != $parser->{nil}) {
            my $escsym = $E{$parser->dump_sym($rhs)};
            $str .= "<sym id=$rhs>$escsym</sym> ";
            push(@symbols, $rhs);
	}

	if (@symbols == 1) {
            $str .= "/*empty*/";
	} else {
	    chop($str);
	}

	my $prec = $parser->{rule_precedence}->[$ruleidx];
        $str .= "<prec id=$prec->[0]>(prec $prec->[0])</prec>"
            if defined $prec;
        $str .= "</rule>\n";

	# Do the actual insertion
        $t->xmlinsert('end', $str, [ map { "rulewith_$_" } @symbols ]);

	$symbols{$_} = 1 foreach (@symbols);

	bindStuff($t, "rule_$ruleidx",
		  sub { $vipar->view_rule($ruleidx); },
                  undef,
		  sub { $vipar->select_rule($ruleidx); },
		  undef);
    }

    for my $symbol (keys %symbols) {
	$t->tagConfigure("sym_$symbol", -foreground => 'blue');
	bindStuff($t, "sym_$symbol",
		  sub { $vipar->view_symbols($symbol); },
		  undef,
		  sub { $vipar->select_symbols($symbol); },
		  sub { $vipar->restrict_symbols($symbol); });
    }
}

sub view {
    my $self = shift;
    my ($rule) = @_;
    activate($self->{_t}, "wholerule_$rule");
}

sub select {
    my $self = shift;
    my ($rule) = @_;
    choose($self->{_t}, "wholerule_$rule");
}

sub view_symbols {
    my $self = shift;
    activate($self->{_t}, map { "sym_$_" } @_);
}

# User is interested in seeing this one symbol. (NOT restricting the view
# to just that symbol, though)
sub select_symbols {
    my $self = shift;
    choose($self->{_t}, map { "rulewith_$_" } @_);
}

sub restrict_symbols {
    my $self = shift;
    my $vipar = $self->{parent};
    my (@symbols) = @_;

    my $grammar = $vipar->{parser}->{grammar};
    my $nil = $vipar->{parser}->{nil};

    my %symbols;
    $symbols{$_} = 1 foreach (@symbols);

    my %rules;
    for (0 .. $#$grammar) {
	if (exists $symbols{$grammar->[$_]}) {
	    my $i = $_;
	    --$i while ($i >= 0) && ($grammar->[$i] != $nil);
	    $i++;

	    $rules{$i} = $grammar->[$_];
	}
    }

    my $t = $self->{_t};
    $self->fillin($t, [ sort keys %rules ]);

    $t->insert('1.0', "<View All>", "viewall", "\n");
    $t->tagCenterLink("viewall", sub { $vipar->unrestrict() });

    $self->view_symbols(@symbols);
}

1;
