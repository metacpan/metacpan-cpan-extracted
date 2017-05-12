# PDA::Simple

PDA::Simple - Push Down Automaton Simple

# SYNOPSIS

    use PDA::Simple;
    use Data::Dumper;  # for demonstration.

    # create PDA::Simple object.
    my $pda = PDA::Simple->new();

    # add states
    $pda->add_state('A');
    $pda->add_state('B');

    # add transition from initial state with stack ops
    $pda->add_trans_from_init('A','a','push');

    # add transition FROM and TO with stack ops
    $pda->add_trans('A','A','a','push');
    $pda->add_trans('A','B','b','pop');
    $pda->add_trans('B','B','b','pop');

    # add transition to final state with stack ops
    $pda->add_trans_to_final('__INIT__','b','pop');

    # define input array.
    my $array = ['a','a','a','a','b','b','b','b'];

    # run

    for( 0 .. $#$array ){
        if(my $hash = $pda->transit($array->[$_],'')){
            print "HIT!\n";
            print Dumper $hash->{stack_a};
        }
    }

# DESCRIPTION

PDA::Simple is simple module for generating Push Down Automaton(PDA).

# METHODS

## _add\_state_

Add state.

    $pda->add_state('A');

## _add\_trans_

Add transition function.

    $operation = 'push'; # "push" or "pop" or "no"
    $pda->add_trans('FROM','TO','INPUT',$operation);

## _add\_trans\_from\_init_

Add transition function specialized to INIT state.

    $pda->add_trans_from_init('TO','INPUT','push');

## _add\_trans\_to\_final_

Add transition function specialized to FINAL state.

    $pda->add_trans_to_final('FROM','INPUT','pop');

## _transit_

Transition.

This method returns inner state(stacks) if it reaches to acceptable state.

    my $hash = $pda->transit('INPUT','ADDITIONAL_ATTRIBUTES');

# LICENSE

Copyright (C) Toshiaki Yokoda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Toshiaki Yokoda <>
