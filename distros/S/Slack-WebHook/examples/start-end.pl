
my $hook = Slack::WebHook->new( url => 'https://...' );

# simple start / end
$hook->post_start( 'starting some task' );
sleep( 1 * 3600 + 12 * 60 + 45 ); # 1 hour 12 minutes and 45 seconds
$hook->post_end( 'task is now finished' );

# using start / end with title and custom color
$hook->post_start( title => "Starting Task 42", text => "description..." );
sleep( 18 );
$hook->post_end( title => "Task 42 is now finished", color => "#000", text => 'task is now finished' );
