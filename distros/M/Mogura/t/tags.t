use strict;
use warnings;
use utf8;
use Test::More;
use lib 'lib';
use Mogura::Server::Tags;

is_deeply(
    Mogura::Server::Tags->validate([' production', '日本語', 'web', 'production', '', ' ']),
    ['production', '日本語', 'web'],
    'Whitespace, blanks, and duplicate tags are normalized'
);
is_deeply(Mogura::Server::Tags->validate([]), [], 'Tags are optional');
for my $invalid ([{}], [undef], ["bad\nvalue"], ['x' x 121], [('tag') x 21]) {
    ok(
        !eval { Mogura::Server::Tags->validate($invalid); 1 },
        'Malformed or excessive tags are rejected'
    );
}
my $input = [' padded '];
Mogura::Server::Tags->validate($input);
is_deeply($input, [' padded '], 'Validation does not mutate its input');

done_testing;
