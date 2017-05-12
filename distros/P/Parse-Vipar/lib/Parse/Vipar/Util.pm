package Parse::Vipar::Util;

use strict;

BEGIN {
    use Exporter ();
    use vars       qw($VERSION @ISA @EXPORT);
    @ISA         = qw(Exporter);
    @EXPORT      = qw(&activate &choose &narrow
                      &bindStuff &tagged_item_body);
}

sub activate {
    my ($t, @tags) = @_;
    $t->tagRemove("active", "1.0", "end");
    $t->tagAdd("active", map { $t->tagRanges($_) } @tags);
}

sub choose {
    my ($t, @tags) = @_;
    $t->tagRemove("selected", "1.0", "end");
    $t->tagAdd("selected", map { $t->tagRanges($_) } @tags);
    eval { $t->see("selected.first"); };
}

sub narrow {
    my ($t, @tags) = @_;
    $t->tagRemove("restricted", "1.0", "end");
    $t->tagAdd("restricted", map { $t->tagRanges($_) } @tags);
}

sub bindStuff {
    my ($t, $tag, $enter_cb, $leave_cb, $b1_cb, $db1_cb) = @_;

    $t->tagBind($tag, "<Any-Enter>", $enter_cb || sub{});
    $t->tagBind($tag, "<Any-Leave>", $leave_cb || sub {});
    $t->tagBind($tag, "<Button-1>", $b1_cb || sub {});
    $t->tagBind($tag, "<Double-Button-1>", $db1_cb || sub {});
}

########################################################

sub tagged_item_body {
    my ($parser, $idx) = @_;
    my $grammar = $parser->{grammar};
    my $nil = $parser->{nil};

    my (@str, @tags);
    my @symbols;

    my $i = $parser->get_rule($idx);

    # LHS ->
    my $lhs = $grammar->[$i];
    push(@symbols, $lhs);
    push(@str, $parser->dump_sym($lhs));
    $tags[$#str] = [ "symbol_$lhs" ];
    push(@str, " -> ");

    # SYM SYM SYM . SYM
    while (1) {
        my $sym = $grammar->[++$i];
        push(@str, ". ") if $idx == $i;
        last if $sym == $nil;
        push(@str, $parser->dump_sym($sym));
        $tags[$#str] = [ "symbol_$sym" ];
        push(@str, " ");
    }

    # Trim trailing space
    chomp($str[-1]);

    # Tag with item_N
    for (0 .. $#str) {
        push(@{ $tags[$_] }, "item_$idx");
    }

    return \@str, \@tags, \@symbols;
}

1;
