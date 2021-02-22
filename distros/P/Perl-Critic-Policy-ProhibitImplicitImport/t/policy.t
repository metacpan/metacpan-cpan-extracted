#!perl

use strict;
use warnings;

use Perl::Critic ();
use Test2::V0;

use constant POLICY => 'Perl::Critic::Policy::ProhibitImplicitImport';

{
    my $pc = Perl::Critic->new( -only => 1 );
    $pc->add_policy(
        -policy => POLICY,
        -params => { ignored_modules => 'Path::Tinier' },
    );

    my $code = <<'EOF';
        use strict;
        use warnings;
        use lazy;

        use AAA q();
        use BBB qw(
          one
          two
        );
        use CCC ();
        use DDD 4.19;
        use DDP;
        use EEE 4.19 qw( encode_json );
        use FFF 4.19 ();
        use Moose;
        use Path::Tiny;
        use Path::Tinier;
        use Test2::V0;

EOF
    my @violations = map { $_->source } $pc->critique( \$code );
    is(
        \@violations,
        [ 'use DDD 4.19;', 'use Path::Tiny;' ],
        'Path::Tiny violation'
    );
}

done_testing();
