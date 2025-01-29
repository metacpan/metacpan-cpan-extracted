#
# $Id: Proc.pm,v cfbea05b0bc4 2025/01/28 15:06:19 gomor $
#
package OPP::Proc;
use strict;
use warnings;

our $VERSION = '1.00';

use base qw(OPP);

our @AS = qw(
   idx
   options
   nested
   state
   output
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Carp;
use Data::Dumper;
use Storable;

#
# Always return values as ARRAY, undef when no value found:
#
sub value {
   my $self = shift;
   my ($flat, $field) = @_;

   croak("value: need flat argument") unless defined($flat);
   croak("value: need field argument") unless defined($field);

   my @value = ();

   #delete $flat->{data};
   #print "$field: ".Data::Dumper::Dumper($flat)."\n";

   # Handle nested fields:
   if (my $split = $self->is_nested($field)) {
      #print "*** is_nested ".$split->[0]." $field\n";
      #print "*** is_nested ".$split->[1]." $field\n";
      my $root = $split->[0];
      my $leaf = $split->[1];
      if (defined($leaf)) {
         for (@{$flat->{$root}}) {
            if (defined($_->{$leaf})) {
               my $ary = ref($_->{$leaf}) ? $_->{$leaf} : [ $_->{$leaf} ];
               push @value, @$ary;
            }
         }
      }
   }
   # Handle standard fields:
   else {
      if (defined($flat->{$field})) {
         my $ary = ref($flat->{$field}) eq 'ARRAY' ? $flat->{$field} : [ $flat->{$field} ];
         push @value, @$ary;
      }
   }

   #print "value: ".Data::Dumper::Dumper(\@value)."\n";

   return @value ? \@value : undef;
}

sub fields {
   my $self = shift;
   my ($flat) = @_;

   croak("fields: need flat argument") unless defined($flat);

   my @fields = ();

   my $flat_fields = [ map { $_ } keys %$flat ];
   for my $field (@$flat_fields) {
      if ($self->is_nested($field)) {
         my $ary = ref($flat->{$field}) eq 'ARRAY' ? $flat->{$field} : [ $flat->{$field} ];
         for (@$ary) {
            for my $leaf (keys %$_) {
               push @fields, "$field.$leaf";
            }
         }
      }
      else {
         push @fields, $field;
      }
   }

   return \@fields;
}

sub values {
   my $self = shift;
   my ($flat) = @_;

   croak("values: need flat argument") unless defined($flat);

   my @values = ();
   my $fields = $self->fields($flat);

   for (@$fields) {
      push @values, $flat->{$_};
   }

   return \@values;
}

sub dumper {
   my $self = shift;
   my ($arg) = @_;

   return Data::Dumper::Dumper($arg)."\n";
}

#
# $self->delete($flat, "domain");
# $self->delete($flat, "app.http.component");
# $self->delete($flat, "app.http.component.product");
#
sub delete {
   my $self = shift;
   my ($flat, $field) = @_;

   croak("delete: need flat argument") unless defined($flat);
   croak("delete: need field argument") unless defined($field);

   # Handle nested fields:
   if (my $split = $self->is_nested($field)) {
      my $root = $split->[0];
      my $leaf = $split->[1];
      # Delete at the leaf level:
      if ($root !~ m{^_} && defined($leaf)) {
         my @keep = ();
         for my $this (@{$flat->{$root}}) {
            delete $this->{$leaf};
            push @keep, $this if keys %$this;  # Keep the final object only when not empty
         }
         # Keep the final array only when not empty
         if (@keep > 0) {
            $flat->{$root} = \@keep;
         }
         # And when empty, completly remove the root field:
         else {
            delete $flat->{$root};
         }
      }
      # Or the complete root field when asked for:
      elsif ($root !~ m{^_}) {
         delete $flat->{$root};
      }
   }
   # Handle standard fields:
   elsif ($field !~ m{^_}) {
      delete $flat->{$field};
   }

   return $flat;
}

#
# $self->set($flat, "domain", "example.com");
# $self->set($flat, "app.http.component.product", "HTTP Server");
#
sub set {
   my $self = shift;
   my ($flat, $field, $value, $asarray) = @_;

   croak("set: need flat argument") unless defined($flat);
   croak("set: need field argument") unless defined($field);
   croak("set: need value argument") unless defined($value);

   # Handle nested fields:
   if (my $split = $self->is_nested($field)) {
      my $root = $split->[0];
      my $leaf = $split->[1];
      # Set at the leaf level:
      if (defined($leaf)) {
         $flat->{$root} = [ { $leaf => $value } ];
      }
   }
   # Handle standard fields:
   else {
      if ($asarray) {
         $flat->{$field} ||= [];
         $flat->{$field} = ref($flat->{$field}) eq 'ARRAY'
            ? $flat->{$field} : [ $flat->{$field} ];
         push @{$flat->{$field}}, $value;
         #print STDERR Data::Dumper::Dumper($flat->{$field})."\n";
         my %h = map { $_ => 1 } @{$flat->{$field}};
         $flat->{$field} = [ sort { $a cmp $b } keys %h ];  # Make uniq
      }
      else {
         $flat->{$field} = $value;
      }
   }

   return $flat;
}

#
# Clone given doc so we can duplicate it and modify on a new one:
#
sub clone {
   my $self = shift;
   my ($doc) = @_;

   croak("clone: need doc argument") unless defined($doc);

   return Storable::dclone($doc);
}

#
# Will return $arg parsed as usable arguments and also original $arg value:
#
sub parse {
   my $self = shift;
   my ($args) = @_;

   my @a = Text::ParseWords::quotewords('\s+', 0, $args);

   # Also keep original value, for use with placeholders, for instance:
   my $parsed = {
      args => $args,
   };
   my $idx = 0;
   for (@a) {
      my ($k, $v) = split(/\s*[=:]\s*/, $_, 2);
      if (defined($k) && defined($v)) {
         $parsed->{$k} = [ sort { $a cmp $b } split(/\s*,\s*/, $v) ];
      }
      elsif (defined($k)) {
         $parsed->{$idx++} = $k;
      }
   }

   return $parsed;
}

sub placeholder {
   my $self = shift;
   my ($query, $flat) = @_;

   # Copy original to not modify it:
   my $copy = $query;
   my (@holders) = $query =~ m{[\w\.]+\s*:\s*\$([\w\.]+)}g;

   # Update search clause with placeholder values
   my %searches = ();
   for my $holder (@holders) {
      my $values = $self->value($flat, $holder);
      for my $value (@$values) {
         while ($copy =~ s{(\S+)\s*:\s*\$$holder}{$1:$value}) { }
      }
   }
   $searches{$copy}++;  # Make them unique

   return [ keys %searches ];
}

1;

__END__

=head1 NAME

OPP::Proc - base class for OPP's processors

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ONYPHE E<lt>contact_at_onyphe.ioE<gt>

=cut
