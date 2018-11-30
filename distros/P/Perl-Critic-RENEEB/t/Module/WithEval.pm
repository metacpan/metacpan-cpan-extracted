package t::Module::WithEval;

# ABSTRACT: This module does nothing 

sub test {
    eval { say "hello" };

    eval "say 'hello'";
}

1;
