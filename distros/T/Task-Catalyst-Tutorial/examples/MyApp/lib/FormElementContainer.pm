package FormElementContainer;

use base 'HTML::Widget::Container';

sub _build_element {
    my ($self, $element) = @_;

    return () unless $element;
    if (ref $element eq 'ARRAY') {
        return map { $self->_build_element($_) } @{$element};
    }
    my $e = $element->clone;
    $e = new HTML::Element('span', class => 'fields_with_errors')->push_content($e)
        if $self->error && $e->tag eq 'input';

    return $e ? ($e) : ();
}

1;
