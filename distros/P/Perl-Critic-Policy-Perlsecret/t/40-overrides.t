#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::Fatal 'dies_ok';
use Test::More tests               => 6;
use Perl::Critic::Policy::Perlsecret;
use Perl::Critic::TestUtils qw( pcritique );

my $policy = Perl::Critic::Policy::Perlsecret->new(
    allow_secrets    => 'Venus',
    disallow_secrets => 'Baby Cart, Venus',
);

my @parameters = $policy->supported_parameters();

is_deeply \@parameters,
    [
    {   'name'           => 'allow_secrets',
        'default_string' => '',
        'description'    => 'A list of perlsecrets to allow.'
    },
    {   'description' =>
            'A list of perlsecrets to disallow (default: all perlsecrets).',
        'name' => 'disallow_secrets',
        'default_string' =>
            'Venus, Baby Cart, Bang Bang, Inchworm, Inchworm on a Stick, Space Station, Goatse, Flaming X-Wing, Kite, Ornate Double Edged Sword, Flathead, Phillips, Torx, Pozidriv, Winking Fat Comma, Enterprise, Key of Truth, Abbott and Costello'
    }
    ],
    'Correct parameters';

# Venus
my $code = <<'__CODE__';
	    print 0+ '23a';
	    #print +0 '23a'; should not be detected as is a comment
	    print +0 '23a';
        ( 'foo' => 'bar' )!!x$baz;
	}
__CODE__

my $config
    = { allow_secrets => 'Venus', disallow_secrets => 'Baby Cart, Venus' };

is pcritique( 'Perlsecret', \$code, $config ), 0,
    '0 x Venus expected, as Venus allowed';

dies_ok { pcritique( 'Perlsecret', \$code, { disallow_secrets => 'no_chance' } ) }
    'Croaks if invalid disallow_secrets set';

# Baby cart
$code = <<'__CODE__';
    print "@{[function_call()]}";
__CODE__

is pcritique( 'Perlsecret', \$code, $config ), 1,
    '1 x Baby Cart expected';

# Bang Bang
$code = <<'__CODE__';
    !!$var;
__CODE__

is pcritique( 'Perlsecret', \$code, $config ), 0,
    'No violations found because Bang Bang not disallowed';

is pcritique( 'Perlsecret', \$code, {} ), 1,
    'Bang Bang is in the default disallow';
