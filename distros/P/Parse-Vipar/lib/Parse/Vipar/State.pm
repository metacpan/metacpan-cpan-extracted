# -*- cperl -*-

package Parse::Vipar::State;
use Parse::Vipar::Common;
use Parse::Vipar::ViparText qw(makestart makeend);
use Parse::Vipar::Util;

BEGIN { *{__PACKAGE__."::new"} = \&Parse::Vipar::subnew; }

use strict;
use Tk::English;
use Tk::Font;

sub layout_view {
    my $self = shift;
    my ($view) = @_;

    $view->{state_l} = $view->{state_f}->Label(-text => "Exploded State View")
      ->pack(-side => TOP);

    print "HEIGHT=".int(SCREENHEIGHT/3)."\n";

    $view->{state_t} = $view->{state_f}->Scrolled('ViparText',
						  -scrollbars => 'osoe',
						  -wrap => 'none')
      ->pack(-side => TOP, -fill => 'both', -expand => 1);

    $self->{_t} = $view->{state_t};

    $self->width(PANEWIDTH);
    $self->height(int(SCREENHEIGHT/3));

    $self->setup_xml();

    return $view;
}

sub setup_xml {
    my ($self) = @_;
    my $t = $self->{_t};
    my $vipar = $self->{parent};

    $t->map->{pre}->{lookahead} = sub {
	my ($tagged) = @_;
	my @tags = ("lookahead",
		    $t->makeTag('lookahead',
				state => $tagged->{state},
				item => $tagged->{item},
				token => $tagged->{token}));
	if (defined $tagged->{ultimate}) {
	    my $kernel = $vipar->{parser}->{states}->[$tagged->{state}];
	    my ($ultimate_kitem) =
	      grep($_->{GRAMIDX}==$tagged->{ultimate}, @{$kernel->{items}});
	    $vipar->data->{$tags[1]} = [ undef, undef, undef, $ultimate_kitem];
	}
	$tagged->{body} = [ makestart(@tags),
			    @{$tagged->{body}},
			    makeend(@tags) ];
	$t->tagLink($tags[1]);
    };

    $t->tagBind('lookahead', '<1>', sub {
		    my %info = $t->getNumericalAttrs('lookahead');
		    $vipar->why_lookahead(@info{'state','item','token'});
		});
}

sub cwidth {
    my $self = shift;
    my $t = $self->{_t};
    my ($setting) = @_;

    if (defined $setting) {
	$t->configure(-width => $setting);
    } else {
	return $t->cget('-width') / $t->cget('-font')->measure("0");
    }
}

sub width {
    my $self = shift;
    my $t = $self->{_t};
    my ($setting) = @_;

    if (defined $setting) {
	$t->configure(-width => int($setting / $t->cget('-font')->measure("0")));
    } else {
	return $t->cget('-width');
    }
}

sub cheight {
    my $self = shift;
    my $t = $self->{_t};
    my ($setting) = @_;

    if (defined $setting) {
	$t->configure(-height => $setting);
    } else {
	return $t->cget('-height') / $t->cget('-font')->metrics('-linespace');
    }
}

sub height {
    my $self = shift;
    my $t = $self->{_t};
    my ($setting) = @_;

    if (defined $setting) {
	$t->configure(-height => int($setting / $t->cget('-font')->metrics('-linespace')));
    } else {
	return $t->cget('-height');
    }
}

# Sort order: all kernel items followed by all generated items.
# Within the items of the same type, sort by grammar index.
sub compare_xitems {
    my $aa = (exists $a->{parent0} ? 1 : 0);
    my $bb = (exists $b->{parent0} ? 1 : 0);
    return ($aa - $bb) if $aa != $bb;
    return $a->{item} <=> $b->{item};
}

sub numberof ($$) {
    return $_[1]." ".$_[0].($_[1] == 1 ? "" : "s");
}

sub fillin {
    my $self = shift;
    my $vipar = $self->{parent};
    my ($id) = @_;
    $id = 0 if !defined $id;

    my $parser = $vipar->{parser};
    my $builder = $vipar->{builder};
    my $grammar = $parser->{grammar};
    my $t = $self->{_t};

    $t->delete("1.0", "end");

    my $state = $parser->{states}->[$id];
    my $xstate = $builder->expand_state($state);

    $t->tagBind('lookahead', '<Any-Enter>',
		sub {
		    $t->configure(-cursor => 'hand2');
		    my %info = $t->getNumericalAttrs('lookahead');
		});

    $t->tagBind('lookahead', '<Any-Leave>',
		sub {
		    $t->configure(-cursor => ($t->configure('-cursor'))[3]);
		});

    $t->xmlinsert('end', $parser->dump_xstate($state, $xstate, 'xml'));
}

sub select {
    my $self = shift;
    my ($state) = @_;
    $self->fillin($state);
}

sub unrestrict {
    my $self = shift;
    narrow($self->{_t});
}

1;
