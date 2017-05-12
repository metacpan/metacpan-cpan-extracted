package MooseX::Graph::Easy::StateMachine;

use 5.010000;
use strict;
use warnings;
use Carp qw/croak/;

our @ISA = qw();

our $VERSION = '0.01';

# use Class::ISA;
#--------------------------------------------------------------------------
sub self_and_super_path {
  # Assumption: searching is depth-first.
  # Assumption: '' (empty string) can't be a class package name.
  # Note: 'UNIVERSAL' is not given any special treatment.
  return () unless @_;

  my @out = ();

  my @in_stack = ($_[0]);
  my %seen = ($_[0] => 1);

  my $current;
  while(@in_stack) {
    next unless defined($current = shift @in_stack) && length($current);
    push @out, $current;
    no strict 'refs';
    unshift @in_stack,
      map
        { my $c = $_; # copy, to avoid being destructive
          substr($c,0,2) = "main::" if substr($c,0,2) eq '::';
           # Canonize the :: -> main::, ::foo -> main::foo thing.
           # Should I ever canonize the Foo'Bar = Foo::Bar thing? 
          $seen{$c}++ ? () : $c;
        }
        @{"$current\::ISA"}
    ;
    # I.e., if this class has any parents (at least, ones I've never seen
    # before), push them, in order, onto the stack of classes I need to
    # explore.
  }

  return @out;
}
# end routine taken from Class::ISA version 0.33


sub template($$$){
   my ($source, $dest, $edgelabel) = @_;
   no strict 'refs';
   # warn "method $source\::$edgelabel will rebless to $dest";
0 and   return     *{"$source\::$edgelabel"} = sub { 
      ref $_[0] or Carp::confess "FSM transition method called on non-ref [$_[0]";
      bless $_[0], $dest };
   eval <<YUCK ## oddly, this is needed for Moose but not Mouse
package $source;
sub $edgelabel {
      ref \$_[0] or Carp::confess "FSM transition method called on non-ref [\$_[0]";
      bless \$_[0], '$dest' }
YUCK
};

sub CreateMethods($$){
   # like as_FSA, but doesn't need to be evaluated later
   my ( $graph, $base) = @_;
   my $BASE = 'BASE';
   my %BaseTransitions;
   my %Transitions;
   for my $node ( $graph->nodes )
   {
      my $statename = $node->name;
      # $statename eq $BASE or ### push @{"$base\::$statename\::ISA"} = ( $base );
      no strict 'refs';
      $statename eq $BASE or  @{"$base\::$statename\::ISA"} or
      ### in Moose, that's spelled
         $base->meta->create(
               "$base\::$statename",
                superclasses => [$base],
                meta_name => undef  
         );
  #    do { no strict 'refs'; @{"$base\::$statename\::ISA"} = ( $base ) } ; # LIGHTWEIGHT SUBCLASS

      for my $edge ( $node->edges )
      {
         $edge->from->name eq $statename or next;
         my $from = $statename;
         my $to = $edge->to->name;
         my $frompack;
         my $methodname = $edge->name ||  $to;
         if( $from eq $BASE )
         {
            $frompack = $base;
            $BaseTransitions{ $methodname } = 1;
         }else{
            $frompack = "$base\::$from";
         };
         my $topack = ( $to eq $BASE ? $base : "$base\::$to" );
         $Transitions{ $methodname }->{$from}++ and Carp::croak( "ambiguous declaration of $methodname from $from");

         template $frompack, $topack, $edge->name ||  $to;
         if ($edge->bidirectional)
         {
            $Transitions{ $edge->name ||  $from }->{$to}++
               and Carp::croak "ambiguous declaration of $methodname from $from";
            template $topack, $frompack, $edge->name || $from;
            $to eq $BASE and 
               $BaseTransitions{ $edge->name ||  $from } = 1;
         }
      };
   
   };
   for my $node ( $graph->nodes )
   {
      my $statename = $node->name;
      $statename eq $BASE and next;
      for my $method ( keys %BaseTransitions )
      {
          $Transitions{ $method }->{$statename} and next;
          no strict 'refs';
          *{"$base\::$statename\::$method"} = sub {
             my ($p,$f,$l) = caller;
             die qq{invalid state transition $statename->$method at $f line $l\n}
          }
      };
   }; 
}


use Graph::Easy;
our %GraphsByPackage;
sub import {
   shift; # lose package
   my ($caller, $file, $line) = caller;
   no strict 'refs';
   push @{$GraphsByPackage{$caller}}, @_;
   no warnings;
   my @graphs = map {
       # warn "looking at ancestor package [$_]";
      @{$GraphsByPackage{$_}}
   } reverse (self_and_super_path($caller), 'UNIVERSAL');

   for (@graphs) { 
      # warn "augmenting $caller with [$_]";
      my $g = Graph::Easy->new( $_ );
      CreateMethods($g, $caller)
   }; 
   # warn "done with import into $caller";
};



1;
__END__

=head1 NAME

MooseX::Graph::Easy::StateMachine - declare state subclasses using Graph::Easy syntax and Any::Moose

=head1 SYNOPSIS

Welcome to a world where a Finite State Machine drawing can go right into your source code.

  
    package liquor::consumer; # "I'm not an alchoholic: alchoholics go to meetings."
    use Any::Moose;
    use MooseX::Graph::Easy::StateMachine <<GRAPH;
  
    [BASE] - WakeUp -> [sober] - drink -> [drunk] - wait -> [sober]
  
    [BASE] - drink -> [drunk]
  
    [drunk] - passout -> [asleep] - wait -> [BASE] - wait -> [BASE]
  
  GRAPH
  
    sub live{ my $self = shift; $self->WakeUp }
    sub liquor::consumer::sober::live {  my $self = shift; $self->drink }
  
    package alchoholic;
    use Any::Moose;
  BEGIN {    # this needs to be in a BEGIN block
             # so the state machine class generator
             # will be able to see the @ISA
             extends ('liquor::consumer');
  };
  
    has days_sober => (isa => 'Int', is => 'rw', required => 1);
  
    use MooseX::Graph::Easy::StateMachine <<GRAPH;
  
    [sober] - GoToMeeting -> [sober]
    [drunk] - GoToMeeting -> [sober]
    [BASE] - GoToMeeting -> [sober]
  
  GRAPH
    after 'drink' => sub {
      my $self = shift;
      $self->days_sober(0);
    };
    after 'GoToMeeting' => sub {
      my $self = shift;
      $self->days_sober(1+$self->days_sober);
    };
    sub live{ my $self = shift; $self->GoToMeeting }
  package alchoholic::sober;
    use Any::Moose;
    after ('drink' => sub {
      my $self = shift;
      $self->days_sober(0);  # the extension is automatic
    });
    after 'GoToMeeting' => sub {
      my $self = shift;
      $self->days_sober(1+$self->days_sober);
    };
  package Maine;
    my $Basil = alchoholic->new(3653); # Basil has been sober for ten years







=head1 DESCRIPTION

This module is intended to work exactly like L<Graph::Easy::StateMachine> only using L<Any::Moose> OO instead,

Instead of running string-eval on the output of a layout engine, this module uses C<<caller()->meta->create>>
and closures to generate the state transition methods.

=head2 What This Module Is Not

this module does not facilitate creating a role/trait that limits the available values that
may be set into a state attribute based on inspecting what the state attribute is currently
set to. Doing it that way would make sense from a flexibility and reuse standpoint, at the cost
of requiring double method dispatch and a lot of dynamic checking.

=head2 surprises during development

Moose's "after" mechanism can't find methods declared like

  *{"alchoholic::sober::drink"} = sub{...}

but can find them when declared usint string eval. Mouse's can find both.
Also, "after" does not affect equivalent methods in subclasses.

=head1 HISTORY

=over 8

=item 0.01


=back



=head1 SEE ALSO



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 David Nicol, E<lt>davidnico@cpan.orgE<gt>

This module is free software; you can redistribute it and/or modify
it under the terms of the Creative Commons Attribution 3.0
license http://creativecommons.org/licenses/by/3.0/ 

Not deleting this section from your installation is sufficient attribution.

=cut
