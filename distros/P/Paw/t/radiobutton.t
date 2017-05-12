print "1..2\n";
use Paw;
use Paw::Radiobutton;
print "ok 1\n";

@labels=("a" , "b" );
$widget = Paw::Radiobutton->new(direction=>"v", color=>1, name=>"name", callback=>\&test_sub, labels=>\@labels);
print "ok 2\n" if ( $widget->{name} eq "name" );    

