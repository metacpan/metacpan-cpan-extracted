use strict;
use warnings;
use utf8;
use Test::More;
use Time::HiRes qw(sleep);
use Encode qw(encode_utf8);
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use POSIX qw(_exit);
use Net::UPnP::AV::MediaServer;
use Net::UPnP::AV::RSS;
use Net::UPnP::ControlPoint;

{
    package Local::BrowseResult;
    sub getstatuscode { exists($_[0]->{status}) ? $_[0]->{status} : 200 }
    sub getargumentlist { $_[0] }
    package Local::BrowseService;
    sub postaction {
        my ($self, $action, $args, $options) = @_;
        push @{$self->{calls}}, [$args->{ObjectID}, $args->{BrowseFlag}, $options->{deadline}];
        Time::HiRes::sleep($self->{delay}) if $self->{delay};
        return bless {status => $self->{status}}, 'Local::BrowseResult'
            if exists $self->{status};
        my $nodes = $self->{graph}{$args->{ObjectID}} || [];
        my $xml = join('', map {
            my ($kind, $id) = @$_;
            qq(<$kind id="$id"><dc:title>$id</dc:title></$kind>);
        } @$nodes);
        return bless {NumberReturned => scalar(@$nodes), TotalMatches => scalar(@$nodes),
            Result => $xml}, 'Local::BrowseResult';
    }
    package Local::BrowseDevice;
    sub getservicebyname { $_[0]->{service} }
}

sub media_server {
    my ($graph, %options) = @_;
    my $service = bless {graph => $graph, calls => [], %options}, 'Local::BrowseService';
    my $server = Net::UPnP::AV::MediaServer->new();
    $server->setdevice(bless {service => $service}, 'Local::BrowseDevice');
    return ($server, $service);
}

{
    my ($server, $service) = media_server({0 => [[container => 'a'], [item => 'rootitem']],
        a => [[item => 'leaf']]});
    my @visited;
    is($server->walkcontent(callback => sub { push @visited, [$_[0]->getid(), $_[1]]; }), 3,
        'ordinary walk returns visit count');
    is_deeply(\@visited, [['a', 1], ['leaf', 2], ['rootitem', 1]], 'depth-first order and indentation preserved');
    is($server->getwalkerror(), '', 'ordinary tree has no truncation');
    ok(!grep(!defined($_->[2]), @{$service->{calls}}), 'every Browse gets the overall deadline');
    @visited = ();
    $server->walkcontent(callback => sub { push @visited, $_[0]->getid(); });
    is_deeply(\@visited, ['a', 'leaf', 'rootitem'], 'visited state resets for a new walk');
    my @one = $server->getcontentlist(ObjectID => 0);
    my @two = $server->getcontentlist(ObjectID => 0);
    is(scalar(@one), scalar(@two), 'one-level Browse remains repeatable');
}

for my $graph (
    {0 => [[container => '0']]},
    {0 => [[container => 'a']], a => [[container => 'b']], b => [[container => 'a']]},
) {
    my ($server, $service) = media_server($graph);
    my @visited;
    $server->walkcontent(callback => sub { push @visited, $_[0]->getid(); });
    cmp_ok(scalar(@{$service->{calls}}), '<=', 3, 'cyclic graph has bounded requests');
    is($server->getwalkerror(), '', 'cycles are skipped without truncating unique objects');
    my %ids;
    ok(!grep($ids{$_}++, @visited), 'each container visited once');
}

{
    my %graph = map { $_ => [[container => '' . ($_ + 1)]] } (0 .. 100);
    my ($server, $service) = media_server(\%graph);
    my $count = $server->walkcontent(max_depth => 3, callback => sub {});
    is($count, 3, 'deep unique tree stops at depth cap');
    like($server->getwalkerror(), qr/depth limit/, 'depth truncation explicit');
    is(scalar(@{$service->{calls}}), 3, 'no Browse beyond depth cap');
}

{
    my ($server) = media_server({0 => [map { [item => $_] } 1 .. 20]});
    is($server->walkcontent(max_nodes => 3, callback => sub {}), 0,
        'wide response rejected during item parsing');
    like($server->getwalkerror(), qr/item limit/, 'wide tree reports item budget');
    ($server) = media_server({0 => [[container => 'a'], [item => 'b']], a => [[item => 'c']]});
    $server->walkcontent(max_nodes => 2, callback => sub {});
    like($server->getwalkerror(), qr/node limit/, 'pending siblings also consume total node budget');
}

{
    my ($server, $service) = media_server({0 => [[container => 'a']], a => [[container => 'b']]}, delay => 0.03);
    $server->walkcontent(timeout => 0.05, callback => sub {});
    like($server->getwalkerror(), qr/deadline/, 'repeated fast successful Browse has overall deadline');
    cmp_ok(scalar(@{$service->{calls}}), '<=', 2, 'deadline stops further requests');
    ($server) = media_server({0 => [[item => 'video']]});
    $server->walkcontent(timeout => 0.03, callback => sub { sleep 0.05; });
    is($server->getwalkerror(), '', 'caller-owned conversion time is excluded from Browse budget');
    my $ok = eval { $server->walkcontent(callback => sub { die "callback failed\n" }); 1; };
    ok(!$ok && $@ =~ /callback failed/, 'callback errors are not swallowed');
}

{
    my ($server, $service) = media_server({0 => []});
    $server->walkcontent(callback => sub {});
    is(scalar(@{$service->{calls}}), 3, 'empty directory retains metadata fallback');
    ok(!grep(!defined($_->[2]), @{$service->{calls}}), 'fallback and retry retain deadline');
    for my $options ({max_nodes => 0}, {max_depth => '9' x 400}, {timeout => '9' x 400}) {
        my $ok = eval { $server->walkcontent(callback => sub {}, %$options); 1; };
        ok(!$ok, 'invalid traversal budget rejected');
    }
    ($server) = media_server({}, status => 0);
    is($server->walkcontent(callback => sub {}), 0, 'failed Browse returns no invented objects');
    like($server->getwalkerror(), qr/HTTP 0/, 'transport failure is explicit, not an empty directory');
    ($server) = media_server({}, status => 500);
    $server->walkcontent(callback => sub {});
    like($server->getwalkerror(), qr/HTTP 500/, 'SOAP failure is explicit');
}

my $payload = '</title><description>injected</description><title>';
my $rss = Net::UPnP::AV::RSS::header(title => 'A & B', language => 'ja',
    description => '<text>', link => 'http://example.invalid/?a=1&b=2');
$rss .= Net::UPnP::AV::RSS::item(title => $payload, link => 'http://example.invalid/a" extra="yes', size => 7);
$rss .= "</channel>\n</rss>\n";
unlike($rss, qr/<description>injected/, 'raw title cannot create RSS fields');
like($rss, qr/&lt;\/title&gt;&lt;description&gt;injected/, 'title markup remains literal data');
like($rss, qr/url="http:\/\/example.invalid\/a&quot; extra=&quot;yes"/, 'filename quotes cannot create enclosure attributes');
like($rss, qr/<title>A &amp; B<\/title>/, 'channel text escaped');
like($rss, qr/<description>&lt;text&gt;<\/description>/, 'channel description escaped');
like($rss, qr/a=1&amp;b=2/, 'channel link escaped');

for my $case (
    ['A &amp; B', 'A &amp; B'],
    ['&lt;b&gt;x&lt;/b&gt;', '&lt;b&gt;x&lt;/b&gt;'],
    ['&amp;lt;', '&amp;lt;'],
    ['&#233; &#x65e5;', 'é 日'],
    ['日本語 &quot;映像&quot;', '日本語 &quot;映像&quot;'],
    [encode_utf8('日本語 &#233;'), '日本語 é'],
) {
    my $item = Net::UPnP::AV::RSS::item(title => $case->[0], link => 'x', size => 1);
    like($item, qr/\Q<title>$case->[1]<\/title>\E/, 'existing DIDL entity/Unicode display preserved');
}
my $invalid = Net::UPnP::AV::RSS::item(title => "a\x01&#xD800;&#9999999999999;b", link => "x\n\t", size => 1);
like($invalid, qr/<title>a\?\?\?b<\/title>/, 'invalid XML codepoints replaced');
like($invalid, qr/url="x&#10;&#9;"/, 'attribute whitespace represented explicitly');
my $ok = eval { Net::UPnP::AV::RSS::item(title => "\xff", link => '', size => 0); 1; };
ok(!$ok, 'invalid UTF-8 rejected rather than emitting malformed XML');

# Exercise the actual converter RSS sink without invoking Shell/curl/ffmpeg.
{
    my $script = abs_path('examples/dms2vodcast.pl');
    my $dir = tempdir(CLEANUP => 1);
    my $filename = 'device"injected="1_uuid-test_1_ipod.m4v';
    open(my $media, '>', "$dir/$filename") or die $!;
    print $media 'existing media'; close $media;
    my $pid = fork(); die $! unless defined $pid;
    if (!$pid) {
        alarm 3;
        open(STDOUT, '>:encoding(UTF-8)', '/dev/null') or _exit(1);
        $INC{'Shell.pm'} = __FILE__;
        no warnings qw(redefine once);
        *Shell::import = sub {};
        *Net::UPnP::ControlPoint::search = sub {
            my $dev = Net::UPnP::Device->new();
            $dev->setdescription('<deviceType>urn:schemas-upnp-org:device:MediaServer:1</deviceType><friendlyName>device" injected="1</friendlyName><UDN>uuid:test</UDN><serviceList><service><serviceType>urn:schemas-upnp-org:service:ContentDirectory:1</serviceType></service></serviceList>');
            return ($dev);
        };
        *Net::UPnP::AV::MediaServer::getcontentlist = sub {
            my $item = Net::UPnP::AV::Item->new();
            $item->setid('1'); $item->settitle($payload . ' &amp; 日本語');
            $item->setcontenttype('video/mp4'); $item->seturl('http://example.invalid/video');
            return ($item);
        };
        @ARGV = ('-B', "$dir/", 'feed.xml');
        do $script;
        _exit(1); # The successful script exits itself.
    }
    waitpid($pid, 0);
    is($?, 0, 'converter writes RSS using preexisting output without external processes');
    open(my $feed, '<:encoding(UTF-8)', "$dir/feed.xml") or die $!;
    my $text = do {local $/; <$feed>}; close $feed;
    unlike($text, qr/<description>injected/, 'actual script prevents RSS element injection');
    like($text, qr/device&quot;injected=&quot;1/, 'actual script escapes enclosure filename');
    like($text, qr/&amp; 日本語/, 'actual script writes UTF-8 exactly once');
    SKIP: {
        skip 'XML::Parser is not installed (optional structural check)', 3
            unless eval { require XML::Parser; 1; };
        my ($descriptions, $enclosure) = (0, undef);
        my $parser = XML::Parser->new(Handlers => {Start => sub {
            my ($expat, $element, %attrs) = @_;
            ++$descriptions if $element eq 'description';
            $enclosure = \%attrs if $element eq 'enclosure';
        }});
        my $ok = eval { $parser->parse(encode_utf8($text)); 1; };
        ok($ok, 'actual converter feed parses as XML') or diag $@;
        is($descriptions, 1, 'only the channel description exists');
        is_deeply([sort keys %{$enclosure || {}}], [qw(length type url)],
            'enclosure has exactly its intended attributes');
    }
}

done_testing;
