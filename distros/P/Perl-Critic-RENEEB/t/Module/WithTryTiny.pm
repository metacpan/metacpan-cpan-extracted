package t::Module::WithTryTiny;

# ABSTRACT: This module does nothing 

use Try::Tiny;

sub test {
    try { say "hello" } catch { say "Fehler" };

    eval "print 'hello'"; # string evals aren't catched with the BlockEval policy
}

1;
