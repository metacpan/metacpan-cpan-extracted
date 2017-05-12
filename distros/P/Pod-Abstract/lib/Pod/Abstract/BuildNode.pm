package Pod::Abstract::BuildNode;
use strict;

use Exporter;
use Pod::Abstract;
use Pod::Abstract::Parser;
use Pod::Abstract::Node;
use base qw(Exporter);

our $VERSION = '0.20';

our @EXPORT_OK = qw(node nodes);

sub node { 'Pod::Abstract::BuildNode' };
sub nodes { 'Pod::Abstract::BuildNode' };

=head1 NAME

Pod::Abstract::BuildNode - Build new nodes for use in Pod::Abstract.

=head1 SYNOPSIS

 use Pod::Abstract::BuildNode qw(node nodes); # shorthand
 
 my $root_doc = node->root;
 for(my $i = 1; $i < 10; $i ++) {
    $root_doc->push(node->head1("Heading number $i"));
 }
 print $root_doc->pod;

=head1 DESCRIPTION

For building a new Pod::Abstract document, or adding nodes to an
existing one. This provides easy methods to generate correctly set
nodes for most common Pod::Abstract elements.

=head1 NOTES

Pod::Abstract::BuildNode can export two functions, C<node> and
C<nodes>. These are constant functions to provide a shorthand so
instead of writing:

 use Pod::Abstract::BuildNode;
 # ...
 my @nodes = Pod::Abstract::BuildNode->from_pod( $pod );

You can instead write:

 use Pod::Abstract::BuildNode qw(node nodes);
 # ...
 my @nodes = nodes->from_pod($pod);

Which is more readable, and less typing. C<node> and C<nodes> are both
synonyms of C<Pod::Abstract::BuildNode>.

This shorthand form is shown in all the method examples below. All
methods operate on the class.

=head1 METHODS

=cut

=head2 from_pod

 my @nodes = nodes->from_pod($pod_text);

Given some literal Pod text, generate a full subtree of nodes. The
returned array is all of the top level nodes. The full document tree
will be populated under the returned nodes.

=cut

sub from_pod {
    my $class = shift;
    my $str = shift;
    
    my $root = Pod::Abstract->load_string($str);
    return undef unless $root;
    
    my @r = map { $_->detach; $_ } $root->children;
    return @r;
}

=head2 root

 my $root = node->root;

Generate a root node. A root node generates no output, and is used to
hold a document tree. Use this to make a new document.

=cut

sub root {
    my $class = shift;
    my $para = Pod::Abstract::Node->new(
        type => '[ROOT]',
        );
}

=head2 begin

 my $begin_block = node->begin($command);

Generates a begin/end block. Nodes nested inside the begin node will
appear between the begin/end.

Note that there is no corresponding C<end> method - the end command
belongs to it's corresponding begin.

=cut

sub begin {
    my $class = shift;
    my $cmd = shift;
    
    my $begin = Pod::Abstract::Node->new(
        type => 'begin',
        body => $cmd,
        close_element => Pod::Abstract::Node->new(
            type => 'end',
            body => $cmd,
        ),
        );
    return $begin;
}

=head2 for

 my $for = node->for('overlay from <class>');

Create a =for node. The argument is the literal body of the for node,
no parsing will be performed.

=cut

sub for {
    my $class = shift;
    my $str = shift;

    return Pod::Abstract::Node->new(
        type => 'for',
        body => $str,
        );
}

=head2 paragraph

 my $para = node->paragraph('Pod text');

Generates a Pod paragraph, possibly containing interior sequences. The
argument will be parsed as Pod, and will generate text and sequence
nodes inside the paragraph.

=cut

sub paragraph {
    my $class = shift;
    my $str = shift;
    
    my $para = Pod::Abstract::Node->new(
        type => ':paragraph',
        );
    my $parser = Pod::Abstract::Parser->new;
    my $pt = $parser->parse_text($str);
    
    if($pt) {
        $parser->load_pt($para,$pt);
    } else {
        return undef;
    }
}

=head2 verbatim

 my $v = node->verbatim($text);

Add the given text as a verbatim node to the document. All lines in
the fiven C<$text> will be indented by one space to ensure they are
treated as verbatim.

=cut

sub verbatim {
    my $class = shift;
    my $str = shift;
    
    my @strs = split "\n",$str;
    for(my $i = 0; $i < @strs; $i ++) {
        my $str_line = $strs[$i];
        $strs[$i] = ' '.$str_line;
    }
    my $verbatim = Pod::Abstract::Node->new(
        type => ':verbatim',
        body => (join("\n", @strs) . "\n\n"),
        );
    return $verbatim;
}

=head2 heading

 my $head2 = node->heading(2, $heading);

Generate a heading node at the given level. Nodes that "belong" in the
heading's section should be nested in the heading node. The
C<$heading> text will be parsed for interior sequences.

=cut

sub heading {
    my $class = shift;
    my $level = shift;
    my $heading = shift;

    my $attr_node = Pod::Abstract::Node->new(
        type => '@attribute',
        );
    my $parser = Pod::Abstract::Parser->new;
    my $pt = $parser->parse_text($heading);
    $parser->load_pt($attr_node, $pt);
        
    my $element_node = Pod::Abstract::Node->new(
        type => "head$level",
        heading => $attr_node,
        body_attr => 'heading',
        );
    return $element_node;
}

=head2 head1

 node->head1($heading);

=cut

sub head1 {
    my $class = shift;
    my $heading = shift;
    
    return $class->heading(1,$heading);
}

=head2 head2

 node->head2($heading);

=cut

sub head2 {
    my $class = shift;
    my $heading = shift;
    
    return $class->heading(2,$heading);
}

=head2 head3

 node->head3($heading);

=cut

sub head3 {
    my $class = shift;
    my $heading = shift;
    
    return $class->heading(3,$heading);
}

=head2 head4

 node->head4($heading);

=cut

sub head4 {
    my $class = shift;
    my $heading = shift;
    
    return $class->heading(4,$heading);
}

=head2 over

 my $list = node->over([$num]);

Generates an over/back block, to contain list items. The optional
parameter C<$num> specifies the number of spaces to indent by. Note
that the back node is part of the over, there is no separate back
method.

=cut

sub over {
    my $class = shift;
    my $number = shift;
    $number = '' unless defined $number;
    
    return Pod::Abstract::Node->new(
        type => 'over',
        body => ($number ? $number : undef),
        close_element => Pod::Abstract::Node->new(
            type => 'back',
        ),
        );
}

=head2 item

 my $item = node->item('*');

Generates an item with the specified label. To fill in the text of the
item, nest paragraphs into the item. Items should be contained in over
nodes.

=cut

sub item {
    my $class = shift;
    my $label = shift;
    
    my $attr_node = Pod::Abstract::Node->new(
        type => '@attribute',
        );
    my $parser = Pod::Abstract::Parser->new;
    my $pt = $parser->parse_text($label);
    $parser->load_pt($attr_node, $pt);
        
    my $element_node = Pod::Abstract::Node->new(
        type => "item",
        label => $attr_node,
        body_attr => 'label',
        );
    return $element_node;
}

=head2 text

 my $text = node->text('Literal text');

Generates a literal text node. You generally B<do not> want this, you
probably want a paragraph. Use this if you want to, for example,
append a word at the end of a paragraph.

=cut

sub text {
    my $class = shift;
    my $text = shift;
    
    my $attr_node = Pod::Abstract::Node->new(
        type => ':text',
        body => $text,
        );
    return $attr_node;
}

=head2 pod

 my $n = node->pod;

Generates an "=pod" command. Can be useful to force pod mode at the
end of cut nodes.

Do not confuse with L</from_pod>!

=cut

sub pod {
    my $class = shift;
    return Pod::Abstract::Node->new(
        type => 'pod',
        body => '',
        );
}

=head1

 my $cut = node->cut;

Generates an explicit "=cut" command.

=cut

sub cut {
    my $class = shift;
    return Pod::Abstract::Node->new(
        type => '#cut',
        body => "=cut\n\n",
        );
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
