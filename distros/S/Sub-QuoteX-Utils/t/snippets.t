#! perl

use Test2::Bundle::Extended;

use Sub::QuoteX::Utils qw[ quote_subs ];

my @results;

sub chunk_as_func {

    push @results, @_;
}

my $boolean;

my $coderef = quote_subs(
    \'if ( $$boolean ) {', [ \&chunk_as_func, args => ['true'] ],
    \'} else {',           [ \&chunk_as_func, args => ['false'] ],
    \'};', { capture => { '$boolean' => \\$boolean } },
);

$boolean = 0;
&$coderef;

is( \@results, ['false'], "conditional: false" );

$boolean = 1;
&$coderef;
is( \@results, [ 'false', 'true' ], "conditional: true" );

done_testing;
