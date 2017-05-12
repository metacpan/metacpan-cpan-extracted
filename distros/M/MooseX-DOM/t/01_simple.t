use strict;
use lib "t/lib";
use Test::More (tests => 10);

BEGIN
{
    use_ok "Test::MxD::Simple";
}

{
    my $xml = <<EOXML;
<feed attribute="hoge" xmlns="http://www.w3.org/2005/Atom">
<title>Hoge</title>
<multi>multi1</multi>
<multi>multi2</multi>
<multi>multi3</multi>
<multi>multi4</multi>
</feed>
EOXML

    my $obj = Test::MxD::Simple->new(node => $xml);
    ok($obj);
    isa_ok($obj, 'Test::MxD::Simple');

    is( $obj->title, "Hoge" );

    $obj->title("Wee");

    is( $obj->title, "Wee" );

    my @multi = $obj->multi;
    is_deeply(\@multi,[ 'multi1', 'multi2', 'multi3', 'multi4' ] );

    $obj->multi('multi5', 'multi6');
    @multi = $obj->multi;
    is_deeply(\@multi,[ 'multi5', 'multi6' ]);

    my $attr = $obj->attribute();
    is($attr, "hoge");
    $obj->attribute("fuga");
    is($obj->attribute, "fuga");
}

{
    my $xml = <<EOXML;
<food attribute="hoge" xmlns="http://www.w3.org/2005/Atom">
<title>Hoge</title>
<multi>multi1</multi>
<multi>multi2</multi>
<multi>multi3</multi>
<multi>multi4</multi>
</food>
EOXML

    my $obj = eval { Test::MxD::Simple->new(node => $xml) };
    like($@, qr/given node does not have required root node/);
}