print "1..2\n";
use Paw;
use Paw::Popup;
print "ok 1\n";

@b=("ok", "cancel");
$text=("jo\njojo");
$widget = Paw::Popup->new(buttons=>\@b, name=>"pop", height=>10, width=>10, text=>\$text);
print "ok 2\n" if $widget->{name} eq "pop";    

