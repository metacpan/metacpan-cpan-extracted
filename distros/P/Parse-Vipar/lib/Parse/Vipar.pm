# -*- cperl -*-
use lib '..';

# find . -name '*.pm' | xargs etags -r '/package \(.+\);/\1/' -r '/use [a-zA-Z:]+/'

package Parse::Vipar;

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

use Tk;

# Preload things to keep perly.y from getting them
use Tk::Menu;
use Tk::Menubutton;

use Parse::Vipar::Common;
use Parse::YALALR::Common;
use Parse::YALALR::Build;
use Parse::Vipar::Ministates;
use Parse::Vipar::Rules;
use Parse::Vipar::Symbols;
use Parse::Vipar::State;
use Parse::Vipar::Shell;
use Parse::Vipar::ParseView;
use Parse::Vipar::StateGraph;

use Tk::English;

#  BEGIN {
#      $SIG{__WARN__} = sub {
#          use Carp;
#          confess @_;
#      }
#  }

sub new {
    my ($class, %args) = @_;
    die "Currently need to start with a parser"
      if ! $args{parser};
    my $self = bless { window => MainWindow->new(-height => SCREENHEIGHT),
		       data => {},
                       %args }, (ref $class || $class);

    $self->{step_window} = $self->{window}->Toplevel(-height => SCREENHEIGHT);

    # View window
    $self->{state} = Parse::Vipar::State->new($self);
    $self->{stategraph} = Parse::Vipar::StateGraph->new($self);
    $self->{ministates} = Parse::Vipar::Ministates->new($self);
    $self->{rules} = Parse::Vipar::Rules->new($self);
    $self->{symbols} = Parse::Vipar::Symbols->new($self);

    push(@{ $self->{view_children} },
	 $self->{state},
         $self->{stategraph},
	 $self->{ministates},
	 $self->{rules},
	 $self->{symbols});

    print "Laying out parser view...\n";
    $self->{view} = $self->layout_parser_view($self->{window});

    # Step window
    $self->{shell} = Parse::Vipar::Shell->new($self);
    $self->{parsetree} = Parse::Vipar::ParseView->new($self);

    push(@{ $self->{step_children} },
         $self->{shell},
         $self->{parsetree});

    print "Laying out step window...\n";
    $self->{step} = $self->layout_step_window($self->{step_window});

    print "Done creating Vipar object\n";
    return $self;
}

sub subnew {
    my ($class, $vipar, %opts) = @_;
    die "Must give parent object" if ! UNIVERSAL::isa($vipar, __PACKAGE__);
    return bless { parent => $vipar, %opts }, (ref $class || $class);
}

sub data { $_[0]->{data} }

sub fillin {
    my $self = shift;

    foreach (@{ $self->{view_children} }) {
	print "Filling in $_...\n";
	$_->fillin();
    }
}

sub main { $_[0]->{window} }

sub layout_parser_view {
    my $self = shift;
    my ($win) = @_;
    
    my $view = {};

    # Set up the overall layout
    $view->{topline_f} = $win->Frame()
        ->pack(-side => TOP, -fill => 'x');
    $view->{main_f} = $win->Frame()
        ->pack(-side => TOP, -fill => 'both', -expand => 1);
    $view->{statusline_f} = $win->Frame()
        ->pack(-side => TOP, -fill => 'x');

    # Left pane
    $view->{left_f} = $view->{main_f}->Frame()
        ->pack(-side => LEFT, -fill => 'both', -expand => 1);
    $view->{state_f} = $view->{left_f}->Frame()
        ->pack(-side => TOP, -fill => 'x');
    $view->{graph_f} = $view->{left_f}->Frame()
        ->pack(-side => TOP, -fill => 'both', -expand => 1);

    # Middle pane
    $view->{ministates_f} = $view->{main_f}->Frame()
        ->pack(-side => LEFT, -fill => 'y');

    # Right pane
    $view->{right_f} = $view->{main_f}->Frame()
	->pack(-fill => 'y', -expand => 1);
    $view->{rules_f} = $view->{right_f}->Frame()
        ->pack(-side => TOP, -fill => 'both', -expand => 1);
    $view->{symbols_f} = $view->{right_f}->Frame()
        ->pack(-side => TOP, -fill => 'both', -expand => 1);
    
    $self->layout_menubar($view);
    $self->layout_statusline($view);

    for my $child (@{ $self->{view_children} }) {
	$child->layout_view($view);
    }

    return $view;
}

sub layout_step_window {
    my $self = shift;
    my ($win) = @_;
    
    my $info = $win->{info} = {};

    # Set up the overall layout
    $info->{topline_f} = $win->Frame()
        ->pack(-side => TOP, -fill => 'x');
    $info->{parse_f} = $win->Frame()
        ->pack(-side => LEFT, -fill => 'y');
    $info->{shell_f} = $win->Frame()
        ->pack(-side => RIGHT, -fill => 'y');

    for my $child (@{ $self->{step_children} }) {
	$child->layout($info, $win);
    }

    return $info;
}

sub layout_menubar {
    my $self = shift;
    my ($view) = @_;

    $view->{topline_m} = $view->{topline_f}->Menubutton(-text => "Pulldown")
      ->pack(-anchor => 'w', -fill => 'x');

    return $view;
}

sub popup_debug_window {
    my $top = Toplevel->new();
    $top->Entry()->pack();
}

sub layout_statusline {
    my $self = shift;
    my ($view) = @_;

    $view->{statusline_l} = $view->{statusline_f}->Label(-text => "Status Line")
      ->pack();

    return $view;
}

sub status {
    my $self = shift;
    $self->{view}->{statusline_l}->configure(-text => shift());
}

################ CONTROLS ######################

######## GENERAL ###########

sub bind_symbol {
    my ($self, $t, $tag, $symbol) = @_;

    $t->tagBind($tag, "<Any-Enter>",
		sub { $self->view_symbols($symbol); });
    $t->tagBind($tag, "<Any-Leave>", sub { });
    $t->tagBind($tag, "<Button-1>",
		sub { $self->select_symbols($symbol); });
    $t->tagBind($tag, "<Double-Button-1>",
		sub { $self->restrict_symbols($symbol) });
}

sub bind_object {
    my ($self, $obj, $t, $tag, $id) = @_;

    $t->tagBind($tag, "<Any-Enter>",
		sub { $obj->view($id); });
    $t->tagBind($tag, "<Any-Leave>", sub { });
    $t->tagBind($tag, "<Button-1>",
		sub { $obj->select($id); });
    $t->tagBind($tag, "<Double-Button-1>",
		sub { $obj->restrict($id) });
}

######## SYMBOLS #########

sub view_symbols {
    my $self = shift;
    my (@symbols) = @_;
    my $view = $self->{view};

    $self->{rules}->view_symbols(@symbols);
    $self->{symbols}->view(@symbols);
    $self->{ministates}->view_symbols(@symbols);
}

sub select_symbols {
    my $self = shift;
    my (@symbols) = @_;
    my $view = $self->{view};
    my $n = @symbols;
    $self->status("Selecting $P{'symbol', $n} "
                  .join(" ", $self->{parser}->dump_sym(@symbols)));

    $self->{rules}->select_symbols(@symbols);
    $self->{symbols}->select(@symbols);
}

sub restrict_symbols {
    my $self = shift;
    my (@symbols) = @_;
    my $view = $self->{view};
    my $n = @symbols;
    $self->status("Restricting view to $P{'symbol', $n} "
                  .join(" ", $self->{parser}->dump_sym(@symbols)));

    $self->{rules}->restrict_symbols(@symbols);
    $self->{symbols}->restrict(@symbols);
}

######## RULES #########

sub view_rule {
    my $self = shift;
    my ($rule) = @_;
    my $view = $self->{view};
    $self->status("Viewing rule #$rule");

    $self->{ministates}->view_rule($rule);
    $self->{rules}->view($rule);
}

sub select_rule {
    my $self = shift;
    my ($rule) = @_;
    my $view = $self->{view};
    $self->status("Selecting rule #$rule");

    $self->{ministates}->select_rule($rule);
    $self->{rules}->select($rule);
}

######## ITEMS #########

sub select_item {
    my $self = shift;
    my ($item) = @_;
    my $view = $self->{view};
    $self->status("Selecting item ".$self->{parser}->dump_item($item));
}

######## STATES #########

sub view_state {
    my $self = shift;
    my ($state) = @_;
    my $view = $self->{view};

    $self->{ministates}->view($state);
}

sub select_state {
    my $self = shift;
    my ($state) = @_;
    my $view = $self->{view};
    $self->status("Selecting state #$state");
    $self->{ministates}->select($state);
    $self->{state}->select($state);
    $self->{stategraph}->select_state($state);
}

###############################################

sub unrestrict {
    my ($self) = @_;
    $self->{rules}->unrestrict();
    $self->{symbols}->restrict();
    $self->{state}->unrestrict();
}

############ ACTIONS (in Shell window) ###############

sub why_lookahead {
    my ($self, $state, $item, $token) = @_;
    my $tokenname = $self->{parser}->dump_sym($token);
    $self->status("Why lookahead $tokenname in state $state: see shell window");
    $self->{shell}->run("why lookahead token $tokenname "
			."in state $state item $item");
}

1;

__END__

=head1 NAME

Parse::Vipar - Visual LALR parser debugger

=head1 SYNOPSIS

% vipar expr.y [--data=DATAFILE]

DATAFILE would contain a list of tokens, one per line, with optional values
after them separated by whitespace. Example:

 number
 '+'
 number
 '*'
 number

=head1 DESCRIPTION

Presents a visual display of a LALR parser in action.

=head1 AUTHOR

Steve Fink <steve@fink.com>

=head1 SEE ALSO

Parse::YALALR

=cut
