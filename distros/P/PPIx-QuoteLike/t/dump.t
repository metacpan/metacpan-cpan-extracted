package main;

use 5.006;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

use PPIx::QuoteLike::Constant ();
use PPIx::QuoteLike::Dumper;

local @PPIx::QuoteLike::Constant::CARP_NOT = (
    @PPIx::QuoteLike::Constant::CARP_NOT, 'My::Module::Test' );

is _dump( '"foo$bar"' ), <<'EOD', 'Dump "foo$bar"';

"foo$bar"
PPIx::QuoteLike	"..."	failures=0	interpolates=1
  PPIx::QuoteLike::Token::String	'foo'
  PPIx::QuoteLike::Token::Interpolation	'$bar'
EOD

is _dump( \<<'EOF', perl_version => 1, variables => 1 ),
use strict;
use warnings;

my $bar = 'buzz';
my $baz = "Burfle";
my $name = q <Bright>;
my $speed = qq{light};

print "foo$bar->@*\F$baz\E\n";

print <<EOD
There was a young lady named $name
Who could travel much faster than $speed
    She set out one day
    In a relative way
And returned the previous night
EOD
EOF
    <<'EOF',

'buzz' ? line 4 column 11
PPIx::QuoteLike	'...'	failures=0	interpolates=0	5.000 <= $]
  PPIx::QuoteLike::Token::String	'buzz'	5.000 <= $]

"Burfle" ? line 5 column 11
PPIx::QuoteLike	"..."	failures=0	interpolates=1	5.000 <= $]
  PPIx::QuoteLike::Token::String	'Burfle'	5.000 <= $]

q <Bright> ? line 6 column 12
PPIx::QuoteLike	q<...>	failures=0	interpolates=0	5.000 <= $]
  PPIx::QuoteLike::Token::String	'Bright'	5.000 <= $]

qq{light} ? line 7 column 13
PPIx::QuoteLike	qq{...}	failures=0	interpolates=1	5.000 <= $]
  PPIx::QuoteLike::Token::String	'light'	5.000 <= $]

"foo$bar->@*\F$baz\E\n" ? line 9 column 7
PPIx::QuoteLike	"..."	failures=0	interpolates=1	5.019005 <= $]	$bar,$baz
  PPIx::QuoteLike::Token::String	'foo'	5.000 <= $]
  PPIx::QuoteLike::Token::Interpolation	'$bar->@*'	5.019005 <= $]	$bar
  PPIx::QuoteLike::Token::Control	'\\F'	5.015008 <= $]
  PPIx::QuoteLike::Token::Interpolation	'$baz'	5.000 <= $]	$baz
  PPIx::QuoteLike::Token::Control	'\\E'	5.000 <= $]
  PPIx::QuoteLike::Token::String	'\\n'	5.000 <= $]

<<EOD ? line 11 column 7
PPIx::QuoteLike	<<EOD...EOD	failures=0	interpolates=1	5.000 <= $]	$name,$speed
  PPIx::QuoteLike::Token::String	'There was a young lady named '	5.000 <= $]
  PPIx::QuoteLike::Token::Interpolation	'$name'	5.000 <= $]	$name
  PPIx::QuoteLike::Token::String	'
Who could travel much faster than '	5.000 <= $]
  PPIx::QuoteLike::Token::Interpolation	'$speed'	5.000 <= $]	$speed
  PPIx::QuoteLike::Token::String	'
    She set out one day
    In a relative way
And returned the previous night
'	5.000 <= $]
EOF
    'Dump a file';

done_testing;

sub _dump {
    my ( @arg ) = @_;
    package
    My::Module::Test;	# Cargo cult to hide from CPAN indexer
    return scalar PPIx::QuoteLike::Dumper->dump( @arg );
}

1;

# ex: set textwidth=72 :
