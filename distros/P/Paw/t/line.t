print "1..2\n";
use Paw;
use Paw::Line;
print "ok 1\n";

$line = Paw::Line->new(char=>"#");
print "ok 2\n" if $line->{char} eq "#";    

