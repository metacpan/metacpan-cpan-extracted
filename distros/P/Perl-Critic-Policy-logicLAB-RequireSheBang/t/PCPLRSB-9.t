
# $Id$

use strict;
use warnings;
use Test::More tests => 2;
use Env qw($TEST_VERBOSE);

use_ok 'Perl::Critic::Policy::logicLAB::RequireSheBang';

require Perl::Critic;

my $critic = Perl::Critic->new(
    '-profile'       => 't/PCPLRSB-9.conf',
    '-single-policy' => 'logicLAB::RequireSheBang'
);

{
my $str = <<'EOS';
#!/usr/local/bin/perl

use strict;
use warnings;

say "Hello World";
EOS

    my @violations = $critic->critique( \$str );
    is(scalar @violations, 0, "asserting no violations for: $str");
}
