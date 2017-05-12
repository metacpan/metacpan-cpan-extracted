package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use parent 'Test::Siebel::Srvrmgr::ListParser::Output::Tabular';

sub class_methods : Tests(+1) {

    my $test = shift;

    my $expected = {
        'Server Request Processor' => {
            'CT_NAME'           => 'Server Request Processor (SRP)',
            'CG_NAME'           => 'Auxiliary System Management',
            'CC_INCARN_NO'      => '0',
            'CC_DISP_ENABLE_ST' => 'Active',
            'CC_NAME'           => 'Server Request Processor',
            'CG_ALIAS'          => 'SystemAux',
            'CC_RUNMODE'        => 'Interactive',
            'CC_ALIAS'          => 'SRProc',
            'CC_DESC_TEXT' =>
'Server Request scheduler and request/notification store and forward processor'
        }
    };

    is_deeply( $test->get_output()->get_data_parsed(),
        $expected, 'get_parsed_data returns the correct data structure' );

}

1;
