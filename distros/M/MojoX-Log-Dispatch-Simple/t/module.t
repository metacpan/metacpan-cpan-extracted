use Test2::V0;
use Log::Dispatch;
use MojoX::Log::Dispatch::Simple;

my $obj;
eval {
    $obj = MojoX::Log::Dispatch::Simple->new(
        dispatch => Log::Dispatch->new,
        level    => 'debug',
    )
};

is( ref $obj, 'MojoX::Log::Dispatch::Simple', 'MojoX::Log::Dispatch::Simple->new' );

done_testing;
