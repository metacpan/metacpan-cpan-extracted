#! perl
#
# Test for containers with object method values.
package Price;

sub new {
    my $class = shift;
    my $id    = shift;
    my $self  = {};
    bless $self, $class;
    $self->id($id);
    $self->{_data} = {
        1 => { on_sale => 1, price => 35.99, sale_price => 24.97 },
        2 => { on_sale => 0, price => 24.99, sale_price => undef },
        3 => { on_sale => 1, price => 64.99, sale_price => 46.88 }
    };
    return $self;
}

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    return $self->{id};
}
sub on_sale { my $self = shift; $self->{_data}->{ $self->id }->{on_sale} }
sub price   { my $self = shift; $self->{_data}->{ $self->id }->{price} }

sub sale_price {
    my $self = shift;
    $self->{_data}->{ $self->id }->{sale_price};
}

package main;

use strict;
use warnings;

use Test::More tests => 2;
use Template::Flute;

my ( $spec, $html, $flute, $out );

$spec = <<'EOS';
<specification>
    <list name="items" iterator="items">
        <param name="itemid" />
        <param name="title" />
        <list name="prices" iterator="prices">
            <param name="price" />
            <param name="sale_price" class="sale-price" />
            <container name="not-on-sale" value="!on_sale" />
            <container name="on-sale" value="on_sale" />
        </list>
    </list>
</specification>
EOS

$html = <<'EOH';
<div class="items">
    <span class="itemid">109267</span> <span class="title">Joseph Phelps Insignia</span>
    <div class="prices">
        <div class="on-sale">
            <span class="strikethough price">$109.99</span>
            <span class="sale-price">$99.99</span> 
        </div>
        <div class="not-on-sale">
            <span class="price">$109.99</span>
        </div>
    </div>
</div>
EOH

my $items = [
    {   itemid => 540876,
        title  => q{Freemark Abbey Merlot 2012},
        prices => [ Price->new(1) ]
    },
    {   itemid => 555024,
        title  => q{Rancho Sisquoc Cabernet Sauvignon 2009},
        prices => [ Price->new(2) ]
    },
    {   itemid => 555518,
        title  => q{Paul Hobbs Russian River Valley Pinot Noir 2013},
        prices => [ Price->new(3) ]
    }
];

$flute = Template::Flute->new(
    template      => $html,
    specification => $spec,
    iterators     => { items => $items },
);

$out = $flute->process();

my @ct_arr   = $flute->template->containers;
my $ct_count = scalar @ct_arr;
ok( $ct_count == 2, 'Test for container count' )
    || diag "Wrong number of containers: $ct_count\n";

ok( $out
        =~ m{<div class="items"><span class="itemid">540876</span> <span class="title">Freemark Abbey Merlot 2012</span><div class="prices"><div class="on-sale"><span class="strikethough price">35.99</span><span class="sale-price">24.97</span></div></div></div><div class="items"><span class="itemid">555024</span> <span class="title">Rancho Sisquoc Cabernet Sauvignon 2009</span><div class="prices"><div class="not-on-sale"><span class="price">24.99</span></div></div></div><div class="items"><span class="itemid">555518</span> <span class="title">Paul Hobbs Russian River Valley Pinot Noir 2013</span><div class="prices"><div class="on-sale"><span class="strikethough price">64.99</span><span class="sale-price">46.88</span></div></div></div>},
    q{container test via method}
);
