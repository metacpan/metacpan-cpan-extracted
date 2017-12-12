use strictures 1;
package Mojito::Template::Zoom;
$Mojito::Template::Zoom::VERSION = '0.25';
use Moo;
use HTML::Zoom;

# Given a template we can zoom in on parts and manipulex 'em.
has 'template' => (
    is => 'rw',
    lazy => 1,
    builder => '_build_template',
);

has 'template_z' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_zoom',
);
has 'edit_area_z' => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->zoom->select('#content') },
);
has 'view_area_z' => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->zoom->select('#view_area') },
);

=head1 Methods

=head2 replace_view_area

Inject rendered content into the view area.

=cut

sub replace_view_area {
    my ($self, $new_content) = @_;

    $self->view_area->replace_content(\$new_content);
}

=head2 replace_edit_area

Inject source into edit area.

=cut

sub replace_edit_area{
    my ($self, $new_content) = @_;

    $self->edit_area->replace_content(\$new_content);
}

=head2 replace_edit_page

Put some content into the edit page, both source and rendered.

=cut

sub replace_edit_page {
    my ($self, $edit, $view) = @_;

    $self->template_z
      ->select('#content')
      ->replace_content(\$edit)
      ->select('#view_area')
      ->replace_content(\$view)->to_html;
}

sub _build_zoom {
    my ($self) = @_;

    HTML::Zoom->new->from_html($self->template);
}

sub _build_template {
    my $self = shift;

    my $edit_page = <<'END_HTML';
<!doctype html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>Mojito page</title>
</head>
<body>
<section id="edit_area" style="float:left;">
<form id="editForm" action="" accept-charset="UTF-8" method="post">
    <textarea id="content" cols="72" rows="24" /></textarea><br />
    <input id="submit" type="submit" value="Submit content" />
</form>
</section>
<section id="view_area" style="float:left; margin-left:1em;"></section>
</body>
</html>
END_HTML

    return $edit_page;

}
1;