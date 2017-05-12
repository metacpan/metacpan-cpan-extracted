use Test::More tests => 48;

use strict;
use warnings;

use Module::ExtractUse;

{
    my $semi   = 'eval "use Test::Pod 1.00;";';
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$semi );

    ok( $p->used( 'Test::Pod' ) );
    ok( $p->used_in_eval( 'Test::Pod' ) );
    ok(!$p->used_out_of_eval( 'Test::Pod' ) );
}

{
    my $nosemi = "eval 'use Test::Pod 1.00';";
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$nosemi );

    ok( $p->used( 'Test::Pod' ) );
    ok( $p->used_in_eval( 'Test::Pod' ) );
    ok(!$p->used_out_of_eval( 'Test::Pod' ) );
}

{
    my $qq = "eval qq{use Test::Pod 1.00}";
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$qq );
    ok( $p->used( 'Test::Pod' ), 'qq brace' );
    ok( $p->used_in_eval( 'Test::Pod' ), 'qq brace' );
    ok(!$p->used_out_of_eval( 'Test::Pod' ), 'qq brace' );
}

{
    my $qq = "eval qq+use Test::Pod+";
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$qq );
    ok( $p->used( 'Test::Pod' ), 'qq plus' );
    ok( $p->used_in_eval( 'Test::Pod' ), 'qq plus' );
    ok(!$p->used_out_of_eval( 'Test::Pod' ), 'qq plus' );
}

{
    my $qq = "eval qq(use Test::Pod)";
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$qq );
    ok( $p->used( 'Test::Pod' ), 'qq paren' );
    ok( $p->used_in_eval( 'Test::Pod' ), 'qq paren' );
    ok(!$p->used_out_of_eval( 'Test::Pod' ), 'qq paren' );
}

{
    my $q = "eval q< use Test::Pod>";
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$q );
    ok( $p->used( 'Test::Pod' ), 'q angle' );
    ok( $p->used_in_eval( 'Test::Pod' ), 'q angle' );
    ok(!$p->used_out_of_eval( 'Test::Pod' ), 'q angle' );
}

{
    my $q = "eval  q/use Test::Pod/";
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$q );
    ok( $p->used( 'Test::Pod' ), 'q slash' );
    ok( $p->used_in_eval( 'Test::Pod' ), 'q slash' );
    ok(!$p->used_out_of_eval( 'Test::Pod' ), 'q slash' );
}

# reported by DAGOLDEN@cpan.org as [rt.cpan.org #19302]
{
    my $varversion = q{my $ver=1.22;
eval "use Test::Pod $ver;"};
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$varversion );

    ok( $p->used( 'Test::Pod' ) );
    ok( $p->used_in_eval( 'Test::Pod' ) );
    ok(!$p->used_out_of_eval( 'Test::Pod' ) );
}

{
    my $varversion = q{my $ver=1.22;
eval 'use Test::Pod $ver';};
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$varversion );

    ok( $p->used( 'Test::Pod' ) );
    ok( $p->used_in_eval( 'Test::Pod' ) );
    ok(!$p->used_out_of_eval( 'Test::Pod' ) );
}


{
    my $semi   = 'eval"use Test::Pod 1.00;";';
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$semi );

    ok( $p->used( 'Test::Pod' ), 'no spaces between eval and expr with semicolon' );
    ok( $p->used_in_eval( 'Test::Pod' ) );
    ok(!$p->used_out_of_eval( 'Test::Pod' ) );
}

{
    my $nosemi = "eval'use Test::Pod 1.00';";
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$nosemi );

    ok( $p->used( 'Test::Pod' ), 'no spaces between eval and expr w/o semicolon' );
    ok( $p->used_in_eval( 'Test::Pod' ) );
    ok(!$p->used_out_of_eval( 'Test::Pod' ) );
}

{
    my $q = "eval { use Test::Pod }";
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$q );
    ok( $p->used( 'Test::Pod' ), 'block' );
    ok( $p->used_in_eval( 'Test::Pod' ), 'block' );
    ok(!$p->used_out_of_eval( 'Test::Pod' ), 'block' );
}

{
    my $q = "eval { use Test::Pod; { use Test::Pod::Coverage; } }";
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$q );
    ok( $p->used( 'Test::Pod' ), 'block in block 1' );
    ok( $p->used_in_eval( 'Test::Pod' ), 'block in block 1' );
    ok(!$p->used_out_of_eval( 'Test::Pod' ), 'block in block 1' );
    ok( $p->used( 'Test::Pod::Coverage' ), 'block in block 1' );
    ok( $p->used_in_eval( 'Test::Pod::Coverage' ), 'block in block 1' );
    ok(!$p->used_out_of_eval( 'Test::Pod::Coverage' ), 'block in block 1' );
}

{
    my $q = "eval { { use Test::Pod; } use Test::Pod::Coverage }";
    my $p = Module::ExtractUse->new;
    $p->extract_use( \$q );
    ok( $p->used( 'Test::Pod' ), 'block in block 2' );
    ok( $p->used_in_eval( 'Test::Pod' ), 'block in block 2' );
    ok(!$p->used_out_of_eval( 'Test::Pod' ), 'block in block 2' );
    ok( $p->used( 'Test::Pod::Coverage' ), 'block in block 2' );
    ok( $p->used_in_eval( 'Test::Pod::Coverage' ), 'block in block 2' );
    ok(!$p->used_out_of_eval( 'Test::Pod::Coverage' ), 'block in block 2' );
}
