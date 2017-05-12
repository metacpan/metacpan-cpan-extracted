use strict;
use Plack::App::DAIA '0.42';
use DAIA;
use LWP::Simple qw(get);

#
# This script shows how to create a DAIA server with 
# Plack::App::DAIA. You can  run this server with:
#
# $ plackup ubbielefeld.pl
#

# Only use pQuery if this CPAN module is installed
our $pQuery;
BEGIN { eval { use pQuery; }; $pQuery = !$@; };


my $app = Plack::App::DAIA->new( 
    code     => \&retrieve,
    idformat => qw{^(http://katalog.ub.uni-bielefeld.de/title/)?[0-9]+$},
    html     => 1,
);

sub retrieve {
    my $id = shift;
    my $daia = DAIA::Response->new;

    $daia->institution(
        content => "Universit\xE4tsbibliothek Bielefeld", # Name
        href    => "http://www.ub.uni-bielefeld.de/",     # Homepage
        id      => "http://lobid.org/organisation/DE-361" # URI (Linked Data)
    );
      
    $id = 'http://katalog.ub.uni-bielefeld.de/title/' . $id unless $id =~ /^http/;

    my $html = get($id);
    if (!$html or $@) {
        $daia->addMessage( "Failed to retrieve title data", errno => 503 );
        return $daia;
    }

    if ($html !~ /<div\s+class\s*=\s*["']\s*ex["']/ms) {
        $daia->addMessage( "Document not found", errno => 404 );
        return $daia;
    }

    my $doc = DAIA::Document->new( id => $id, href => $id );
    if ( $pQuery ) {

        # dirty old screen scraping
        pQuery( $html )->find(".ex")->find("table")->find('tr')->each(sub {
            return unless shift; # skip first row

            my $item = DAIA::Item->new;
            
            my $td = pQuery($_)->find('td');

            if ( my $standort = $td->get(0) ) {
                if ( $standort->find('a') ) {
                    $standort = $standort->firstChild;
                    my $url = $standort->getAttribute('href');
                    $item->department( "".$standort->innerHTML, href => $url );
                } else {
                    $item->department( "".$standort->innerHTML );
                }
            }
            if ( my $storage = $td->get(1) ) {
                $item->storage( "".$storage->innerHTML );
            }
            if ( my $label = $td->get(2) ) {
                $item->label( "".$label->innerHTML );
            }

            my $loan   = eval { $td->get(4)->innerHTML; } || "";
            my $status = eval { $td->get(5)->innerHTML; } || "";
            my $queue  = eval { 1 * $td->get(6)->innerHTML; } || 0;
            
            if ( $status =~ /Entliehen bis (\d\d)\.(\d\d)\.(\d\d\d\d)/ ) {
                $item->addUnavailable( service => "loan", expected => "$3-$2-$1", href => $id );
                $item->addUnavailable( service => "presentation", expected => "$3-$2-$1" );
            } elsif( $loan =~ /Nicht ausleihbar/ ) {
                $item->addUnavailable( service => "loan" );
            } else {
                # probably you can get it (fuzzy heruistic)
                $item->addAvailable( service => "loan" );
                $item->addAvailable( service => "presentation" );
            }

            $doc->addItem($item);
        });
    }

    $daia->document( $doc );

    return $daia;
}

$app;

__END__
#
# You can test the running server with Plack::App::DAIA::Test via:
#
# plackup examples/daia-ubbielefeld.pl
# provedaia -s http://localhost:5000 --end examples/daia-ubbielefeld.pl
#
# or without plackup via:
# provedaia -c examples/daia-ubbielefeld.pl
#
#

218777
http://katalog.ub.uni-bielefeld.de/title/218777

base=http://katalog.ub.uni-bielefeld.de/title

# found at least one item
{ "document" : [ { } ] }

# item must have the right URI
{ "document" : [ { 
    "id" : "$base/218777",
    "item": [ { } ]
} ] }

