#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::Net::Async::Webservice::DHL::Factory;

my ($dhl,$ua) = Test::Net::Async::Webservice::DHL::Factory::without_network;

subtest 'parse failure response' => sub {
    my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?><res:ErrorResponse xmlns:res='http://www.dhl.com' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation= 'http://www.dhl.com err-res.xsd'>
     <Response>
         <ServiceHeader>
             <MessageTime>2014-04-14T15:43:57+01:00</MessageTime>
             <MessageReference>foo</MessageReference>
             <SiteID>testid</SiteID>
         </ServiceHeader>
         <Status>
             <ActionStatus>Error</ActionStatus>
             <Condition>
                 <ConditionCode>111</ConditionCode>
                 <ConditionData>Error in parsing request XML:Error:
                     Datatype error: In element
                     &apos;GlobalProductCode&apos; : Value &apos;&apos;
                     does not match regular expression facet
                     &apos;[A-Z0-9]+&apos;.. at line 26, column 57</ConditionData>
             </Condition>
         </Status>
     </Response></res:ErrorResponse>
XML
    my $reader = $dhl->_xml_cache->reader('{http://www.dhl.com}ErrorResponse');
    my $data = $reader->($xml);

    cmp_deeply(
        $data,
        {
            Response => superhashof({
                Status => {
                    ActionStatus => 'Error',
                    Condition => [
                        {
                            ConditionCode => 111,
                            ConditionData => ignore(),
                        },
                    ],
                },
            }),
        },
        'error response parsed correctly',
    );
};

done_testing;
