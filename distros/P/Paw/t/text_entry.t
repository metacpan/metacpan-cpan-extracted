print "1..4\n";
use Paw;
use Paw::Text_entry;
print "ok 1\n";

$widget = Paw::Text_entry->new(name=>"test", orientation=>"left", text=>"text", echo=>1);
print "ok 2\n";    

print "ok 3\n" if $widget->get_text() eq "text";
$widget->set_text("jo");
print "ok 4\n" if $widget->get_text() eq "jo";
