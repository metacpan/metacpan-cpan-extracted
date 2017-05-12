#
# This file is part of Pod-Elemental-Transformer-List-Converter
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Pod::Elemental::Transformer::List::Converter;
{
  $Pod::Elemental::Transformer::List::Converter::VERSION = '0.001';
}

# ABSTRACT: Convert a list to... something else

use Moose;
use namespace::autoclean;
use Moose::Autobox;

use Pod::Elemental;
use Pod::Elemental::Transformer 0.102361;

with 'Pod::Elemental::Transformer';

# debugging...
#use Smart::Comments;


has command => (is => 'rw', isa => 'Str', default => 'head2');


sub transform_node {
    my ($self, $node) = @_;

    my %drop = map { $_ => 1 } qw{ over back };
    my @elements;

    ### get children, and loop over them...
    ELEMENT_LOOP: for my $element ($node->children->flatten) {

        do { push @elements, $element; next ELEMENT_LOOP }
            unless $element->does('Pod::Elemental::Command');

        if ($element->does('Pod::Elemental::Command')) {

            my $command = $element->command;
            next ELEMENT_LOOP if $drop{$command};

            if ($command eq 'item') {

                my $content = $element->content;

                ### $content
                if ($content =~ /^\*\s*$/) {

                    warn 'not handling plain * items yet';
                    next ELEMENT_LOOP;
                }
                elsif ($content =~ /^\*/) {

                    $content =~ s/^\*\s*//;
                }

                chomp $content;
                $element->command($self->command);
                $element->content($content);
            }

            push @elements, $element;
        }
    }

    $node->children([ @elements ]);
    return;
}

__PACKAGE__->meta->make_immutable;

1;



=pod

=encoding utf-8

=head1 NAME

Pod::Elemental::Transformer::List::Converter - Convert a list to... something else

=head1 VERSION

This document describes 0.001 of Pod::Elemental::Transformer::List::Converter - released February 27, 2012 as part of Pod-Elemental-Transformer-List-Converter.

=head1 SYNOPSIS

    # somewhere inside your code...
    my $transformer = Pod::Elemental::Transformer::List::Converter->new;
    $transformer->transform_node($node);

=head1 DESCRIPTION

This L<Pod::Elemental::Transformer> takes a given node's children, and
converts any list commands to another command, C<head2> by default.

That is:

=over 4

=item C<=item> becomes C<=head2>, and

=item C<=over> and <=back> commands are dropped entirely.

=back

As you can imagine, it's important to be selective with the nodes you run
through this transformer -- if you pass the entire document to it, it will
obliterate any lists found.

=head1 ATTRIBUTES

=head2 command

The command we change C<=item> elements to; defaults to C<head2>.

=head1 METHODS

=head2 command

Accessor to the command attribute.

=head2 transform_node($node)

Takes a node, and replaces any C<=item>'s with our target command (by default,
C<=head2>).  We also drop any command elements found for C<=over> and
C<=back>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Elemental::Transformer>

=item *

L<Pod::Weaver::Section::Collect::FromOther>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/pod-elemental-transformer-list-converter>
and may be cloned from L<git://github.com/RsrchBoy/pod-elemental-transformer-list-converter.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/pod-elemental-transformer-list-converter/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__

