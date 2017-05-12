print "1..7\n";
use Paw;
use Paw::Button;
print "ok 1\n";

$button = Paw::Button->new(name=>"testbutton");
print "ok 2\n" if ( $button->{name} );
$button->set_button();
print "ok 3\n" if ( $button->is_pressed() );
$button->release_button();
print "ok 4\n" if ( not $button->is_pressed() );
$button->push_button();
print "ok 5\n" if ( $button->is_pressed() );
$button->key_press(" ");
print "ok 6\n" if ( not $button->is_pressed() );
$button->key_press("\n");
print "ok 7\n" if ( $button->is_pressed() );

