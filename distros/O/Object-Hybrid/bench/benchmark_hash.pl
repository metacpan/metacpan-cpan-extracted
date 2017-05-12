#!/usr/bin/perl

use Benchmark;

use lib './blib/lib', '../blib/lib';

use strict qw(vars subs);

use Object::Hybrid qw(promote); 
my $plain                  =                     {a => 1};
my $blessed                =               bless {a => 1}, 'Foo';
my $hybrid                 = Object::Hybrid->new({a => 1});
my $hybrid_tieable         = Object::Hybrid->new({a => 1}, tieable => 1);
my $hybrid_tieable         = Object::Hybrid->new({a => 1}, tieable => 1);
my $hybrid_tieable_mutable = Object::Hybrid->new({a => 1}, tieable => 1, mutable => 1);
my $hybrid_tieable_caller  = Object::Hybrid->new({a => 1}, tieable => 1, caller  => 1);

use          Tie::Hash; 
my      ($tied, $hybrid_tied, $hybrid_tied_mutable, $hybrid_tied_caller);
foreach ($tied, $hybrid_tied, $hybrid_tied_mutable, $hybrid_tied_caller) {
	tie %$_, 'Tie::StdHash'; 
	     $_->{a} = 1;
}
promote($hybrid_tied); 
promote($hybrid_tied_mutable, mutable => 1); 
promote($hybrid_tied_caller,  caller  => 1); 

{
	package Foo; 
	use overload '*{}' => sub{}; # this makes very tiny slowdown of blessed
}

my $hybrid_class = ref promote({});

my $iterations = 100000;
timethese( $iterations, {

	new                                => sub{ Object::Hybrid->new({}) },          # includes DESTROY() costs
	new2class                          => sub{ Object::Hybrid->new({} => 'Foo') }, # includes DESTROY() costs
	promote                            => sub{ promote({}) },                      # includes DESTROY() costs
	promote2class                      => sub{ promote({} => 'Bar' ) },            # includes DESTROY() costs
	promote_bless                      => sub{ bless {}, $hybrid_class; },         # includes DESTROY() costs
	promote_bless_nodestroy            => sub{ bless {}, 'NO_DESTROY'; },          #       no DESTROY() costs
	
	hybrid                             => sub{ $hybrid->{a} },
	hybrid_method                      => sub{ $hybrid->FETCH('a') },
	hybrid_method_fast                 => sub{ $hybrid->fast->FETCH('a') },
	hybrid_can                         => sub{ $hybrid->can('FETCH') },
	hybrid_can_switch                  => sub{ (tied(%$hybrid)||$hybrid)->can('FETCH') },
	hybrid_can_fast                    => sub{ $hybrid->fast->can('FETCH') },
	
	hybrid_tieable_method              => sub{ $hybrid_tieable->FETCH('a') },
	hybrid_tieable_method_fast         => sub{ $hybrid_tieable->fast->FETCH('a') },
	hybrid_tieable_mutable_method      => sub{ $hybrid_tieable_mutable->FETCH('a') },
	hybrid_tieable_mutable_method_fast => sub{ $hybrid_tieable_mutable->fast->FETCH('a') },
	hybrid_tieable_caller_method       => sub{ $hybrid_tieable_caller->FETCH('a') },
	hybrid_tieable_caller_method_fast  => sub{ $hybrid_tieable_caller->fast->FETCH('a') },
	
	hybrid_tied                        => sub{ $hybrid_tied->{a} },
	hybrid_tied_method                 => sub{ $hybrid_tied->FETCH('a') },
	hybrid_tied_method_fast            => sub{ $hybrid_tied->fast->FETCH('a') },
	hybrid_tied_can                    => sub{ $hybrid_tied->can('FETCH') },
	hybrid_tied_can_switch             => sub{ (tied(%$hybrid_tied)||$hybrid_tied)->can('FETCH') },
	hybrid_tied_can_fast               => sub{ $hybrid_tied->fast->can('FETCH') },
	
	hybrid_tied_mutable_method         => sub{ $hybrid_tied_mutable->FETCH('a') },
	hybrid_tied_mutable_method_fast    => sub{ $hybrid_tied_mutable->fast->FETCH('a') },
	hybrid_tied_caller_method          => sub{ $hybrid_tied_caller->FETCH('a') },
	hybrid_tied_caller_method_fast     => sub{ $hybrid_tied->fast->FETCH('a') },
	
	primitive                          => sub{ $plain->{a} },
	primitive_blessed                  => sub{ $blessed->{a} },
	primitive_tied                     => sub{ $tied->{a} },
	primitive_switch                   => sub{ tied(%$plain) ? tied(%$plain)->FETCH('a') : $plain->{a} },
	primitive_tied_switch              => sub{ tied(%$tied)  ? tied(%$tied )->FETCH('a') : $tied->{a} },
	primitive_tied_method              => sub{                 tied(%$tied )->FETCH('a') },
	
});
