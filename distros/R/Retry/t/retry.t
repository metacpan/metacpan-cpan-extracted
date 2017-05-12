use strict;
use warnings;
use Test::More;
use Test::Exception;
use Retry;

{
    my $retry = Retry->new;
    lives_ok {
        $retry->retry(sub { 1 });
    } 'Simple case works';
}

{
    my $retry = Retry->new( retry_delay => 1 );
    my $count = 3;
    lives_ok {
        $retry->retry(sub { die('for dethklok') unless not $count-- });
    } 'Succeed with retries';
}

{
    my $retry = Retry->new( retry_delay => 1, max_retry_attempts => 3 );
    my $count = 3;
    
    lives_ok {
        $retry->retry(sub { die('for dethklok') unless not $count-- });
    } 'Succeed with exactly 3 retries';

    $count = 4;
    dies_ok {
        $retry->retry(sub { die('for dethklok') unless not $count-- });
    } 'Fails with more than 3 retries';
}

{
    my $callbacks = 0;
    my $retry = Retry->new(
        retry_delay => 1,
        failure_callback => sub { $callbacks++; },
    );
    my $count = 3;
    $retry->retry(sub { die('for dethklok') unless not $count-- });

    is($callbacks, 3, "Callback called three times.");
}

{
    my $retry = Retry->new( retry_delay => 1 );
    my $count = 3;
    my $result = $retry->retry(
        sub {
            die('for dethklok') unless not $count--;
            return "win!";
        }
    );
    is($result, 'win!', "Return value from sub was passed through.");
}

done_testing();
