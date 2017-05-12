use strict;
use Test::More 0.96; # subtests
use Test::Exception;
use Pandoc::Elements;
use JSON qw( decode_json );

use utf8;

sub list2content {
    my @content = map { Str( $_ ), Space } @_;
    pop @content;    # remove trailing space
    return \@content;
}

sub doc_meta() {
    { title => MetaInlines( [Plain [ Str 'A', SoftBreak, Str 'message' ] ] ) }
}

sub doc_blocks() {
    [ Header( 1, attributes {}, list2content qw[Hej Världen!] ),
              Para list2content qw[Hur mår du idag?] ]
}

my %data = (
    1.16 => [
        'meta, blocks, api_version' => [
            doc_meta, doc_blocks, api_version => '1.16'
        ],
        '[ { unMeta => meta }, blocks' => [
            [ { unMeta => doc_meta }, doc_blocks ]
        ],
        '{ meta =>, blocks =>, pandoc-api-version }' => [
            { 
                meta => doc_meta,
                blocks => doc_blocks,
                'pandoc-api-version' => [ 1, 16 ],
            }
        ],
    ],
    1.17 => [
        'meta, blocks' => [ 
            doc_meta, doc_blocks,
        ],
        'meta, blocks, api_version =>' => [
            doc_meta,
            doc_blocks,
            api_version => '1.17',
        ],
        '{ meta =>, blocks => }' => [
            { meta => doc_meta, blocks => doc_blocks }
        ],
        '{ meta =>, blocks =>, pandoc-api-version => }' => [
            {   meta => doc_meta,
                blocks => doc_blocks,
                'pandoc-api-version' => [ 1, 17 ],
            }
        ],
    ],
);

my %json = (
  '1.17' => '{"blocks":[{"c":[1,["",[],[]],[{"c":"Hej","t":"Str"},{"c":[],"t":"Space"},{"c":"V\u00e4rlden!","t":"Str"}]],"t":"Header"},{"c":[{"c":"Hur","t":"Str"},{"c":[],"t":"Space"},{"c":"m\u00e5r","t":"Str"},{"c":[],"t":"Space"},{"c":"du","t":"Str"},{"c":[],"t":"Space"},{"c":"idag?","t":"Str"}],"t":"Para"}],"meta":{"title":{"c":[{"c":[{"c":"A","t":"Str"},{"c":[],"t":"SoftBreak"},{"c":"message","t":"Str"}],"t":"Plain"}],"t":"MetaInlines"}},"pandoc-api-version":[1,17]}',
  '1.16' => '[{"unMeta":{"title":{"c":[{"c":[{"c":"A","t":"Str"},{"c":[],"t":"SoftBreak"},{"c":"message","t":"Str"}],"t":"Plain"}],"t":"MetaInlines"}}},[{"c":[1,["",[],[]],[{"c":"Hej","t":"Str"},{"c":[],"t":"Space"},{"c":"V\u00e4rlden!","t":"Str"}]],"t":"Header"},{"c":[{"c":"Hur","t":"Str"},{"c":[],"t":"Space"},{"c":"m\u00e5r","t":"Str"},{"c":[],"t":"Space"},{"c":"du","t":"Str"},{"c":[],"t":"Space"},{"c":"idag?","t":"Str"}],"t":"Para"}]]',
  '1.12.3' => '[{"unMeta":{"title":{"c":[{"c":[{"c":"A","t":"Str"},{"c":[],"t":"Space"},{"c":"message","t":"Str"}],"t":"Plain"}],"t":"MetaInlines"}}},[{"c":[1,["",[],[]],[{"c":"Hej","t":"Str"},{"c":[],"t":"Space"},{"c":"V\u00e4rlden!","t":"Str"}]],"t":"Header"},{"c":[{"c":"Hur","t":"Str"},{"c":[],"t":"Space"},{"c":"m\u00e5r","t":"Str"},{"c":[],"t":"Space"},{"c":"du","t":"Str"},{"c":[],"t":"Space"},{"c":"idag?","t":"Str"}],"t":"Para"}]]',
);

foreach (keys %json) {
    $json{$_} = JSON->new->utf8->canonical->convert_blessed->encode( decode_json $json{$_} );
}

# create a document and check whether it equals to expected result
sub test_document(@) {
    my ($args, $expect, $json, $message) = @_;

    subtest $message => sub {
        my $doc = Document @$args;
        isa_ok $doc, 'Pandoc::Document', '$doc';
        is_deeply $doc, $expect, 'expected'; 
        is $doc->to_json, $json, 'to_json';
    };
}

foreach my $api_version ( qw[ 1.16 1.17 ] ) {
    subtest $api_version => sub {
        my $expect = pandoc_json $json{$api_version};
        is $expect->api_version, $api_version, 'api_version';
        
        my @variants = @{ $data{$api_version} };
        while (@variants) {
            my ($name, $args) = splice @variants, 0, 2;
            test_document $args, $expect, $json{$api_version}, $name;
        }
    };
}

subtest '1.12.3' => sub {
    my $expect = Document pandoc_json($json{1.16});
    $expect->api_version('1.12.3');

    my $args = [ doc_meta, doc_blocks, api_version => '1.12.3' ];
    test_document $args, $expect, $json{'1.12.3'}, 'api_version = 1.12.3';
};

throws_ok { Document doc_meta, doc_blocks, api_version => '1.12.1' }
    qr{^api_version must be >= 1\.12\.3}, 'minimum api_version';

throws_ok { Document doc_meta, doc_blocks, '1.17.0.4' }
    qr{Document: too many or ambiguous arguments}, 'invalid arguments';

throws_ok { Document 'hello' }
    qr{expect array or hash reference}, 'invalid arguments';

done_testing;
