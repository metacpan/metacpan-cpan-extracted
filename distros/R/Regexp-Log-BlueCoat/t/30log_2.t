use Test::More tests => 1;
use Regexp::Log::BlueCoat;

# change the default UFS categories
Regexp::Log::BlueCoat->ufs_category(
    'smartfilter',
    an => 'Anonymizer/Translator',
    ac => 'Art/Culture',
    ch => 'Chat',
    cs => 'Criminal_Skills',
    oc => 'Cults/Occult',
    mm => 'Dating',
    dr => 'Drugs',
    et => 'Entertainment',
    ex => 'Obscene/Extreme',
    gb => 'Gambling',
    gm => 'Games',
    nw => 'General_News',
    hs => 'Hate_Speech',
    hm => 'Humor',
    in => 'Investing',
    js => 'Job_Search',
    ls => 'Lifestyle',
    mt => 'Mature',
    mp => 'MP3_Sites',
    nd => 'Nudity',
    os => 'Online_Sales',
    pp => 'Personal',
    po => 'Politics/Religion',
    ps => 'Portal_Sites',
    sh => 'Self_Help/Health',
    sx => "Sex",
    sp => 'Sports',
    tr => 'Travel',
    na => 'Usenet_News',
    wm => 'Webmail',
);

my $log = Regexp::Log::BlueCoat->new(
    format  => '%g %e %a %w/%s %b %m %i %u %H/%d %c %f %A',
    ufs     => 'smartfilter',
    login   => 'ldap',
    capture => [':all'],
);

# test the regex on real log lines
@ARGV = ('t/bc2.log');
my @fields = $log->capture;
my $regexp = $log->regexp;

# a big data set
my %data;
my @data = (
    {
        'c-ip'        => '10.0.203.16',
        'user-agent'  => 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)',
        'time-taken'  => '182',
        'cs-uri'      => 'http://wwwsantéobésité.com/perl/main.pl',
        's-hierarchy' => 'DIRECT',
        'cs-username' => 'CN=George BUSH,OU=fr,O=states',
        'cs-supplier-name'   => 'wwwsantéobésité.com',
        's-action'           => 'TCP_NC_MISS',
        'sc-filter-category' => 'uncategorized',
        'cs-content-type'    => 'text/html',
        'cs-method'          => 'GET',
        'cs-bytes'           => '414',
        'sc-status'          => '404',
        'timestamp'          => '1046084665.298'
    },
);

$i = 0;
while (<>) {
    @data{@fields} = /$regexp/;
    is_deeply( \%data, $data[ $i++ ], "bc1.log line " . ( $i + 1 ) );
}

