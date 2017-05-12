print "1..4\n";
use Paw;
use Paw::Filedialog;
print "ok 1\n";

$fd = Paw::Filedialog->new();
print "ok 2\n";    

$fd = Paw::Filedialog->new(height=>10, width=>10, name=>"fd", dir=>"/tmp" );
print "ok 3\n" if ( $fd->{name} eq "fd" );

print "ok 4\n" if ( $fd->get_dir() eq "/tmp" );
$fd->set_dir("/etc");
print "ok 5\n" if ( $fd->get_dir() eq "/etc" );
