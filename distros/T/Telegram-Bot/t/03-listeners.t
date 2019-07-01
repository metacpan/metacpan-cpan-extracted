use Test::More;

use_ok ('Telegram::Bot::Brain');

my $b = Telegram::Bot::Brain->new();

my $foo = 0;
$b->add_listener( sub { shift; $foo++ if shift->text =~ /hello/ } );

my $msg1 = { message_id => 123456, text => "goodbye", date => 12346, from => { id => 444 } };

$b->_process_message( { message => $msg1 } );
ok (! $foo, 'foo still 0');

my $msg2 = { message_id => 123457, text => "hello", date => 12346, from => { id => 444 } };

$b->_process_message( { message => $msg2 } );
is ($foo, 1, 'foo 1');

$b->add_listener(sub { shift; $foo++ if length(shift->text) == 10 } );

my $msg3 = { message_id => 123457, text => "hellohello", date => 12346, from => { id => 444 } };

$b->_process_message( { message => $msg3 } );
is ($foo, 3, 'foo 3');

my $msg4 = { message_id => 123457, text => "chimpthere", date => 12346, from => { id => 444 } };

$b->_process_message( { message => $msg4 } );
is ($foo, 4, 'foo 4');

done_testing();
