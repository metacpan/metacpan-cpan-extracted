package Pod::Abstract::Parser;
use strict;

use Pod::Parser;
use Pod::Abstract::Node;
use Data::Dumper;
use base qw(Pod::Parser);

our $VERSION = '0.26';

=head1 NAME

Pod::Abstract::Parser - Internal Parser class of Pod::Abstract.

=head1 DESCRIPTION

This is a C<Pod::Parser> subclass, used by C<Pod::Abstract> to convert Pod
text into a Node tree.

Use this class via the L<Pod::Abstract> class which has "load" methods
provided.

=head1 METHODS

=head2 new

 Pod::Abstract::Parser->new( $pod_abstract );

Requires a Pod::Abstract object to load Pod data into. Should only be
called internally by L<Pod::Abstract>.

This is a subclass of L<Pod::Parser> and uses that class to handle all basic Pod
parsing, but implements the additional rules from L<perlpodspec> that require
more context.

=cut

sub new {
    my $class = shift;
    my $p_a = shift;
    
    # Always accept non-POD paras, so that the input document can
    # always be reproduced exactly as entered. These will be stored in
    # the tree but will be available through distinct methods.
    my $self = $class->SUPER::new();
    $self->parseopts(
        -want_nonPODs => 1,
        -process_cut_cmd => 1,
        );
    $self->{pod_abstract} = $p_a;
    my $root_node = Pod::Abstract::Node->new(
        type => "[ROOT]",
        );
    $self->{cmd_stack} = [ $root_node ];
    $self->{root} = $root_node;
    
    return $self;
}

sub root {
    my $self = shift;
    return $self->{root};
}

# Automatically nest these items: A head1 section continues until the
# next head1, list items continue until the next item or end of list,
# etc. POD doesn't specify these relationships, but they are natural
# and make sense in the whole document context.
#
# SPECIAL: Start node with < to pull the end node out of the tree and
# into the opening node - e.g, pull a "back" into an "over", but not
# into an "item". Pulling a command stops it from closing any more
# elements, so begin/end style blocks need to use a pull, or one end
# will close all begins.
my %section_commands = (
    'head1' => [ 'head1' ],
    'head2' => [ 'head2', 'head1' ],
    'head3' => [ 'head3', 'head2', 'head1' ],
    'head4' => [ 'head4', 'head3', 'head2', 'head1' ],
    'head5' => [ 'head5', 'head4', 'head3', 'head2', 'head1' ],
    'head6' => [ 'head6', 'head5', 'head4', 'head3', 'head2', 'head1' ],
    'over'  => [ '<back' ],
    'item'  => [ 'item', 'back' ],
    'begin' => [ '<end' ],
    );

# Don't parse anything inside these. But there are some special cases where you
# might need to - see "parse_me"
my %no_parse = (
    'begin' => 1,
    'for' => 1,
    );

my %attr_names = (
    head1 => 'heading',
    head2 => 'heading',
    head3 => 'heading',
    head4 => 'heading',
    item  => 'label',
    );

sub command {
    my ($self, $command, $paragraph, $line_num) = @_;
    my $cmd_stack = $self->{cmd_stack} || [ ];
    
    my $p_break = "\n\n";
    if($paragraph =~ s/([ \t]*\n[ \t]*\n)$//s) {
        $p_break = $1;
    }        
    
    if($self->cutting) {
        # Treat as non-pod - i.e, verbatim program text block.
        my $element_node = Pod::Abstract::Node->new(
            type => "#cut",
            body => ($paragraph ? "=$command $paragraph$p_break" : "=$command$p_break"),
            );
        my $top = $cmd_stack->[$#$cmd_stack];
        $top->push($element_node);
    } else {
        # Treat as command.
        my $pull = undef;
        while(@$cmd_stack > 0) {
            my $last = scalar(@$cmd_stack) - 1;
            my @should_end = ( );
            @should_end = 
                grep { $command eq $_ }
                     @{$section_commands{$cmd_stack->[$last]->type}};
            my @should_pull = ( );
            @should_pull =
                grep { "<$command" eq $_ }
                     @{$section_commands{$cmd_stack->[$last]->type}};
            if(@should_end) {
                my $end_cmd = pop @$cmd_stack;
            } elsif(@should_pull) {
                $pull = pop @$cmd_stack;
                last;
            } else {
                last;
            }
        }
        
        # Don't do anything special if we're on a no_parse node
        my $top = $cmd_stack->[$#$cmd_stack];
        if($no_parse{$top->type} && !$top->param('parse_me')) {
            my $t_node = Pod::Abstract::Node->new(
                type => ':text',
                body => ($paragraph ne '' ? 
                         "=$command $paragraph$p_break" :
                         "=$command$p_break"),
                );
            $top->push($t_node);
            return;
        }
        
        # Some commands have to get expandable interior sequences
        my $attr_node = undef;
        my $attr_name = $attr_names{$command};
        my %attr = ( parse_me => 0 );
        if($attr_name) {
            $attr_node = Pod::Abstract::Node->new(
                type => '@attribute',
                );
            $paragraph =~ s/[\s\n\r]+/ /g;
            my $pt = $self->parse_text($paragraph);
            $self->load_pt($attr_node, $pt);
            $attr{$attr_name} = $attr_node;
            $attr{body_attr} = $attr_name;
        } elsif($command =~ m/^(begin|for)$/ && $paragraph =~ m/^\:/) {
            # In the case of begin/for, the format name is the first word and if
            # it begins with : then the internal POD should be parsed.
            $attr{parse_me} = 1;
        }

        my $for_para = undef;
        if($command eq 'for') {
            # Special case for =for - POD rules are nonsense, so the first
            # *word* is the formatter (we will treat as body), and the
            # following words are either a child text, or possibly interior
            # sequences that need to be parsed.
            my ($formatter, $rest) = split /\s/,$paragraph,2;
            $paragraph = $formatter;
            $for_para = $rest;
        }

        
        my $element_node = Pod::Abstract::Node->new(
            type => $command,
            body => ($attr_name ? undef : $paragraph),
            p_break => $p_break,
            %attr,
            );

        if( $command eq 'for' && $for_para ) {
            # Special handling for =for - the "paragraph" has been split from
            # the formatter, and may or may not need parsing.
            if( $attr{parse_me} ) {
                my $pt = $self->parse_text($for_para);
                $self->load_pt($element_node, $pt);
            } else {
                my $t_node = Pod::Abstract::Node->new(
                    type => ':text',
                    body => $for_para,
                    );
                $element_node->push($t_node);
            }
        }

        if($pull) {
            $pull->param('close_element', $element_node);
        } else {
            $top->push($element_node);
        }
        if($section_commands{$command}) {
            push @$cmd_stack, $element_node;
        } else {
            # No push
        }
    }
    
    $self->{cmd_stack} = $cmd_stack;
}

=head2 verbatim

In general, a verbatim node is created as any indented text in a POD block.
However, there's a special case which is that -

=over

=item *

If we are in a "begin/end" block, that's by default not parsed, and this should
be text, not verbatim.

=item *

B<But> if we are in a parsed begin/end block (C<parse_me>) it should still be a
verbatim node.

=back

The behaviour here is very much a DWIM - if you're in a non-parsed block this
will interpret it correctly even though C<Pod::Parser> will tell you it's a
verbatim. If you're in a parsed block it will be a C<:text>.

 This would be verbatim.

 =begin example

 But if this command was at the start of the line, this would be non-parsed
 and would instead be a text node.

 =end

=cut

sub verbatim {
    my ($self, $paragraph, $line_num) = @_;
    
    my $cmd_stack = $self->{cmd_stack};
    my $top = $cmd_stack->[$#$cmd_stack];

    my $type = ':verbatim';
    if($no_parse{$top->type} && !$top->param('parse_me')) {
        $type = ':text';
    }
    
    my $element_node = Pod::Abstract::Node->new(
        type => ':verbatim',
        body => $paragraph,
        );
    $top->push($element_node);
}

sub preprocess_paragraph {
    my ($self, $text, $line_num) = @_;
    return $text unless $self->cutting;
    
    # This is a non-pod text segment
    my $element_node = Pod::Abstract::Node->new(
        type => "#cut",
        body => $text,
        );
    my $cmd_stack = $self->{cmd_stack};
    my $top = $cmd_stack->[$#$cmd_stack];
    $top->push($element_node);
}

=head2 textblock

Textblock handling as C<Pod::Parser> class - we are keeping a command stack
which lets us know if we should parse the interior sequences of the text block -
the C<< B<interior sequences> >> style commands. In some cases L<perlpodspec>
requires them to be ignored, and in some cases they should be parsed.

The C<%no_parse> hash defines commands that generally shouldn't be parsed, but
the command parser may add a parameter C<parse_me> to the command which will
cause their text to be parsed as normal POD text.

=cut

sub textblock {
    my ($self, $paragraph, $line_num) = @_;
    my $p_break = "\n\n";
    if($paragraph =~ s/([ \t]*\n[ \t]*\n)$//s) {
        $p_break = $1;
    }
    my $cmd_stack = $self->{cmd_stack};
    my $top = $cmd_stack->[$#$cmd_stack];
    if($no_parse{$top->type} && !$top->param('parse_me')) {
        my $element_node = Pod::Abstract::Node->new(
            type => ':text',
            body => "$paragraph$p_break",
            );
        $top->push($element_node);
        return;
    }

    my $element_node = Pod::Abstract::Node->new(
        type => ':paragraph',
        p_break => $p_break,
        );
    my $pt = $self->parse_text($paragraph);
    $self->load_pt($element_node, $pt);

    $top->push($element_node);
}

# Recursive load
sub load_pt {
    my $self = shift;
    my $elt = shift;
    my $pt = shift;
    
    my @c = $pt->children;
    foreach my $c(@c) {
        if(ref $c) {
            # Object;
            if($c->isa('Pod::InteriorSequence')) {
                my $cmd = $c->cmd_name;
                my $i_node = Pod::Abstract::Node->new(
                    type => ":$cmd",
                    left_delimiter => $c->left_delimiter,
                    right_delimiter => $c->right_delimiter,
                    );
                $self->load_pt($i_node, $c->parse_tree);
                $elt->push($i_node);
            } else {
                die "$c not an interior sequence!";
            }
        } else {
            # text
            my $t_node = Pod::Abstract::Node->new(
                type => ':text',
                body => $c,
                );
            $elt->push($t_node);
        }
    }
    return $elt;
}

sub end_pod {
    my $self = shift;
    my $cmd_stack = $self->{cmd_stack};
    
    my $end_cmd;
    while(defined $cmd_stack && @$cmd_stack) {
        $end_cmd = pop @$cmd_stack;
    }
    die "Last node was not root node" unless $end_cmd->type eq '[ROOT]';
    
    # Replace the root node.
    push @$cmd_stack, $end_cmd;
}

=head1 AUTHOR

Ben Lilburne <bnej80@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2025 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
