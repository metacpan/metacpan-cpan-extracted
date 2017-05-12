package Parse::Vipar::Symbols;
require Parse::Vipar::ViparText;
use Parse::Vipar::Util;
use Tk::English;

*{__PACKAGE__."::new"} = \&Parse::Vipar::subnew;

use strict;

sub layout_view {
    my $self = shift;
    my ($view) = @_;

    $view->{symbols_l} = $view->{symbols_f}->Label(-text => "Symbols View")
      ->pack(-side => TOP);

    $view->{symbols_t} = $view->{symbols_f}->Scrolled('ViparText',
						      -width => 30,
						      -scrollbars => "oe")
      ->pack(-side => TOP, -fill => 'y', -expand => 1);

    $self->{_t} = $view->{symbols_t};

    # Since these things are always the whole line, make selected stuff
    # override active stuff. Hm... could also make selected be the whole
    # line and active be just the symbol...?
    $self->{_t}->tagLower("active", "selected");

    return $view;
}

sub compare_prec {
    my ($parser, $a, $b) = @_;
    my $pa = $parser->{precedence}->[$a];
    my $pb = $parser->{precedence}->[$b];
    return -1 if !defined $pa;
    return  1 if !defined $pb;
    return $pa->[0] <=> $pb->[0]
                    ||
           $pa->[1] cmp $pb->[1];
    # left < nonassoc < right
}

sub fillin {
    my $self = shift;
    my $vipar = $self->{parent};
    my (@symbols) = @_;

    my $parser = $vipar->{parser};

    my (@terms, @nts, @codes);

    my $t = $self->{_t};
    my $default_bg = $t->configure('-background')->[3];
    $t->delete('1.0', 'end');

    if (@symbols == 0) {
	push(@symbols, @{ $parser->{tokens} });
	push(@symbols, @{ $parser->{nonterminals} });
    } else {
        $t->insert('1.0', "<View All>", "viewall", "\n\n");
        $t->tagCenterLink("viewall", sub { $vipar->unrestrict() });
    }

    @terms = grep { $parser->is_token($_) } @symbols;
    @nts = grep { $parser->is_nonterminal($_) && ! $parser->is_codesym($_) } @symbols;
    @codes = grep { $parser->is_codesym($_) && !$parser->{end_action_symbols}->{$_} } @symbols;

    $t->insert('end', "NONTERMINALS\n", "title");
    foreach my $sym (@nts) {
	$t->tagConfigure("sym_$sym", -foreground => "blue");
	$t->insert('end', $parser->dump_sym($sym),
                   [ "symbol", "sym_$sym", "symline_$sym" ]);
	$t->insert('end', "\n", "symline_$sym");
    }
    $t->insert('end', "(no nonterminals selected)\n")
        if (@nts == 0);

    my $width = $t->cget('-width');
    $t->insert('end', "\n", [], "TERMINALS\n", "title");
    @terms = sort { compare_prec($parser, $a, $b) } @terms;
    foreach my $sym (@terms) {
        my $str = $parser->dump_sym($sym);
        if (defined $parser->{precedence}->[$sym]) {
            my $gap = $width - 11 - length($str);
            if ($gap < 0) {
                $str .= "\n" . " " x ($width - 11);
            } else {
                $str .= " " x $gap;
            }
            $str .= sprintf("% 2d %s", @{ $parser->{precedence}->[$sym] });
        }

	$t->insert('end', $str, [ "symbol", "sym_$sym", "symline_$sym" ],
                   "\n");
    }
    $t->insert('end', "(no terminals selected)\n")
        if (@terms == 0);

    $t->insert('end', "\n", [], "DUMMY SYMBOLS\n", "title")
        if (@codes);
    foreach my $sym (@codes) {
	$t->tagConfigure("sym_$sym", -foreground => "blue");
	$t->insert('end', $parser->dump_sym($sym),
                   [ "symbol", "sym_$sym", "symline_$sym" ]);
	$t->insert('end', "\n", "symline_$sym");
    }

    $t->tagConfigure("symbol", -foreground => "blue");
    foreach my $sym (@symbols) {
	$vipar->bind_symbol($t, "sym_$sym", $sym);
    }

    $t->tagConfigure("title", -relief => 'groove', -borderwidth => 1);
}

sub view {
    my $self = shift;
    activate($self->{_t}, map { "symline_$_" } @_);
}

sub select {
    my $self = shift;
    choose($self->{_t}, map { "symline_$_" } @_);
}

sub restrict {
    my $self = shift;
    $self->fillin(@_);
    activate($self->{_t}, map { "symline_$_" } @_);
}

1;
