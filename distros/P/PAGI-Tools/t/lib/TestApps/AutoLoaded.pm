package TestApps::AutoLoaded;

use strict;
use warnings;
use Future::AsyncAwait;

sub new { my ($class) = @_; return bless {}, $class }

sub to_app {
    my ($self_or_class) = @_;

    return async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'text/plain']],
        });
        await $send->({ type => 'http.response.body', body => 'autoloaded', more => 0 });
    };
}

1;
