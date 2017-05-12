use Test::More tests => 22;
use Test::Warn;
use Test::Exception;

BEGIN { use_ok('Net::Laconica') };

my $laconica;

dies_ok{ $laconica = Net::Laconica->new } 'No arguments';


### Correct, wrong and invalid uri ###

dies_ok{ $laconica = Net::Laconica->new(
    uri => 'http://identi.ca'
) } 'Correct uri, no username and no password';

dies_ok{ $laconica = Net::Laconica->new(
    uri => 'http://alanhaggai.org'
) } 'Wrong uri, no username and no password';

dies_ok{ $laconica = Net::Laconica->new(
    uri     => 'http/identi.ca'
) } 'Invalid uri, no username and no password';


### Correct, wrong and invalid username ###

dies_ok{ $laconica = Net::Laconica->new(
    username => 'alanhaggai'
) } 'No uri, correct username and no password';

dies_ok{ $laconica = Net::Laconica->new(
    username => 'alanhaggaialavi'
) } 'No uri, wrong username and no password';

dies_ok{ $laconica = Net::Laconica->new(
    username => 'alanhaggai-'
) } 'No uri, invalid username and no password';


### Wrong password ###

dies_ok{ $laconica = Net::Laconica->new(
    password => 'topsecret'
) } 'No uri, no username and wrong password';


### Correct, wrong and invalid uri with correct and invalid username ###

ok($laconica = Net::Laconica->new(
    uri      => 'http://identi.ca',
    username => 'alanhaggai'
), 'Correct uri ,correct username and no password');

dies_ok{ $laconica = Net::Laconica->new(
    uri      => 'http://identi.ca',
    username => 'alan_haggai'
) } 'Correct uri, invalid username and no password';

ok($laconica = Net::Laconica->new(
    uri      => 'http://alanhaggai.org',
    username => 'alanhaggai'
), 'Wrong uri, correct username and no password');

dies_ok{ $laconica = Net::Laconica->new(
    uri      => 'http://alanhaggai.org',
    username => 'alanhaggai-'
) } 'Wrong uri, invalid username and no password';

dies_ok{ $laconica = Net::Laconica->new(
    uri      => 'htt//alanhaggai.org',
    username => 'alanhaggai'
) } 'Invalid uri, correct username and no password';

dies_ok{ $laconica = Net::Laconica->new(
    uri      => 'htt//alanhaggai.org',
    username => 'alanhaggai-'
) } 'Invalid uri, invalid username and no password';


### Correct, wrong and invalid uri with wrong password ###

dies_ok{ $laconica = Net::Laconica->new(
    uri      => 'http://identi.ca',
    password => 'topsecret'
) } 'Correct uri, no username and wrong password';

dies_ok{ $laconica = Net::Laconica->new(
    uri      => 'http://alanhaggai.org',
    password => 'topsecret'
) } 'Wrong uri, no username and wrong password';

dies_ok{ $laconica = Net::Laconica->new(
    uri      => 'http:identi.ca',
    password => 'topsecret'
) } 'Invalid uri, no username and wrong password';


### Correct and invalid username with wrong password

dies_ok{ $laconica = Net::Laconica->new(
    username => 'alanhaggai',
    password => 'topsecret'
) } 'No uri, correct username and wrong password';

dies_ok{ $laconica = Net::Laconica->new(
    username => 'alanhaggai-',
    password => 'topsecret'
) } 'No uri, invalid username and wrong password';

isa_ok($laconica, 'Net::Laconica', 'Object created successfully');

$laconica = Net::Laconica->new(
    uri      => 'http://identi.ca',
    username => 'alanhaggai'
);

my @messages = $laconica->fetch;
ok(@messages >= 1, 'It is indeed an array');
