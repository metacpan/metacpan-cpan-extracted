package with_Dancer2;
use Dancer2;
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
