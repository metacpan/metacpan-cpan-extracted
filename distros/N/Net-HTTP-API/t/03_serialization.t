use strict;
use warnings;
use Test::More;

use Net::HTTP::API::Parser::XML;
use Net::HTTP::API::Parser::JSON;
use Net::HTTP::API::Parser::YAML;

ok my $xml_parser = Net::HTTP::API::Parser::XML->new();
ok my $yaml_parser = Net::HTTP::API::Parser::YAML->new();
ok my $json_parser = Net::HTTP::API::Parser::JSON->new();

done_testing;
