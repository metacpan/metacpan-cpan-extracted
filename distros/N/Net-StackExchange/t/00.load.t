use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
    use_ok('Net::StackExchange'                   );
    use_ok('Net::StackExchange::Core'             );
    use_ok('Net::StackExchange::Owner'            );
    use_ok('Net::StackExchange::Answers'          );
    use_ok('Net::StackExchange::Answers::Request' );
    use_ok('Net::StackExchange::Answers::Response');
}
