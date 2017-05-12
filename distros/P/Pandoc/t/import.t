use strict;
use Test::More;
use Test::Exception;

BEGIN {
    require Pandoc;
    if ($ENV{RELEASE_TESTING}) {
        Pandoc->import(qw(-t latex));
    } else {
        plan skip_all => 'these tests are for release candidate testing';
    }
}

is_deeply [ pandoc->arguments ], [qw(-t latex)], 'import with arguments';

throws_ok { Pandoc->VERSION(99) } qr/^pandoc 99 required/, '!use Pandoc 99';
throws_ok { Pandoc->import(99) } qr/^pandoc 99 required/, '!use Pandoc qw(99 ...)';

lives_ok { Pandoc->VERSION(pandoc->version) } "use Pandoc ".pandoc->version;
lives_ok { Pandoc->VERSION('1.9') } "use Pandoc 1.9";
lives_ok { Pandoc->VERSION('v1') } "use Pandoc 'v1'";

done_testing;
