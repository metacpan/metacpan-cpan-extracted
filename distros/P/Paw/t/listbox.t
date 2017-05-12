print "1..7\n";
use Paw;
use Paw::Listbox;
print "ok 1\n";

$lb = Paw::Listbox->new(height=>10, width=>10, colored=>0, name=>"lb");
print "ok 2\n" if ( $lb->{name} eq "lb" );    

$lb->add_row("test");                    	
print "ok 3\n" if ( $lb->get_all_rows() == 1 );
$lb->add_row("test2");
$lb->del_row(0);
print "ok 4\n" if ( $lb->get_pushed_rows("data") == 0 );
print "ok 5\n" if ( $lb->get_pushed_rows("linenumbers") == 0 );
print "ok 6\n" if ( $lb->get_all_rows() == 1 );
@a = $lb->get_all_rows();
print "ok 7\n" if ( $a[0] eq "test2" );
