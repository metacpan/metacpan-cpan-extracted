#!perl -T

use warnings;
use strict;

use Test::More tests => 3;
use lib qw( lib );

use Parse::Flash::Cookie;
ok(1);

# test missing or undefined filename
eval { Parse::Flash::Cookie::to_text(); };
like($@, qr/missing argument file/i, q{to_text should die when file is missing});

# test filename that does not exist
eval { Parse::Flash::Cookie::to_text(q{/hey_they_cannot_possibly_have_a_file_named_like_this}); };
like($@, qr/no such file/i, q{to_text should die when file is missing});

__END__

