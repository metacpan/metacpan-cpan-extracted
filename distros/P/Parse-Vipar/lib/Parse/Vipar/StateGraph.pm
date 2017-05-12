# -*- cperl -*-

package Parse::Vipar::StateGraph;
use Parse::Vipar::Util;
use Parse::Vipar::Graph;
use Parse::Vipar::Common;

BEGIN { *{__PACKAGE__."::new"} = \&Parse::Vipar::subnew; }

use strict;
use Tk::English;

sub layout_view {
    my $self = shift;
    my ($view) = @_;

    $view->{graph_l} = $view->{graph_f}->Label(-text => "State Graph")
      ->pack(-side => TOP, -fill => 'y');

    my $c = $view->{_c} = $view->{graph_c} =
      $view->{graph_f}->Scrolled('Canvas',
				 -height => int(SCREENHEIGHT*2/3))
	->pack(-side => TOP, fill => 'both', -expand => 1);

    $self->{_c} = $c;

    return $view;
}

sub fillin {
    my $self = shift;
    my $vipar = $self->{parent};

    my $parser = $vipar->{parser};
    my $grammar = $parser->{grammar};
    my $canvas = $self->{_c};

    print "Initializing graph view...\n";
    my $model = Parse::Vipar::Graph->new();
    $self->{model} = $model;
    my $view = Parse::Vipar::Graph::View->init($canvas, $model);
    $self->{view} = $view;

    print "Constructing graph...\n";
    if (@{$parser->{states}} > 200) {
	print "Aborting construction. Too many states. Wouldn't look good anyway.\n";
	return;
    }

    $model->newnode($_) for (0 .. $#{ $parser->{states} });
    for my $state (@{ $parser->{states} }) {
        for my $tok (0 .. @{ $state->{actions} }) {
            my $action = $state->{actions}->[$tok];
            next if !defined $action;
            next if ref $action;
            $model->addedge($state->{id}, $action, $parser->dump_sym($tok));
        }
    }
    print "Laying out graph...\n";
    $model->layout();

    print "Drawing graph...\n";
    $view->draw();
    print "Binding graph...\n";
    $view->bind();

    print "Training StateGraph object...\n";
    $self->train();
    print "Done with StateGraph::fillin()\n";
}

# Teach the graph object to generate and react to events
sub train {
    my ($self) = @_;
    my $vipar = $self->{parent};
    my $canvas = $self->{view}->{c};
    foreach my $node ($self->{model}->nodes()) {
        $canvas->bind("node_$node->{id}", "<1>",
                      sub { $vipar->select_state($node->{id}) });
    }
}

sub select_state {
    my ($self, $state) = @_;
    my $canvas = $self->{view}->{c};
    my $oncolor = '#ff9900';
    my $offcolor = 'black';
    $canvas->itemconfigure("selected_text", -fill => $offcolor);
    $canvas->itemconfigure("selected_oval", -outline => $offcolor);
    $canvas->dtag("selected_text");
    $canvas->dtag("selected_oval");
    $canvas->addtag("selected_text", "withtag", "node_text_$state");
    $canvas->addtag("selected_oval", "withtag", "node_oval_$state");
    $canvas->itemconfigure("selected_text", -fill => $oncolor);
    $canvas->itemconfigure("selected_oval", -outline => $oncolor);
}

1;
