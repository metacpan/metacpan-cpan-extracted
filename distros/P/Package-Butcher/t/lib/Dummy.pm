package Dummy;

use Cannot::Load;
use Cannot::Load2;
use NoSuch::List::MoreUtils 'uniq';

use base 'Exporter';
our @EXPORT_OK = qw(existing);

sub existing { 'should never see this' }

# this strange construct forces a syntax error
sub filter {
    uniq map {lc} split /\W+/, shift;
}

sub chain {
    return Cannot::Load->foo->bar->baz->this->that(@_);
}

1;
