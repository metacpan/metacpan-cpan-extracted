use strict;
use warnings;
use Test::More;
use t::Util;

test('use in comment', <<'END', {}, {}, used(qw/Apache::DBI/));
BEGIN {
    # Only use Apache::DBI on dev.
    if (-f '/var/run/httpd-dev01') {
        # Must be loaded before DBI.
        require Apache::DBI;
        Apache::DBI->import();
    }
}
END

test('require in comment', <<'END', used(qw/Apache::DBI/));
# require Apache::DBI
require Apache::DBI
END

test('everything is in comment', <<'END', used());
# require Apache::DBI
# require Apache::DBI
END

test('irrelevant comment', <<'END', used(qw/Apache::DBI/));
# foo
require Apache::DBI
END

test('use in comment', <<'END', used(qw/Apache::DBI/));
# use some Apache::DBI, yo
require Apache::DBI
END

test('use in comment', <<'END', used(qw/Apache::DBI/));
# require Apache::DBI
use Apache::DBI
END

test('use in comment', <<'END', used(qw/Apache::DBI/));
# yo, require Apache::DBI
require Apache::DBI
END

test('trailing comments', <<'END', {perl => '5.008', strict => 0, warnings => 0});
use 5.008; # Because we want to
# Another comment

use strict;
use warnings;
END

done_testing;
