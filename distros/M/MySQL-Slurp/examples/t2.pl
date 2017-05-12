
use IO::File::flock;

my $pipe = IO::File::flock->new( "pipe", ">" );
print $pipe "1\n";
$pipe->lock_un;
$pipe->lock_ex;

print $pipe "2\n";
# print <$pipe> "here\n";
# print <$pipe> "here\n";
<STDIN>;

