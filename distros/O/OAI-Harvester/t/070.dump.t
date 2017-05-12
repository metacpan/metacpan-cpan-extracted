use Test::More tests => 6;
use File::Path;  # core
use IO::Dir;     # core
use strict;
use warnings;

$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

sub xmlFiles {
    my $dir = IO::Dir->new(shift);
    my @xmlFiles;
    while (my $file = $dir->read()) {
        next if $file =~ /^\./;
        push @xmlFiles, $file;
    }
    return @xmlFiles;
}


# this test uses the dumpDir option for keeping xml files in a directory

# clean up dumping ground if necessary
rmtree 't/dump' if -d 't/dump';
mkdir 't/dump';

my $repo = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [
    baseURL => $repo,
    dumpDir => 't/dump'
]);

my $records = $h->listIdentifiers(metadataPrefix => 'oai_dc');

SKIP: {
    my $HTE = HTE($records, $repo);
    skip $HTE, 4 if $HTE;

    # look for xml files
    my @xmlFiles = xmlFiles('t/dump');

# is one still there?
    is scalar(@xmlFiles), 1, 'found an xml file';
    is $xmlFiles[0], '00000000.xml', 'has the correct format';

# does it look like oai xml?
    open XML, "t/dump/$xmlFiles[0]";
    my $xml = '';
    while (my $line = <XML>) {$xml .= $line};
    close XML;

    like $xml,
         qr{<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/}, 
         'looks like an oai-pmh response';

   # get another 
   $records = $h->listIdentifiers(metadataPrefix => 'oai_dc');

   @xmlFiles = xmlFiles('t/dump');
   is scalar(@xmlFiles), 2, 'found another xml file';

}

# final cleanup
rmtree 't/dump' if -d 't/dump';



sub HTE {
    my ($r, $url) = @_;
    my $hte;
    if ( my $e = $r->HTTPError() ) {
        $hte = "HTTP Error ".$e->status_line;
	$hte .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
	diag("LWP condition accessing $url:\n$hte");
        note explain $e;
      }
   return $hte;
}

