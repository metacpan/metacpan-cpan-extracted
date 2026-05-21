use strict;
use warnings;
use utf8;
use Test::More tests => 11;

use PDF::FacturX::XML qw(build_xml);

my $base = sub {
    return {
        number   => 'FA-X',
        date     => '2026-04-19',
        currency => 'EUR',
        seller   => { name => 'Acme', country => 'FR' },
        buyer    => { name => 'Client', country => 'FR' },
        lines    => [{ name => 'A', qty => 1, unit_price => 100, vat_rate => 20, vat_cat => 'S' }],
    };
};

# 1. Profil inconnu
eval { build_xml($base->(), 'nope'); };
like($@, qr/Profil Factur-X inconnu/i, 'unknown profile rejected');

# 2. Hash absent
eval { build_xml(undef, 'basic'); };
like($@, qr/hashref/i, 'undef invoice rejected');

# 3. Champ requis manquant : number
{
    my $i = $base->(); delete $i->{number};
    eval { build_xml($i, 'basic'); };
    like($@, qr/number/i, 'missing number rejected');
}

# 4. Date format invalide
{
    my $i = $base->(); $i->{date} = '19/04/2026';
    eval { build_xml($i, 'basic'); };
    like($@, qr/format ISO/i, 'invalid date format rejected');
}

# 5. Due date format invalide
{
    my $i = $base->(); $i->{due_date} = 'plus tard';
    eval { build_xml($i, 'basic'); };
    like($@, qr/due_date.*format ISO/i, 'invalid due_date rejected');
}

# 6. Seller manquant
{
    my $i = $base->(); delete $i->{seller};
    eval { build_xml($i, 'basic'); };
    like($@, qr/seller/i, 'missing seller rejected');
}

# 7. Seller.name manquant
{
    my $i = $base->(); delete $i->{seller}{name};
    eval { build_xml($i, 'basic'); };
    like($@, qr/seller\.name/i, 'missing seller.name rejected');
}

# 8. Buyer.name manquant
{
    my $i = $base->(); delete $i->{buyer}{name};
    eval { build_xml($i, 'basic'); };
    like($@, qr/buyer\.name/i, 'missing buyer.name rejected');
}

# 9. Currency mauvais format
{
    my $i = $base->(); $i->{currency} = 'eur';
    eval { build_xml($i, 'basic'); };
    like($@, qr/ISO 4217/i, 'invalid currency rejected');
}

# 10. vat_cat invalide
{
    my $i = $base->(); $i->{lines}[0]{vat_cat} = 'X';
    eval { build_xml($i, 'basic'); };
    like($@, qr/vat_cat invalide/i, 'invalid vat_cat rejected');
}

# 11. Lines requises pour basic
{
    my $i = $base->(); delete $i->{lines};
    eval { build_xml($i, 'basic'); };
    like($@, qr/lines/i, 'missing lines rejected for basic');
}
