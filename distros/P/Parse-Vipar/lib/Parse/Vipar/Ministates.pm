package Parse::Vipar::Ministates;
use Parse::Vipar::Common;
use Parse::Vipar::ViparText qw(makestart makeend find_parent);
use Parse::Vipar::Util;
use Parse::YALALR::Common;

use Tk::English;

BEGIN { *{__PACKAGE__."::new"} = \&Parse::Vipar::subnew; }

use strict;

sub layout_view {
    my $self = shift;
    my ($view) = @_;

    $view->{ministates_l} = $view->{ministates_f}->Label(-text => "States")
      ->pack(-side => TOP);

    $view->{ministates_t} = $view->{ministates_f}->Scrolled('ViparText',
							    -width => PANEWIDTH,
							    -wrap => 'none',
							    -scrollbars => 'osoe')
      ->pack(-side => TOP, -fill => 'y', -expand => 1);

    $self->{_t} = $view->{ministates_t};

    $self->setup_xml();

    return $view;
}

sub setup_xml {
    my ($self) = @_;
    my $t = $self->{_t};
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};

    $t->tagLink("lookahead", undef, -alink => undef);
    $t->tagLink("sym", undef, -alink => undef, -underline => 0);

    ######## LOOKAHEADS ########
    $t->map->{pre}->{lookahead} = sub {
	my ($xmltag) = @_;

	my ($state, $itemidx) = ($xmltag->{state}, $xmltag->{item});

	if (!defined $itemidx) {
	    my $parent = find_parent($xmltag, 'item')
	      or die "No parent item found";
	    $itemidx = $parent->{id};
	}

	if (!defined $state) {
	    my $parent = find_parent($xmltag, 'wholestate')
	      or die "No parent item found";
	    $state = $parent->{id};
	}

	my $kernel = $parser->{states}->[$state];
	my ($item) = grep($_->{GRAMIDX}==$itemidx, @{$kernel->{items}});
        my @la = $parser->{symmap}->get_indices($item->{LA});

	my @tags = ("la_${state}_$item->{GRAMIDX}", "lookahead");
	$xmltag->{body} = [ makestart(@tags),
#			    @{$xmltag->{body}},
			    "LOOKAHEAD",
			    makeend(@tags) ];
	bindStuff($t, $tags[0],
                  sub { $vipar->view_symbols(@la); },
                  undef,
                  sub { $vipar->select_symbols(@la); },
                  sub { $vipar->restrict_symbols(@la); });
    };

    ########## SYMBOLS ########
    $t->map->{pre}->{sym} = sub {
	my ($xmltag) = @_;
	my $sym = $xmltag->{id};

	my @tags = ("sym_$sym", "sym");
	$xmltag->{body} = [ makestart(@tags),
			    @{$xmltag->{body}},
			    makeend(@tags) ];

	bindStuff($t, "sym_$sym",
                  sub { $vipar->view_symbols($sym); },
                  undef,
                  sub { $vipar->select_symbols($sym); },
                  sub { $vipar->restrict_symbols($sym); });
    };
}

sub insert_state {
    my ($self, $parser, $t, $kernel) = @_;
    my $grammar = $parser->{grammar};
    my $vipar = $self->{parent};
    my $nil = $parser->{nil};

    my $state = $kernel->{id};
    print "Inserting state $state...";
    if (!defined $::timer) {
	$::lastmark = $::timer = time;
	print "starting timer\n";
    } else {
	my $now = time;
	my $elapsed = $now - $::lastmark;
	my $cumulative = $now - $::timer;
	print "$elapsed sec total $cumulative sec\n";
	$::lastmark = $now;
    }
#      $t->xmlinsert('end', $parser->dump_kernel($kernel, 'xml')."\n",
#  		  "wholestate_$state");

    $t->xmlinsert('end', "<wholestate id=$state><state id=$state>".$E{$parser->dump_kernel($kernel)}."</state>\n</wholestate>");

    $t->insert('end', "\n");

    bindStuff($t, "wholestate_$state",
	      sub { activate($t, "wholestate_$state"); },
	      undef,
	      sub { $vipar->select_state($state) },
	      undef);
    $t->tagLower("wholestate_$state");
}

sub fillin {
    my $self = shift;
    my $vipar = $self->{parent};
    my ($states) = @_;

    my $parser = $vipar->{parser};
    $states ||= $parser->{states};

    my $t = $self->{_t};

    $t->delete("1.0", "end");
    foreach my $state (@$states) {
	$self->insert_state($parser, $t, $state);
    }

#      my $dump = "/opt/usr/tmp/TEXTDUMP.log";
#      open(DUMPFH, ">$dump") or die "Creating $dump: $!";
#      print DUMPFH join("\n", $t->dump('1.0')), "\n";
#      close(DUMPFH);
}

sub view {
    my $self = shift;
    activate($self->{_t}, map { "wholestate_$_" } @_);
}

sub select {
    my $self = shift;
    choose($self->{_t}, map { "wholestate_$_" } @_);
}

sub restrict {
    my $self = shift;
    my ($state) = @_;
}

sub view_rule {
    my $self = shift;
    my ($rule) = @_;
    activate($self->{_t}, "withrule_$rule");
}

sub select_rule {
    my $self = shift;
    my ($rule) = @_;
    choose($self->{_t}, "withrule_$rule");
}

sub view_symbols {
    my $self = shift;
    activate($self->{_t}, map { "sym_$_" } @_);
}

sub select_symbols {
    my $self = shift;
    choose($self->{_t}, map { "itemwith_$_" } @_);
}

1;
