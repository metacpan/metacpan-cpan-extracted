use strict;
use Test;
BEGIN { plan tests => 89 }
use Shell::Parser;

my $parser = new Shell::Parser;

my %sh_tokens = (
    'case'  => 'keyword',  'do'    => 'keyword', 
    'for'   => 'keyword',  'if'    => 'keyword', 
    'while' => 'keyword', 
    
    'alias' => 'builtin',  'break' => 'builtin', 
    'cd'    => 'builtin',  'eval'  => 'builtin', 
    'read'  => 'builtin',  'shift' => 'builtin', 
);

my %csh_tokens = (
    'case'   => 'keyword',  'foreach' => 'keyword',  
    'if'     => 'keyword',  'while'   => 'keyword', 
    
    'alias'  => 'builtin',  'break'   => 'builtin', 
    'cd'     => 'builtin',  'eval'    => 'builtin', 
    'onintr' => 'builtin',  'shift'   => 'builtin', 
);

my @sh_shells  = qw(korn88 korn93 bash zsh);
my @csh_shells = qw(csh tcsh);

# default syntax is 'bourne'
ok( $parser->syntax, 'bourne'                                   );
ok( $parser->syntax, $parser->{syntax}                          );
for my $token (keys %sh_tokens) {
    ok( $parser->{lookup_hash}{$token}, $sh_tokens{$token}         );
}

# change syntax to korn88, korn93, bash, zsh
for my $syntax (@sh_shells) {
    $parser->syntax($syntax);
    ok( $parser->syntax, $syntax                                );
    ok( $parser->syntax, $parser->{syntax}                      );
    for my $token (keys %sh_tokens) {
        ok( $parser->{lookup_hash}{$token}, $sh_tokens{$token}     );
    }
}

# change syntax to csh, tcsh
for my $syntax (@csh_shells) {
    $parser->syntax($syntax);
    ok( $parser->syntax, $syntax                                );
    ok( $parser->syntax, $parser->{syntax}                      );
    for my $token (keys %csh_tokens) {
        ok( $parser->{lookup_hash}{$token}, $csh_tokens{$token}     );
    }
}
