package TestApps::Component;

use strict;
use warnings;
use Future::AsyncAwait;

sub new {
    my ($class, %args) = @_;
    return bless { body => $args{body} // 'component' }, $class;
}

sub to_app {
    my ($self) = @_;
    my $body = ref($self) ? $self->{body} : 'component';

    return async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'text/plain']],
        });
        await $send->({ type => 'http.response.body', body => $body, more => 0 });
    };
}

1;
