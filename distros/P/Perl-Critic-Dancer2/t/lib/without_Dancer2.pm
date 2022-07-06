package without_Dancer2;
use warnings;

sub deprecated_keywords {
    context;
    header;
    headers;
    push_header;
}
sub unrecommended_keywords {
    params;
}

1;
