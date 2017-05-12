use Mojo::Base -strict;
use Test::More;

use_ok 'Mojar::Message';
diag "Testing Mojar::Message $Mojar::Message::VERSION, Perl $], $^X";
use_ok 'Mojar::Message::BulkSms';

done_testing();
