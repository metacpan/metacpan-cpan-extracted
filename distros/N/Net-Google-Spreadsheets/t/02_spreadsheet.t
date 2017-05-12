use t::Util;
use Test::More;
use Test::Exception;

ok my $service = service;

{
    my @sheets = $service->spreadsheets;
    ok scalar @sheets;
    isa_ok $sheets[0], 'Net::Google::Spreadsheets::Spreadsheet';
    ok $sheets[0]->title;
    ok $sheets[0]->key;
    ok $sheets[0]->etag;
}

{
    ok my $ss = spreadsheet;
    isa_ok $ss, 'Net::Google::Spreadsheets::Spreadsheet';
    is $ss->title, $t::Util::SPREADSHEET_TITLE;
    like $ss->id, qr{^https://spreadsheets.google.com/feeds/spreadsheets/};
    isa_ok $ss->author, 'XML::Atom::Person';
    is $ss->author->email, config->{username};
    my $key = $ss->key;
    ok length $key, 'key defined';
    my $ss2 = $service->spreadsheet({key => $key});
    ok $ss2;
    isa_ok $ss2, 'Net::Google::Spreadsheets::Spreadsheet';
    is $ss2->key, $key;
    is $ss2->title, $t::Util::SPREADSHEET_TITLE;
    throws_ok { $ss2->title('foobar') } qr{Cannot assign a value to a read-only accessor};
}

{
    my @existing = map {$_->title} $service->spreadsheets;
    my $title;
    while (1) {
        $title = 'spreadsheet created at '.scalar localtime;
        grep {$_ eq $title} @existing or last; 
    }
    
    my $ss = $service->spreadsheet({title => $title});
    is $ss, undef, "spreadsheet named '$title' shouldn't exit";
    my @ss = $service->spreadsheets({title => $title});
    is scalar @ss, 0;
}

done_testing;
