use lib 't/lib';
use Test::Monitis tests => 14, live => 1;

my $unique_page_name = 'test page ';

my @chars = split //, 'abcdefgh0123456789';
my $size = rand(15);

for (0 .. $size) {
    $unique_page_name .= uc $chars[rand(scalar @chars)];
}

note 'Action addPage';

my $response = api->layout->add_page(
    title       => $unique_page_name,
    columnCount => 2
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{pageId}, qr/^\d+$/, 'API returned page id';

my $page_id = $response->{data}{pageId};

note 'Action addPageModule to page #' . $page_id;

$response = api->layout->add_module_to_page(
    moduleName   => 'Process',
    pageId       => $page_id,
    column       => '1',
    row          => '2',
    dataModuleId => int rand(100000),    # Some glitch of api?
    height       => '400'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{pageModuleId}, qr/^\d+$/, 'API returned module id';

my $module_id = $response->{data}{pageModuleId};

note 'Action pageModules #' . $page_id;

$response =
  eval { api->layout->get_page_modules(pageName => $unique_page_name) } || [];

$response->[0]{id} = $@ if $@;

isa_ok $response, 'ARRAY', 'JSON response ok';

TODO: {
    local $TODO =
      'Make sure Monitis fixed "Malformed JSON string" but in pageModules method';

    like $response->[0]{id}, qr/^\d+$/, 'Right ID';
}

note 'Action deletePageModule #' . $page_id;

$response = api->layout->delete_page_module(pageModuleId => $module_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action deletePage #' . $page_id;

$response = api->layout->delete_page(pageId => $page_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action getPages';

$response = api->layout->get_pages;

isa_ok $response, 'ARRAY', 'JSON response ok';
like $response->[0]{id}, qr/^\d+$/,
  'API returned page id in HASH packed in ARRAY';
