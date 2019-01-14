#!perl

use strict;
use warnings;

use Perl::Critic;
use Perl::Critic::Utils qw{ :severities };
use Test::More;

use Data::Dumper;

use constant POLICY => 'Perl::Critic::Policy::TooMuchCode::ProhibitLargeBlock';

{
    my $pc = Perl::Critic->new( -only => 1 );
    $pc->add_policy( -policy => POLICY, -params => { block_statement_count_limit => 20 } );

    my $code = q~
        use strict;
        map {
            print 42;
            print 42;
            print 42;
            print 42;
            print 42;
            print 42;
            print 42;
            print 42;
            print 42;
            print 42;
            print 42;
            print 42;
        } (1...100)
    ~;
    my @violations = $pc->critique( \$code );
    ok !@violations;
}

done_testing();
