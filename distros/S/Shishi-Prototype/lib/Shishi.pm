package Shishi;
use Shishi::Prototype;
use strict;
use Shishi::Node;
use Shishi::Decision;
use Exporter;
@Shishi::ISA = qw( Exporter );
@Shishi::EXPORT_OK = qw( ACTION_FINISH ACTION_REDUCE ACTION_CODE
ACTION_SHIFT ACTION_CONTINUE ACTION_FAIL);

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
