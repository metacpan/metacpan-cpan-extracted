#!perl

use strict;

use Perl::Critic ();
use Perl::Critic::Utils qw{ :severities };
use Test::More;

use constant POLICY =>
    'Perl::Critic::Policy::TooMuchCode::ProhibitUnusedImport';

{
    my $pc = Perl::Critic->new( -only => 1 );
    $pc->add_policy(
        -policy => POLICY,
        -params => { ignored_modules => 'Test::Thingy' },
    );

    my $code = q~
        use strict;
        use Git::Sub qw( push );
        use Test::Thingy qw( Some::Module );

        git::push qw(--tags origin master);
    ~;
    my @violations = $pc->critique( \$code );
    ok( !@violations, 'no violations' );
}

done_testing();
