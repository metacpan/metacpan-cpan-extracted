#!perl -T

use Test::More tests => 7;

my @list = qw/foo bar baz/;
my $expected = join q{ }, @list;

# q test
use PerlX::QuoteOperator quc => { -emulate => 'q', -with => sub ($) { uc $_[0] } };
is quc/$expected/, uc('$expected'), 'basic q test';

# qq test
use PerlX::QuoteOperator qquc => { -emulate => 'qq', -with => sub ($) { uc $_[0] } };
is qquc{$expected}, uc($expected), 'basic qq test';

# qw test
use PerlX::QuoteOperator qwuc => { -emulate => 'qw', -with => sub (@) { @_ } };
is_deeply [qwuc/foo bar baz/], \@list, 'basic qw test';

# retest in case import issues
is quc($expected), uc('$expected'), 'basic q re-test';

# qw sub test
is_deeply [ flip( qwuc/foo bar baz/ ) ], [ reverse @list ], 'basic qw sub test'; 

# multi-line
is quc{foo
bar
baz}, uc(join "\n", @list), 'basic q multi-line test';

# leading and trailing spaces
is qquc/ $expected /, uc( ' '.$expected.' ' ), 'basic qq spaces test';

sub flip {
    reverse @list;
}