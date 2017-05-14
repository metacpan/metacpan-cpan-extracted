
# Flaws: action code and decision code not separated.

package Shishi::Prototype;
$Shishi::Debug = 0;
1;
package Shishi;
use strict;
use Shishi::Node;
use Shishi::Decision;
use Exporter;
@Shishi::ISA = qw( Exporter );
@Shishi::EXPORT_OK = qw( ACTION_FINISH ACTION_REDUCE ACTION_CODE
ACTION_SHIFT ACTION_CONTINUE ACTION_FAIL);

sub new {
    my $self = shift;
    my $o = bless {
        creator => shift,
        decisions => [],
        nodes => [],
        stack => [],
    };
    # We start with one node
    $o->add_node(new Shishi::Node ($o->{creator}));
    return $o;
}

sub new_mo {
    bless {
        text => $_[1]
    }, "Shishi::Match";
}

sub add_node {
    my $self = shift;
    my $node = shift;
    $node->{parents}++;
    push @{$self->{nodes}}, $node;
    return $self;
}

sub execute {
    my $self = shift;
    my $text = shift;
    $self->start_node->execute($self, Shishi->new_mo($text)) > 0;
}

sub start_node { $_[0]->{nodes}->[0] }

sub Shishi::Match::parse_text { my $self = shift; @_ ? $self->{text} = shift : $self->{text};  } 

sub dump {
    my $parser = shift;
    print "Parser ".$parser->{creator}." dump\n";
    my %name2num;
    my @nodes = @{$parser->{nodes}};
    print ((scalar @nodes), " nodes\n\n");
    $name2num{$nodes[$_]}=$_ for 0..$#nodes;
    for (0..$#nodes) {
        my $n = $nodes[$_];
        print "$_:\n";
        for ($n->decisions) {
            print "\tMatch ".$_->{type}.":";
            print " ".$_->{target} if exists $_->{target};
            print " -> ";
            print "($_->{hint}) " if exists $_->{hint};
            if ($_->{action} == ACTION_FINISH) {
                print "DONE\n";
            } elsif ($_->{action} == ACTION_FAIL) {
                print "FAIL\n";
            } elsif ($_->{action} == ACTION_CONTINUE) {
                if (defined $_->{next_node}) {
                    print exists $name2num{$_->{next_node}} ?
                        $name2num{$_->{next_node}}
                        :
                        "UNKNOWN NODE ($_->{next_node})\n";
                } else { print "INCOMPLETE" }
                print "\n";
            } elsif ($_->{action} == ACTION_SHIFT) {
                print "SHIFT (something)\n";
            } elsif ($_->{action} == ACTION_REDUCE) {
                print "REDUCE\n";
            } elsif ($_->{action} == ACTION_CODE) {
                print "CODE (".$_->{code}.")\n";
            } else {
                print "UNKNOWN ACTION\n";
            }
        }
    }
}

sub as_dot {
    require GraphViz;
    my $g = GraphViz->new(rankdir => "LR");
    my $parser = shift;
    my @nodes = @{$parser->{nodes}};
    $g->add_node($_, shape=>"circle") for 0..$#nodes;
    my %name2num;
    $name2num{$nodes[$_]}=$_ for 0..$#nodes;
    for my $node_num (0..$#nodes) {
        my $n = $nodes[$node_num];
        for ($n->decisions) {
            my $dec = $g->add_node(
                label => "$_->{type}".(
                     exists $_->{target} ? " ($_->{target}) " : 
                     (exists $_->{code} && " ($_->{code}) ")
                ),
                shape => "box"
            );
            $g->add_edge($node_num, $dec, (exists $_->{hint} ? (label => $_->{hint}) : ()));
            if ($_->{action} == ACTION_FINISH) {
                my $targ = $g->add_node(
                    label => "DONE", style => "bold", shape => "circle");
                $g->add_edge($dec, $targ);
            } elsif ($_->{action} == ACTION_FAIL) {
                my $targ = $g->add_node(
                    label => "FAIL", style => "bold", shape => "circle");
                $g->add_edge($dec, $targ);
            } elsif ($_->{action} == ACTION_SHIFT) {
                my $targ = $g->add_node(
                    label => "SHIFT", style => "bold", shape => "circle");
                $g->add_edge($dec, $targ);
            } elsif ($_->{action} == ACTION_REDUCE) {
                my $targ = $g->add_node(
                    label => "REDUCE", style => "bold", shape => "circle");
                $g->add_edge($dec, $targ);
            } elsif ($_->{action} == ACTION_CONTINUE) {
                $g->add_edge($dec, exists $name2num{$_->{next_node}} ?
                        $name2num{$_->{next_node}} : $_->{next_node});
            } elsif ($_->{action} == ACTION_CODE) {
                my $targ = $g->add_node( 
                    label => "CODE", style => "bold", shape => "circle");
                $g->add_edge($dec, $targ);
            }   
        }
    }
    return $g->_as_debug;
}

1;

=head1 NAME

Shishi::Prototype - Internal use prototype for the Shishi regex/parser

=head1 SYNOPSIS

    my $parser = new Shishi ("test parser");
    $parser->start_node->add_decision(
     new Shishi::Decision(target => 'a', type => 'char', action => 4,
                              next_node => Shishi::Node->new->add_decision(
        new Shishi::Decision(target => 'b', type => 'char', action => 4,
                              next_node => Shishi::Node->new->add_decision(
            new Shishi::Decision(target => 'c', type => 'char', action => 0)
                                ))
                            ))
    );
    $parser->start_node->add_decision(
     new Shishi::Decision(type => 'skip', next_node => $parser->start_node,
     action => 4)
    );
    $parser->parse_text("babdabc");
    if ($parser->execute()) {
        print "Successfully matched\n"
    } else {
        print "Match failed\n";
    }

=head1 DESCRIPTION

This is a prototype only. The real library (C<Shishi>) will come once
this prototype is finalised. The interface will remain the same.

As this is only a prototype, don't try doing anything with it yet.
However, feel free to use Shishi applications such as
C<Shishi::Perl6Regex>.

When C<Shishi> itself is released, you can uninstall this module and
install C<Shishi> and everything ought to work as normal. (Except
perhaps somewhat faster.) However, since we're still firming up the
interface with this prototype, it's best not to depend on it; hence, the
interface is not currently documented.

=head1 AUTHOR

Simon Cozens, C<simon@netthink.co.uk>

=cut
