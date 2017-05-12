use lib 't/lib';

package OldWay;
use Rubyish::AttributeOld;
attr_accessor 'name';
sub new { bless {}, shift }

package NewWay;
use Rubyish::Attribute;
attr_accessor 'name';
sub new { bless {}, shift }

package main;
use Benchmark qw(cmpthese);

cmpthese(1000000, {
    'OldWay' => sub {
        my $obj = OldWay->new;
        $obj->name("hi");
    },
    'NewWay' => sub {
        my $obj = NewWay->new;
        $obj->name("hi");
    }
});
