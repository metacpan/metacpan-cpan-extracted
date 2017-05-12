package PDA::Simple;
use 5.008005;
use Mouse;

our $VERSION = "0.01";

has 'stack_init' => (
    is => 'rw',
    isa => 'Str',
    default => '__INIT__'
    );

has 'init_state' => (
    is => 'rw',
    isa => 'Str',
    default => '__INIT__'
    );
has 'final_state' => (
    is => 'rw',
    isa => 'Str',
    default => '__FINAL__'
    );
has 'acceptable_state' => (
    is => 'rw',
    isa => 'Str',
    default => '__ACCEPTABLE__'
    );
has 'acceptable' => (
    is => 'rw',
    isa => 'Num',
    default => 0
    );
has 'stack_s' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub {[]}
    );

has 'stack_a' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub {[]}
    );

has 'stack_b' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub {[]}
    );

has 'model' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub {
	{
	    '__INIT__' => {},
	    '__FINAL__' => {}
	}
    }
    );

has 'acceptables' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub {{}}
    );



sub add_state{
    my $self = shift;
    my $state_name = shift;
    my $model = $self->model;
    if(defined($model->{$state_name})){
	warn "$state_name : Already exist\n";
    }else{
	$model->{$state_name} = {};
	$self->model($model);
    }
}

sub add_acceptables{
    my $self = shift;
    my $state = shift;
    my $acceptables = $self->acceptables;
    if(($state eq $self->init_state) or ($state eq $self->final_state)){
	warn "can't add acceptables\n";
    }else{
	unless(defined($acceptables->{$state})){
	    $acceptables->{$state} = 1;
	}
    }
}


sub add_trans{
    my $self = shift;
    my $from_state = shift;
    my $to_state = shift;
    my $input = shift;
    my $push_or_pop = shift;
    unless(defined($push_or_pop)){
	$push_or_pop = 'no';
    }
    if(($push_or_pop ne 'push') and ($push_or_pop ne 'pop') and ($push_or_pop ne 'no')){
	$push_or_pop = 'no';
    }
    my $model = $self->model;
    if($from_state eq $self->final_state){
	warn "can't add this transition: from final state\n";
	return 0;
    }elsif($to_state eq $self->init_state){
	warn "can't add this transition: to initial state\n";
	return 0;
    }else{
	if(defined($model->{$from_state})){
	    my $trans_func = $model->{$from_state};
	    if(defined($trans_func->{$input})){
		warn "$input : $from_state : Already exists\n";
		return 0;
	    }else{
		$trans_func->{$input} = {
		    to_state => $to_state,
		    operation => $push_or_pop
		};
		$model->{$from_state} = $trans_func;
		return 1;
	    }
	}else{
	    warn "$from_state : No such state.\n";
	    return 0;
	}
    }
}

sub add_trans_to_final{
    my $self = shift;
    my $from_state = shift;
    my $input = shift;
    my $push_or_pop = shift;
    unless(defined($push_or_pop)){
	$push_or_pop = 'push';
    }
    if(($push_or_pop ne 'push') and ($push_or_pop ne 'pop') and ($push_or_pop ne 'no')){
	$push_or_pop = 'no';
    }

    my $to_state = $self->final_state;
    my $model = $self->model;
    if($from_state eq $self->final_state){
	warn "can't add this transition: from final state\n";
	return 0;
    }else{
	if(defined($model->{$from_state})){
	    my $trans_func = $model->{$from_state};
	    if(defined($trans_func->{$input})){
		warn "$input of $from_state : Already exist\n";
		return 0;
	    }else{
		$trans_func->{$input} = {
		    to_state => $to_state,
		    operation => $push_or_pop
		};
		$model->{$from_state} = $trans_func;
		return 1;
	    }
	}else{
	    warn "$from_state : No such state.\n";
	    return 0;
	}
    }
}

sub add_trans_from_init{
    my $self = shift;
    my $to_state = shift;
    my $input = shift;
    my $push_or_pop = shift;
    unless(defined($push_or_pop)){
	$push_or_pop = 'push';
    }
    if(($push_or_pop ne 'push') and ($push_or_pop ne 'pop') and ($push_or_pop ne 'no')){
	$push_or_pop = 'no';
    }

    my $from_state = $self->init_state;
    my $model = $self->model;
    if($to_state eq $self->init_state){
	warn "can't add this transition: to initial state\n";
	return 0;
    }else{
	if(defined($model->{$self->init_state})){
	    my $trans_func = $model->{$self->init_state};
	    if(defined($trans_func->{$input})){
		warn "$input of ".$self->init_state." : Already exist\n";
		return 0;
	    }else{
		$trans_func->{$input} = {
		    to_state => $to_state,
		    operation => $push_or_pop
		};
		$model->{$self->init_state} = $trans_func;
		return 1;
	    }
	}else{
	    warn $self->init_state." : No INIT state!!\n";
	    return 0;
	}
    }
}

sub reset_state{
    my $self = shift;
    $self->stack_s([]);
    $self->stack_a([]);
    $self->stack_b([]);
    $self->acceptable(0);
    return 1;
}

sub export_model{
    my $self = shift;
    return($self->model);
}

sub import_model{
    my $self = shift;
    my $model = shift;
    if(defined($model->{$self->init_state}) and
       defined($model->{$self->final_state})){
	$self->model($model);
	return 1;
    }else{
	warn "import_model : this model has no init state or final state\n";
	return;
    }
}

sub transit{
    my $self = shift;
    my $input = shift;
    my $attr = shift;
    my $model = $self->model;
    my $acceptables = $self->acceptables;
    my $stack_s = $self->stack_s;
    my $stack_a = $self->stack_a;
    my $stack_b = $self->stack_b;
    
    my $current_state = $self->init_state;
    if(defined($stack_s->[$#$stack_s])){
	$current_state = $stack_s->[$#$stack_s];
    }else{
	$stack_s = [$self->stack_init];
	$self->stack_s($stack_s);
    }
    print "Current STATE : $current_state\n";
    my $trans = $model->{$current_state};
    if(defined($trans->{$input})){
	my $next_state = $trans->{$input}->{to_state};
	print "Next STATE : $next_state\n";
	if(defined($acceptables->{$next_state})){
	    $self->acceptable(1);
	}
	if($next_state eq $self->final_state){
	    if($trans->{$input}->{operation} eq 'push'){
		push(@$stack_s,$next_state);
	    }elsif($trans->{$input}->{operation} eq 'pop'){
		pop(@$stack_s);
	    }
	    push(@$stack_a,$input);
	    push(@$stack_b,$attr);
	    $self->reset_state();
	    return ({
		state => $next_state,
		stack_s => $stack_s,
		stack_a => $stack_a,
		stack_b => $stack_b
		    });
	}else{
	    if($trans->{$input}->{operation} eq 'push'){
		push(@$stack_s,$next_state);
	    }elsif($trans->{$input}->{operation} eq 'pop'){
		pop(@$stack_s);
	    }
	    if($stack_s->[$#$stack_s] eq $self->stack_init){
		push(@$stack_a,$input);
		push(@$stack_b,$attr);
		$self->reset_state();
		return ({
		    state => $next_state,
		    stack_s => $stack_s,
		    stack_a => $stack_a,
		    stack_b => $stack_b
			});
	    }else{
		push(@$stack_a,$input);
		push(@$stack_b,$attr);
		$self->stack_s($stack_s);
		$self->stack_a($stack_a);
		$self->stack_b($stack_b);
		return;
	    }
	}
    }else{
	if($self->acceptable == 1){
	    push(@$stack_s,$self->acceptable_state);
	    push(@$stack_a,$input);
	    push(@$stack_b,$attr);
	    $self->reset_state();
	    return ({
		state => $self->acceptable,
		stack_s => $stack_s,
		stack_a => $stack_a,
		stack_b => $stack_b
		    });
	}else{
	    $self->reset_state();
	    return;
	}
    }
}

sub delete_dead_state{
    my $self = shift;
    my $model = $self->model;
    my $refered;
    my $delete_count = 0;
    foreach my $key (sort keys %$model){
	my $state = $model->{$key};
	foreach my $input (sort keys %$state){
	    $refered->{$state->{$input}->{to_state}} = 1;
	}
    }
    foreach my $key (sort keys %$model){
	if(($key ne $self->init_state) and ($key ne $self->final_state)){
	    unless(defined($model->{$key}) or defined($refered->{$key})){
		delete $model->{$key};
		$delete_count++;
	    }
	}
    }
    $self->model($model);
    return($delete_count);
}




1;
__END__

=encoding utf-8

=head1 PDA::Simple

PDA::Simple - Push Down Automaton Simple

=head1 SYNOPSIS

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

=head1 DESCRIPTION

PDA::Simple is simple module for generating Push Down Automaton(PDA).

=head1 METHODS

=head2 I<add_state>

Add state.

    $pda->add_state('A');

=head2 I<add_trans>

Add transition function.

    $operation = 'push'; # "push" or "pop" or "no"
    $pda->add_trans('FROM','TO','INPUT',$operation);

=head2 I<add_trans_from_init>

Add transition function specialized to INIT state.

    $pda->add_trans_from_init('TO','INPUT','push');

=head2 I<add_trans_to_final>

Add transition function specialized to FINAL state.

    $pda->add_trans_to_final('FROM','INPUT','pop');

=head2 I<transit>

Transition.

This method returns inner state(stacks) if it reaches to acceptable state.

    my $hash = $pda->transit('INPUT','ADDITIONAL_ATTRIBUTES');


=head1 LICENSE

Copyright (C) Toshiaki Yokoda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Toshiaki Yokoda E<lt>E<gt>

=cut

