
my $webhook = Slack::WebHook->new( url => '...' );

# message without a title using a custom color
$webhook->post_ok( { text => 'Hello World! in black', color => '#000' );

# message with a title using a custom color
$webhook->post_warning( { title => 'My Title', text => 'Hello World! in red', color => '#cc0000' );