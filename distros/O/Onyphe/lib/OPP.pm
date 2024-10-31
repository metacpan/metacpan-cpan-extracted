#
# $Id: OPP.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP;
use strict;
use warnings;

our $VERSION = '1.00';

our $debug = 0;

use Class::Gomor::Array;
use base qw(Class::Gomor::Array);

our @AS = qw(
   nested
   state
   output
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Carp;
use Data::Dumper;
use Text::ParseWords;
use JSON::XS qw(encode_json decode_json);
use Tie::IxHash;

#
# Check given field is of nested kind:
#
# $self->is_nested("domain");                      # 0
# $self->is_nested("app.http.component");          # ( 'app.http.component', undef )
# $self->is_nested("app.http.component.product");  # ( 'app.http.component', 'product' )
#
sub is_nested {
   my $self = shift;
   my ($field) = @_;

   croak("is_nested: need field arg") unless defined($field);

   my $fields = $self->nested;
   return 0 unless defined($fields);

   my $nested = { map { $_ => 1 } @{$self->nested} };

   my ($head, $leaf) = $field =~ m{^(.+)\.(\S+)$};

   my $is_nested = 0;
   # Handle first case: app.http.component.product given as input:
   # Will have head set to app.http.component and leaf to product:
   if (defined($head) && $nested->{$head}) {
      $is_nested = 1;
   }
   # Handle second case: app.http.component given as input:
   elsif ($nested->{$field}) {
      $head = $field;
      $leaf = undef;
      $is_nested = 1;
   }

   return $is_nested ? [ $head, $leaf ] : 0;
}

#
# Flatten given doc so we can work with field names in 'a.b.c' format i/o of {a}{b}{c}:
#
sub flatten {
   my $self = shift;
   my ($docs) = @_;

   #croak("flatten: need doc|docs argument") unless defined($docs);
   return $docs unless defined($docs);

   $docs = ref($docs) eq 'ARRAY' ? $docs : [ $docs ];

   my @new = ();
   for my $doc (@$docs) {
      my $new = { __opp_flatten => 1 };
      my $sub; $sub = sub {
         my ($doc, $field) = @_;

         for my $k (keys %$doc) {
            my $this_field = defined($field) ? "$field.$k" : $k;
            if (ref($doc->{$k}) eq 'HASH') {
               $sub->($doc->{$k}, $this_field);
            }
            else {
               $new->{$this_field} = $doc->{$k};
            }
         }

         return $new;
      };

      #push @new, ($doc->{__opp_flatten} ? $doc : $sub->($doc));
      push @new, $sub->($doc);
   }

   return \@new;
}

my $tie = sub {
   my ($h) = @_;
   my $t = tie(my %res, 'Tie::IxHash');
   %res = %$h;
   $t->SortByKey;
   return \%res;
};

my $order; $order = sub {
   my ($h) = @_;

   my $tie = $tie->($h);

   for my $k (keys %$h) {
      next unless defined $k;
      next unless defined $h->{$k};
      if (ref($h->{$k}) eq 'HASH') {
         my $this_tie = $order->($h->{$k});
         $tie->{$k} = $this_tie;
      }
      elsif (ref($h->{$k} eq 'ARRAY')) {
         my @a = ();
         for (@{$h->{$k}}) {
            next unless ref($_) eq 'HASH';
            my $this_tie = $order->($_);
            push @a, $this_tie;
         }
         $h->{$k} = \@a if @a;
      }
   }

   return $tie;
};

sub order {
   my $self = shift;
   my ($docs) = @_;

   $docs = ref($docs) eq 'ARRAY' ? $docs : [ $docs ];

   my @ordered = ();
   for (@$docs) {
      my $this = $order->($_) or next;
      push @ordered, $this;
   }

   return \@ordered;
}

sub unflatten {
   my $self = shift;
   my ($flats) = @_;

   croak("unflatten: need flat|flats argument") unless defined($flats);

   $flats = ref($flats) eq 'ARRAY' ? $flats : [ $flats ];

   my @new = ();
   for my $flat (@$flats) {
      if ($flat->{_opp_nounflatten}) {
         delete $flat->{_opp_nounflatten};
         push @new, $flat;
         next;
      }

      my %new;
      for my $k (keys %$flat) {
         my @toks = split(/\./, $k);
         my $value = $flat->{$k};

         my $current = \%new;
         my $last = $#toks;
         for my $idx (0..$#toks) {
            if ($idx == $last) {  # Last token
               $current->{$toks[$idx]} = $value;
               last;
            }

            # Create HASH key so we can iterate and create all subkeys
            # Merge with existing or create empty HASH:
            $current->{$toks[$idx]} = $current->{$toks[$idx]} || {};
            $current = $current->{$toks[$idx]};
         }
      }

      delete $new{__opp_flatten};
      push @new, \%new;
   }

   return \@new;
}

sub pipeone {
   my $self = shift;
   my ($input, $opp) = @_;

   $input = ref($input) eq 'ARRAY' ? $input : [ $input ];

   return $input unless defined($opp);

   $opp =~ s{(?:^\s*|\s*$)}{}g;

   my @cmd = split(/\s*(?<!\\)\|\s*/, $opp);
   croak("pipeone: no query, aborting") if @cmd == 0;

   print STDERR "pipeone: cmdlist[@cmd] count[".scalar(@cmd)."]\n" if $debug;

   my $idx = 0;
   $self->output->add($self->flatten($input));
   for my $this (@cmd) {
      print STDERR "pipeone: cmd[$this]\n" if $debug;
      my @proc = $this =~ m{^(\S+)(?:\s+(.+))?$};
      if (! defined($proc[0])) {
         print STDERR "pipeone: parse failed for [$this]\n" if $debug;
         return;
      }

      # Load proc
      my $module = 'OPP::Proc::'.ucfirst(lc($proc[0]));
      eval("use $module;");
      if ($@) {
         chomp($@);
         print STDERR "pipeone: use proc failed [$proc[0]]: $@\n";
         return;
      }
      my $proc = $module->new;
      if (!defined($proc)) {
         print STDERR "pipeone: load proc failed [$proc[0]]\n";
         return;
      }
      $proc->idx($idx);
      $proc->nested($self->nested);
      $proc->state($self->state);
      $proc->output($proc->clone($self->output)->init);

      my $argument = $proc[1];
      my $options = $proc->parse($argument);
      $proc->options($options);

      print STDERR "pipeone: proc[$proc]\n" if $debug;

      for my $input (@{$self->output->docs}) {
         $proc->process($input);
      }
      $self->output->docs($proc->output->docs);
      $idx++;
   }

   if (defined($self->output->docs)) {
      my $docs = $self->unflatten($self->output->docs);
      $self->output->flush;
      return $docs;
   }

   return;
}

sub pipeline {
   my $self = shift;
   my ($input, $opp) = @_;

   $input = ref($input) eq 'ARRAY' ? $input : [ $input ];

   return $input unless defined($opp);

   $opp =~ s{(?:^\s*|\s*$)}{}g;

   my @cmd = split(/\s*(?<!\\)\|\s*/, $opp);
   croak("pipeline: no query, aborting") if @cmd == 0;

   print STDERR "pipeline: cmdlist[@cmd] count[".scalar(@cmd)."]\n" if $debug;

   my $idx = 0;
   $self->output->add($self->flatten($input));
   for my $this (@cmd) {
      print STDERR "pipeline: cmd[$this]\n" if $debug;
      my @proc = $this =~ m{^(\S+)(?:\s+(.+))?$};
      if (! defined($proc[0])) {
         print STDERR "pipeline: parse failed for [$this]\n" if $debug;
         return;
      }

      # Load proc
      my $module = 'OPP::Proc::'.ucfirst(lc($proc[0]));
      eval("use $module;");
      if ($@) {
         chomp($@);
         print STDERR "pipeline: use proc failed [$proc[0]]: $@\n";
         return;
      }
      my $proc = $module->new;
      if (!defined($proc)) {
         print STDERR "pipeline: load proc failed [$proc[0]]\n";
         return;
      }
      $proc->idx($idx);
      $proc->nested($self->nested);
      $proc->state($self->state);
      $proc->output($proc->clone($self->output)->init);

      my $argument = $proc[1];
      my $options = $proc->parse($argument);
      $proc->options($options);

      print STDERR "pipeline: proc[$proc]\n" if $debug;

      for my $input (@{$self->output->docs}) {
         $proc->process($input);
      }
      $self->output->docs($proc->output->docs);
      $idx++;
   }

   if (defined($self->output->docs)) {
      for my $doc (@{$self->unflatten($self->output->docs)}) {
         print "$_\n" for @{$self->to_json($doc)};
      }
      $self->output->flush;  # Flush output when processed
   }

   return 1;
}

sub to_json {
   my $self = shift;
   my ($doc) = @_;

   $doc = ref($doc) eq 'ARRAY' ? $doc : [ $doc ];

   my @json = ();
   for (@$doc) {
      my $docs = $self->order($_) or next;
      for my $doc (@$docs) {
         my $json;
         eval {
            $json = encode_json($doc);
         };
         if ($@) {  # Silently discard in case of error
            next;
         }
         next unless defined $json;
         push @json, $json;
      }
   }

   return \@json;
}

sub from_json {
   my $self = shift;
   my ($docs) = @_;

   $docs = ref($docs) eq 'ARRAY' ? $docs : [ $docs ];

   my @json = ();
   for my $doc (@$docs) {
      my $json;
      eval {
         $json = decode_json($doc);
      };
      if ($@) {  # Silently discard in case of error
         next;
      }
      next unless defined $json;
      push @json, $json;
   }

   return $self->order(\@json);
}

sub add_output {
   my $self = shift;
   my ($doc) = @_;

   return push @{$self->output}, $doc;
}

sub process_as_json {
   my $self = shift;
   my ($input, $opp) = @_;

   croak("process: need input argument") unless defined($input);
   croak("process: need opp argument") unless defined($opp);

   $input = $self->from_json($input);

   return $self->pipeline($input, $opp);
}

sub process_as_perl {
   my $self = shift;
   my ($input, $opp) = @_;

   croak("process: need input argument") unless defined($input);
   croak("process: need opp argument") unless defined($opp);

   return $self->pipeline($input, $opp);
}

1;

__END__

=head1 NAME

OPP - ONYPHE Processing Pipeline

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
