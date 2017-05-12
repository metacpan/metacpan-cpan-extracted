print "1..3\n";
use Paw;
use Paw::Label;
print "ok 1\n";

$label = Paw::Label->new(text=>"test");
print "ok 2\n";    

print "ok 3\n" if ( $label->get_text() eq "test" );
