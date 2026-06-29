package PDF::Make::Layer;

use strict;
use warnings;

our $VERSION = '0.04';

use PDF::Make ();

use constant {
    STATE_ON  => 0,
    STATE_OFF => 1,
};

sub create {
    my ($class, $doc, $name) = @_;
    return $class->_create($doc, $name);
}

1;

__END__

=head1 NAME

PDF::Make::Layer - Optional Content Groups (PDF Layers)

=head1 SYNOPSIS

    use PDF::Make::Layer;

    my $doc = PDF::Make::Document->new;
    my $page = $doc->add_page(612, 792);

    # Create layers
    my $dims = PDF::Make::Layer->create($doc, 'Dimensions');
    my $notes = PDF::Make::Layer->create($doc, 'Annotations');
    $notes->visible(0);  # hidden by default

    # Write layer objects
    $dims->write_to_doc($doc);
    $notes->write_to_doc($doc);

    # Register on page
    $page->add_ocg($dims->res_name, $dims->write_to_doc($doc));
    $page->add_ocg($notes->res_name, $notes->write_to_doc($doc));

    # Draw on layers
    my $c = PDF::Make::Canvas->new;
    $c->begin_layer($dims->res_name)
      ->w(1)->RG(0, 0, 1)
      ->m(72, 72)->l(200, 72)->S
      ->end_layer;

    $c->begin_layer($notes->res_name)
      ->BT->Tf('F1', 10)->Td(72, 100)->Tj('Note text')->ET
      ->end_layer;

    $page->set_content($c->to_bytes);
    $doc->to_file('layered.pdf');

=head1 CONSTANTS

=over 4

=item STATE_ON (0) — layer visible

=item STATE_OFF (1) — layer hidden

=back

=head1 METHODS

=head2 create($doc, $name)

Create a new layer on the document.

=head2 name()

Get the layer name.

=head2 res_name()

Get the resource name (e.g. "MC0") for use in content streams.

=head2 visible([$bool])

Get/set default visibility.

=head2 set_print_state($state)

Set print usage (STATE_ON or STATE_OFF).

=head2 set_view_state($state)

Set view usage.

=head2 set_export_state($state)

Set export usage.

=head2 write_to_doc($doc)

Write the OCG dictionary. Returns object number.

=head1 SEE ALSO

L<PDF::Make::Document>, L<PDF::Make::Canvas>

=cut
