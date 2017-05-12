package Album::Text; {

    use Moose;

    sub supported_mime_types { qw{text/plain} }

    with "Album::Role::Resource";
}

1;
