
use Log::Any::Adapter;

our ( $method, $messagetext );

Log::Any::Adapter->set(
'Capture' =>
    'format' => 'messages',
    'to' => sub { ( $method, undef, $messagetext ) = @_; },
    'log_level' => 'trace',
);

1;
