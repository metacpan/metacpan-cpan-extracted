#!perl

use Slack::WebHook ();

my $hook = Slack::WebHook->new( 
		url => 'https://hooks.slack.com/services/xxxx/xxxx...' 
);

# using some preset decorations with markdown syntax enabled
$hook->post_ok( 'a pretty _green_ message' );
$hook->post_warning( 'a pretty _orange_ message' );
$hook->post_error( 'a pretty _red_ message' );
$hook->post_info( 'a pretty _blue_ message' );

# this is similar to the previous syntax
$hook->post_ok( text => 'a pretty _green_ message' );

# you can also set a title and a body to your message
# with any of the post_* methods
$hook->post_ok( # or any other post_* method
	title   => ':camel: My Title',
	text    => qq[A multiline\ncontent as an example],
);

# you can also set your own color if you want
$hook->post_info( # or any other post_* method
	color   => '#00cc00',
	text    => q[Hello, World! in green],
);

{
	# using timers for your tasks
	$hook->post_start( 'starting some task' );
	sleep( 1 * 3600 + 12 * 60 + 45 ) if 0; # 1 hour 12 minutes 45 seconds
	$hook->post_end( 'task is now finished' );
	# automatically adds the run time at the end of your message:
	#	"\nrun time: 1 hour 12 minutes 45 seconds" 
}

# using a custom color to a notification
$hook->post_end( text => 'task is now finished in black', color => '#000' );

# you can also post your own custom message without any preset styles
#	this allow you to bypass the custom layout and provide your own hash struct
#	which will be converted to JSON before posting the message
$hook->post( 'posting a raw message' );
$hook->post( { text => 'Hello, World!'} );