print "1..4\n";

use Paw;
use Paw::Box;
print "ok 1\n";

$widget = Paw::Box->new(direction=>"v");
print "ok 2\n";    

$box = Paw::Box->new(direction=>"h", name=>"testbox", title=>"test", color=>1, orientation=>"top_left");
print "ok 3\n";

$box->put($widget);
print "ok 4\n";

