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
is ($foo, 1, 'foo is now 1');

$b->add_listener(sub { shift; $foo++ if length(shift->text) == 10 } );

my $msg3 = { message_id => 123457, text => "hellohello", date => 12346, from => { id => 444 } };

$b->_process_message( { message => $msg3 } );
is ($foo, 3, 'foo is 3 - both listeners triggered');

my $msg4 = { message_id => 123457, text => "chimpthere", date => 12346, from => { id => 444 } };

$b->_process_message( { message => $msg4 } );
is ($foo, 4, 'foo became');

# check that edited messages get reprocessed

$b->_process_message( { edited_message => $msg4 } );
is ($foo, 5, 'foo is 5, edited message triggered listener again');

# check that unknown fields no longer die

$b->_process_message( { some_unknown_field => $msg4 } );
is ($foo, 5, 'foo still 5 but Brain no longer dies' );

done_testing();