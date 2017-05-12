#!/usr/local/bin/perl

use lib 'blib/lib';

$| = 1;

use ProLite qw(:core :commands :colors :styles :dingbats :effects);

my $s = new ProLite(id=>1, device=>'/dev/ttyS0');

$err = $s->connect();
die "Can't connect to device - $err" if $err;

print "Downloading headlines...\n" unless $ARGV[0] eq '-q';

$s->wakeUp();
$s->setClock();

$s->setPage(26, RESET, dimRed, "-- fetching headlines --");
$s->runPage(26);

$url = "http://slashdot.org/slashdot.rdf";

$data = ${suck($url)};
foreach $line (split "\n", $data)
{
	$item = 1 if ($line =~ /<item>/);
	$item = 0 if ($line =~ /<\/item>/);
	
	($title) = $line =~ /\<title\>(.*)\<\/title\>/;
	$title =~ s/&amp;/&/g;
	
	push @titles, $title if ($title and $item);
}

print "Sending..." unless $ARGV[0] eq '-q';

for($i = 0; $i < scalar@titles; $i+=2)
{
	push @t, red, @titles[$i];
	push @t, RESET, blank;
	push @t, green, @titles[$i+1];
	push @t, RESET, blank;
}

$s->setPage(1, RESET, brightGreen, 
	join('', @t),
) if @titles;

print "Done.\n" unless $ARGV[0] eq '-q';
$s->runPage(1);

sleep 1;

# ---------------------------------------------------------------------------

sub suck
{
        my($url) = @_;

        # Create a user agent object
        use LWP::UserAgent;
        my $ua = new LWP::UserAgent;
        $ua->agent("ImageVacuum/1.0 " . $ua->agent);

        # Create a request
        my $req = new HTTP::Request(GET => $url);

        # Pass request to the user agent and get a response back
        my $res = $ua->request($req);

        # Check the outcome of the response
        my $content;
        if ($res->is_success) {
                $content = $res->content_ref();
        } else {
                return undef;
        }

        return $content;
}


