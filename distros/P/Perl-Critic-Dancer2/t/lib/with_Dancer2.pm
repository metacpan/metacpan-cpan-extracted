package with_Dancer2;
use Dancer2;
sub deprecated_keywords {
    context;
    header;
    headers;
    push_header;
    my %foo = ( header => '123' );
    my $bar = {
        header => '123',
    };
    my $tas = {};
    $tas->{header} = '123';
}
sub unrecommended_keywords {
    params;
    my %foo = ( params => '123' );
    my $bar = {
        params => '123',
    };
    my $tas = {};
    $tas->{params} = '123';
}
sub return_redirect {
    return redirect 'foo';
}
sub just_redirect {
    redirect 'foo';
}
1;
