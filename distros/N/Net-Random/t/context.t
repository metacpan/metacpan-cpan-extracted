use strict;
use warnings;

my $warning;
BEGIN { $SIG{__WARN__} = sub { warn $warning = join('', @_); }; }

use Test::More tests => 6;
use Test::MockObject;

my @statuses;
my @content;

my $lwp = Test::MockObject->new();
$lwp->fake_new('LWP::UserAgent');
$lwp->mock(get => sub { return HTTP::Response->new(); });
my $httpresponse = Test::MockObject->new();
$httpresponse->fake_new('HTTP::Response');
$httpresponse->mock(is_success => sub { return shift(@statuses); });
$httpresponse->mock(content    => sub { return shift(@content); });

use_ok('Net::Random');

# now grab some real data from qrng.anu.edu.au
open(FILE, 't/qrng-data') || die("Can't open t/qrng-data\n");
$warning = ''; @statuses = (1); @content = (join('', <FILE>));
close(FILE);

my $rand = Net::Random->new(ssl => 0, src => 'qrng.anu.edu.au');
is(scalar($rand->get()), 21, "->get() in scalar context works");
is(scalar($rand->get(1)), 133, "->get(1) in scalar context works");
is_deeply([$rand->get()], [89], "->get() in list context returns list");
is_deeply([$rand->get(2)], [37, 82], "->get(multiple) in list context returns list");
is_deeply(scalar($rand->get(2)), [76, 87], "->get(multi) in scalar context returns list-ref");
