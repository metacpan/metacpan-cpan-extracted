use Test::More;
use Pandoc::Filter;
use Pandoc::Elements;
use JSON;
use Encode;
use Test::Output;

# FIXME: don't require decode_utf8 (?)

my $ast = Pandoc::Elements::pandoc_json(
    '{"blocks":[{"t":"Para","c":[{"t":"Str","c":"☃"}]}]}'
)->blocks->[0]->content->[0];
is_deeply $ast, { t => 'Str', c => decode_utf8("☃") }, 'JSON with Unicode';
Pandoc::Filter->new()->apply($ast);
is_deeply $ast, { t => 'Str', c => decode_utf8("☃") }, 'identity filter';

sub shout {
    return unless $_[0]->name eq 'Str';
    return Str($_[0]->content.'!');
}

# FIXME: cannot directly filter root element
$ast = [$ast];
Pandoc::Filter->new(\&shout)->apply($ast);
is_deeply $ast, [{ t => 'Str', c => "\x{2603}!" }], 'applied filter';

{
    local *STDIN = *DATA;
    my $data_start = tell DATA;
    stdout_like(sub { 
            pandoc_filter( \&shout ) 
        }, qr/"c":"☃!"/, 'pandoc_filter (sub)');

    seek DATA, $data_start, 0;
    stdout_like(sub { 
            pandoc_filter( Str => sub { Str($_[0]->content.'!') } ) 
        }, qr/"c":"☃!"/, 'pandoc_filter (hash)');
}

done_testing;

__DATA__
[{"unMeta":{}},[{"t":"Para","c":[{"t":"Str","c":"☃"}]}]]
