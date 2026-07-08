package PDF::Make::Structure;

use strict;
use warnings;

our $VERSION = '0.06';

use PDF::Make ();

1;

__END__

=head1 NAME

PDF::Make::Structure - Tagged PDF structure tree

=head1 SYNOPSIS

    use PDF::Make::Structure;

    my $tree = PDF::Make::Structure->create_tree($doc);
    my $root = $tree->root;

    my $heading = $root->add_child('H1');
    my $para = $root->add_child('P');

    # Tag content with MCID
    $canvas->begin_tag('H1', 0);  # MCID 0
    $canvas->BT->Tf('F1', 24)->Td(72, 700)->Tj('Chapter 1')->ET;
    $canvas->end_tag;

    $heading->add_content($page, 0);  # link MCID 0 to heading

    # Accessibility
    my $fig = $root->add_child('Figure');
    $fig->alt_text('Chart showing quarterly revenue');
    $fig->lang('en-US');

=head1 SEE ALSO

L<PDF::Make::Document>, L<PDF::Make::Canvas>

=cut
