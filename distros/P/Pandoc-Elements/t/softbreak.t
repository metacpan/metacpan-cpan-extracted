use strict;
use Test::More;
use Pandoc::Elements qw(pandoc_json Space);

my $json_in = <DATA>;
my $ast = pandoc_json( $json_in );

is $ast->string,
    'Dolorem sapiente ducimus quia beatae sapiente perspiciatis quia. Praesentium est cupiditate architecto temporibus eos.',
    'replaced SoftBreak with spaces';

$Pandoc::Elements::PANDOC_VERSION = '1.16';
like $ast->to_json, qr/"SoftBreak"/, 'keep SoftBreak by default';

$Pandoc::Elements::PANDOC_VERSION = '1.15';
unlike $ast->to_json, qr/"SoftBreak"/, 'no SoftBreak in modified ast';

done_testing;

__DATA__
[{"unMeta":{}},[{"t":"Para","c":[{"t":"Str","c":"Dolorem"},{"t":"Space","c":[]},{"t":"Str","c":"sapiente"},{"t":"Space","c":[]},{"t":"Str","c":"ducimus"},{"t":"Space","c":[]},{"t":"Str","c":"quia"},{"t":"SoftBreak","c":[]},{"t":"Str","c":"beatae"},{"t":"Space","c":[]},{"t":"Str","c":"sapiente"},{"t":"Space","c":[]},{"t":"Str","c":"perspiciatis"},{"t":"Space","c":[]},{"t":"Str","c":"quia."},{"t":"SoftBreak","c":[]},{"t":"Str","c":"Praesentium"},{"t":"Space","c":[]},{"t":"Str","c":"est"},{"t":"Space","c":[]},{"t":"Str","c":"cupiditate"},{"t":"SoftBreak","c":[]},{"t":"Str","c":"architecto"},{"t":"Space","c":[]},{"t":"Str","c":"temporibus"},{"t":"Space","c":[]},{"t":"Str","c":"eos."}]}]]

