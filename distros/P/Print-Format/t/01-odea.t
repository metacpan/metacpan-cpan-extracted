use Test::More;
use Print::Format qw/form/;

=pod
form my $STDOUT => q{
                ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
                                        &white Bug Reports
                @<<<<<<<<<<<<<<<<<<<<<<<40 @|||||||||||||20 @>>>>>>>>>>>>>>>40
                &yellow $system              &red $number    &green $date
                **************************************************************
                &black_on_white -
                <<<<<<<<<<<<<<20. @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<80
                Subject: $subject
                <<<<<20. @<<<<<<<<<<<<<<<<<<<<<<<40 ^<<<<<<<<<<<<<<<<<<<<<<<40
                Index:   $index                      $description
                <<<<<20. @<<<<<<10 >>>>>>20.@<<<<10 ^<<<<<<<<<<<<<<<<<<<<<<<40
                Priority: $priority     Date: $date  $description
                <<<<<20. @<<<<<<<<<<<<<<<<<<<<<<<40 ^<<<<<<<<<<<<<<<<<<<<<<<40
                From: $from                          $description
                <<<<<20. @<<<<<<<<<<<<<<<<<<<<<<<40 ^<<<<<<<<<<<<<<<<<<<<<<<40
                Assigned To: $programmer             $description
                <<<<<<<<<<<<<<<<<<<<<30 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<70 ~~
                $description
                **************************************************************
                =
                @<<<<<<<<<<<<<25 @<<<<<<<<<<<<25 @<<<<<<<<<<<25 @<<<<<<<<<<<25
                @headers[|]
                *************************************************************
                =
                @<<<<<<<<<<<25~~ @<<<<<<<<<25~~ @<<<<<<<<<<25~~ @<<<<<<<<<25~~ ~~
                @rows[|]
                *************************************************************
                =
                @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<50 @<<<<<<<<<<<<<<<<<<<<<<<<<<50 ~~
                &custom_list [-]@list &custom_numbered_list [$#)]@list
};
=cut

my $form = q{
|100
Bug Reports
@<<<<<<<<<<<<<<<<<<<<<<<40 @|||||||||||||20 @>>>>>>>>>>>>>>>40
$system              	   $number    	    $date
*100
-
<<<<<<<<<<<<<<20. @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<80,
Subject: $subject 
<<<<<20. @<<<<<<<<<<<<<<<<<<<<<<<40 ^<<<<<<<<<<<<<<<<<<<<<<40
Index:   $index                      $description
<<<<<20. @<<<<<<10 >>>>>>20. @<<<<10 ^<<<<<<<<<<<<<<<<<<<<<40
Priority: $priority     Date: $date  $description
<<<<<<<<<<<<<<<<<<<<<30 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<70 ~~
$description
*100
=
<2 @||24 @||24 @||24 @||24 >2
| @headers[|] |
*100
=
<2 @<<<<<<<<<<<24,~~ @>>>>>24~~ @||||24~~ @<<<<<<<<<24~~ >2 ~~
| @rows[|] |
*100
=
};

form my $STDOUT => $form;

open $STDOUT, '>', STDOUT, 100;

print $STDOUT ( 
	system => 'Some System', 
	number => "100", 
	date => '20251201', 
	subject => "\e[34;1mThis\e[0m is the subject of the line that should get cut off if long enough but we will keep making it longer to make sure\e[0m",
	index => 123,
	description => 'This is the description of the bug report that should span multiple lines, This is the description of the bug report that should span multiple lines. This is the description of the bug report that should span multiple lines. This is the description of the bug report that should span multiple lines. This is the description of the bug report that should span multiple lines.',
	priority => 'High',
	headers => [ 'one', 'two', 'three', 'four' ],
	rows => [
		[ 'abc when this fills more than 24 it needs to take all to the next line', 'def', 'ghi', 'jkl' ],
		[ 1, 2, 3, 4],
		[ 'a', 'b', 'c', 'd'] 
	]
);


print $STDOUT ( 
	system => 'Some System', 
	number => "100", 
	date => '20251201', 
	subject => 'This is the subject of the line that should get cut off if long enough but we will keep making it longer to make sure',
	index => 123,
	description => 'This is the description of the bug report that should span multiple lines, This is the description of the bug report that should span multiple lines. This is the description of the bug report that should span multiple lines. This is the description of the bug report that should span multiple lines. This is the description of the bug report that should span multiple lines.',
	priority => 'High',
	headers => [ 'one', 'two', 'three', 'four' ],
	rows => [
		[ 'abc', 'def', 'ghi', 'jkl' ],
		[ 1, 2, 3, 4],
		[ 'a', 'b', 'c', 'd'] 
	]

);

close $STDOUT;

print "\r\n I print as normal \n\n";

ok(1);

done_testing();
