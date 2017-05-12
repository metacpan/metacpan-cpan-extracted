print "1..2\n";
use Mmap;
use FileHandle;
$tmp = "mmap.tmp";

sysopen(FOO, $tmp, O_WRONLY|O_CREAT|O_TRUNC) or die "$tmp: $!\n";
print FOO "ok 1\n";
close FOO;

sysopen(FOO, $tmp, O_RDONLY) or die "$tmp: $!\n";
mmap($foo, 0, PROT_READ, MAP_SHARED, FOO);
close FOO;

print $foo;
munmap($foo);

sysopen(FOO, $tmp, O_RDWR) or die "$tmp: $!\n";
mmap($foo, 0, PROT_READ|PROT_WRITE, MAP_SHARED, FOO);
close FOO;

substr($foo, 3, 1) = "2";
print $foo;

unlink($tmp);
