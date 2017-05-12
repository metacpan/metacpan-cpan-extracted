use strict;
use warnings;
use Benchmark qw( cmpthese );
use Test::More;
use XML::Simple;
use RDF::Sesame::Response;
use RDF::Sesame::TableResult;

my @tests = qw( a );

plan tests => 1;

my $test = shift @ARGV;
my $xml = slurp("t/$test.xml");
my $bin = slurp("t/$test.bin");

# make sure the conversions agree before proceeding
#$XML::SAX::ParserPackage = 'XML::SAX::PurePerl';
is_deeply(
    process_xml($xml),
    process_bin($bin),
) or die "Disagreement\n";

cmpthese(400, {
    xml => sub { process_xml($xml) },
    bin => sub { process_bin($bin) },
});

sub process_xml {
    my ($xml) = @_;
    $xml =~ s#<tuple>(.*?)</tuple>#RDF::Sesame::Response::_fix_tuple($1)#siegx;

    my $parsed = XMLin(
        $xml,
        ForceArray => [
            qw(repository status notification
                columnName tuple  attribute  
                error                         )
        ],
        KeyAttr    => [ ],
    );

    my ($head, $tuples) = RDF::Sesame::TableResult::_parse_xml($parsed, 0, 0);
    return $tuples;
}

sub process_bin {
    my ($bin) = @_;
    my ($head, $tuples) = RDF::Sesame::TableResult::_parse_bin($bin, 0, 0);
    return $tuples;
}

sub slurp {
    my ($filename) = @_;

    local $/;
    open my $fh, '<', $filename or die $!;
    my $data = <$fh>;
    close $fh;
    return $data;
}
