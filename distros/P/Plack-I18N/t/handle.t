use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;

use Plack::I18N::Handle;

subtest 'returns language' => sub {
    my $handle = _build_handle(language => 'foo');

    is $handle->language, 'foo';
};

subtest 'returns localized message' => sub {
    my $handle = _build_handle(language => 'foo');

    is $handle->loc('foo'), 'translated';
};

subtest 'returns localized message with maketext method' => sub {
    my $handle = _build_handle(language => 'foo');

    is $handle->maketext('foo'), 'translated';
};

sub _build_handle {
    my $handle = Test::MonkeyMock->new;
    $handle->mock(maketext => sub { 'translated' });

    return Plack::I18N::Handle->new(
        handle => $handle,
        @_
    );
}

done_testing;
