package BaseTestXS::Base2;
use Mojo::BaseXS;
use base 'BaseTestXS::Base1';

has [qw/ears eyes/] => sub {2};
has coconuts => 0;

1;
