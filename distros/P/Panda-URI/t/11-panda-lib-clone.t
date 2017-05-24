use strict;
use warnings;
use Test::More;
use Panda::URI qw/uri/;

plan skip_all => 'Panda::Lib required for testing Panda::Lib::clone' unless eval { require Panda::Lib; 1 };

# check that clone hook works
my $uri = uri("http://ya.ru");
my $cloned = Panda::Lib::lclone($uri);
is($cloned, "http://ya.ru");
$cloned->host('mail.ru');
is($cloned, "http://mail.ru");
is($uri, "http://ya.ru");

done_testing();
