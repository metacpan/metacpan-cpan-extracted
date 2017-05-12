
# $Id$

use strict;
use warnings;
use Test::More tests => 3;
use Env qw($TEST_VERBOSE);

use_ok 'Perl::Critic::Policy::logicLAB::RequireSheBang';

require Perl::Critic;

my $critic = Perl::Critic->new(
    '-profile'       => 't/PCPLRSB-6.conf',
    '-single-policy' => 'logicLAB::RequireSheBang'
);

{
my $str = <<'EOS';
#!/usr/bin/perl -T

use strict;
use warnings;

say "Hello World";
EOS

    my @violations = $critic->critique( \$str );
    is(scalar @violations, 0, "asserting no violations for: $str");
}

{
my $str = <<'EOS';
#!/usr/bin/perl

use strict;
use warnings;

say "Hello World";
EOS

    my @violations = $critic->critique( \$str );
    is(scalar @violations, 1, "asserting violations for: $str");
}
