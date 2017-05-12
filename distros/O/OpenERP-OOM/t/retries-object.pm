use Test::Most;
use OpenERP::OOM::Object::Base;
use FindBin;
use lib "$FindBin::Bin";
use ExceptionMock;

my $o = OpenERP::OOM::Object::Base->new({
    
});

pass 'test';

done_testing;
