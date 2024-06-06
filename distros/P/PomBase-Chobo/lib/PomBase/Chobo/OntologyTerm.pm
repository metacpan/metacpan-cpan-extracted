package PomBase::Chobo::OntologyTerm;

=head1 NAME

PomBase::Chobo::OntologyTerm - Code for holding term data read from an OBO file

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomBase::Chobo::OntologyTerm

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

our $VERSION = '0.040'; # VERSION

use Mouse;
use Carp;

use PomBase::Chobo::OntologyConf;

use Clone qw(clone);
use Data::Compare;
use List::Compare;

has id => (is => 'ro', isa => 'Int', required => 1);
has cvterm_id => (is => 'ro', isa => 'Int', required => 0);
has cv_id => (is => 'ro', isa => 'Int', required => 0);
has name => (is => 'ro', isa => 'Str');
has def => (is => 'ro', isa => 'Str');
has namespace => (is => 'ro', isa => 'Str');
has comment => (is => 'ro', isa => 'Str');
has alt_id => (is => 'ro', isa => 'ArrayRef');
has xref => (is => 'ro', isa => 'ArrayRef');
has subset => (is => 'ro', isa => 'ArrayRef');
has is_relationshiptype => (is => 'ro', isa => 'Bool');
has is_obsolete => (is => 'ro', isa => 'Bool');
has replaced_by => (is => 'ro', isa => 'Str');
has consider => (is => 'ro', isa => 'Str');
has property_value => (is => 'ro', isa => 'ArrayRef');
has source_file => (is => 'ro', isa => 'Str', required => 1);
has source_file_line_number => (is => 'ro', isa => 'Str', required => 1);
has metadata => (is => 'ro');

our @field_names;
our %field_conf;

BEGIN {
  %field_conf = %PomBase::Chobo::OntologyConf::field_conf;
  @field_names = qw(id name);

  for my $field_name (sort grep { $_ ne 'id' && $_ ne 'name' } keys %field_conf) {
    push @field_names, $field_name;
  }
}

sub synonyms
{
  my $self = shift;

  return @{$self->{synonym} // []};
}

sub alt_ids
{
  my $self = shift;

  return map {
    my $val = $_;

    if ($val =~ /(\S+):(\S+)/) {
      {
        id => $val,
        db_name => $1,
        accession => $2,
      };
    } else {
      my $db_name;
      if (defined $self->metadata()->{ontology} &&
          $self->metadata()->{ontology} eq 'ro') {
        $db_name = 'OBO_REL'
      } else {
        $db_name = '_global';
      }
      {
        id => $val,
        db_name => $db_name,
        accession => $val,
      };
    }
  } @{$self->{alt_id} // []};
}

sub property_values
{
  my $self = shift;

  return @{$self->{property_value} // []};
}

sub subsets
{
  my $self = shift;

  return @{$self->{subset} // []};
}

sub xrefs
{
  my $self = shift;

  return @{$self->{xref} // []};
}

=head2 make_object

 Usage   : my $object = PomBase::Chobo::OntologyTerm->make_object($args);
 Function: Turn $args into an OntologyTerm

=cut

sub make_object
{
  my $class = shift;
  my $object = shift;
  my $options = shift;

  if (!defined $object) {
    croak "no argument passed to new()";
  }

  if ($object->{def} && $object->{def}->{dbxrefs} && $object->{alt_id}) {
    for my $alt_id (@{$object->{alt_id}}) {
      # filter alt_ids from the definition xrefs to avoid:
      #   duplicate key value violates unique constraint "cvterm_dbxref_c1"
      # see also: https://github.com/kimrutherford/go-ontology/commit/92dca313a69ffb073c226b94242faa8f321efcf2
      @{$object->{def}->{dbxrefs}} =
        grep {
          my $xref = $_;
          $alt_id ne $xref;
        } @{$object->{def}->{dbxrefs}};
    }
  }

  if ($object->{is_obsolete} && $object->{name} && $object->{name} !~ /^obsolete/i) {
    $object->{name} = "OBSOLETE " . $object->{id} . " " . $object->{name};
  }

  if ($object->{is_relationshiptype} && $object->{name}) {
    $object->{name} =~ s/ /_/g;
  }

  $object->{_namespace_from_metadata} = 0;

  if ($options) {
    if ($options->{namespace_from_metadata}) {
      $object->{_namespace_from_metadata} = 1;
    }
  }

  $object->{alt_id} //= [];

  my ($db_name, $accession);

  unless (($db_name, $accession) = $object->{id} =~ /^(\S+):(.+?)\s*$/) {
    if ($object->{id} eq 'part_of') {
      # special case to make sure all the part_of terms are merged - the "part_of"
      # in the GO and FYPO OBO files has the namespace "external" (and a variety of
      # others) and the ID is "part_of"
      # we normalise the id and namespace to match RO
      $db_name = 'BFO';
      $accession = '0000050';

      $object->{id} = "$db_name:$accession";
      $object->{namespace} = "relationship";
    } else {
      $db_name = '_global';
      $accession = $object->{id};
    }
  }

  $object->{accession} = $accession;
  $object->{db_name} = $db_name;

  if (!defined $object->{source_file}) {
    confess "source_file attribute of object is required\n";
  }

  if (!defined $object->{source_file_line_number}) {
    confess "source_file_line attribute of object is required\n";
  }

  return bless $object, $class;
}

=head2 merge

 Usage   : my $merged_term = $term->merge($other_term);
 Function: Attempt to merge $other_term into this term.  Only merges if at least
           one of the ID or alt_ids from this term match the ID or an alt_id
           from $other_term
 Args    : $other_term - the term to merge with
 Return  : undef - if no id from this term matches one from $other_term
           $self - if there is a match
=cut

sub merge
{
  my $self = shift;
  my $other_term = shift;

  my $orig_term = clone $self;

  return if $self == $other_term;

  my $lc = List::Compare->new([$self->{id}, @{$self->{alt_id}}],
                              [$other_term->{id}, @{$other_term->{alt_id}}]);

  if (scalar($lc->get_intersection()) == 0) {
    return undef;
  }

  my @new_alt_id = List::Compare->new([$lc->get_union()], [$self->id()])->get_unique(1);

  $self->{alt_id} = \@new_alt_id;

  my $merge_field = sub {
    my $name = shift;
    my $other_term = shift;

    my $field_conf = $PomBase::Chobo::OntologyConf::field_conf{$name};

    if (defined $field_conf) {
      if (defined $field_conf->{type} &&
            ($field_conf->{type} eq 'SINGLE' || $field_conf->{type} eq 'SINGLE_HASH')) {
        my $res = undef;
        if (defined $field_conf->{merge}) {
          $res = $field_conf->{merge}->($self, $other_term);
        }

        if (defined $res) {
          $self->{$name} = $res;
        } else {
          my $new_field_value = $other_term->{$name};

          if (defined $new_field_value) {
            if (!defined $self->{$name} ||
                ($name eq 'namespace' &&
                 $self->{_namespace_from_metadata})) {
              $self->{$name} = $new_field_value;
            } else {
              if ($name ne 'namespace' || !$other_term->{_namespace_from_metadata}) {
                warn qq|new "$name" tag of this stanza (from |,
                  $other_term->source_file(), " line ",
                  $other_term->source_file_line_number(), ") ",
                  "differs from previously ",
                  "seen value (from ", $self->source_file(),
                  " line ", $self->source_file_line_number(), q|) "|,
                  $orig_term->{$name}, '" ',
                  qq(- ignoring new value: "$new_field_value"\n\n),
                  "while merging: \n" . $other_term->to_string() . "\n\n",
                  "into existing term:\n",
                  $orig_term->to_string(), "\n\n";
              }
            }
          } else {
            # no merging to do
          }
        }
      } else {
        my $new_field_value = $other_term->{$name};
        for my $single_value (@$new_field_value) {
          if (!grep { Compare($_, $single_value) } @{$self->{$name}}) {
            push @{$self->{$name}}, clone $single_value;
          }
        }
      }
    } else {
      die "unhandled field in merge(): $name\n";
    }
  };

  for my $field_name (@field_names) {
    next if $field_name eq 'id' or $field_name eq 'alt_id';

    if (!Compare($self->{$field_name}, $other_term->{$field_name})) {
      $merge_field->($field_name, $other_term);
    }
  }

  return $self;
}

sub to_string
{
  my $self = shift;

  my @lines = ();

  if ($self->is_relationshiptype()) {
    push @lines, "[Typedef]";
  } else {
    push @lines, "[Term]";
  }

  my $line_maker = sub {
    my $name = shift;
    my $value = shift;

    my @ret_lines = ();

    if (ref $value) {
      my @values;
      if ($field_conf{$name}->{type} eq 'SINGLE_HASH') {
        push @values, $value;
      } else {
        @values = @$value;
      }
      for my $single_value (@values) {
        my $to_string_proc = $field_conf{$name}->{to_string};
        my $value_as_string;
        if (defined $to_string_proc) {
          $value_as_string = $to_string_proc->($single_value);
        } else {
          $value_as_string = $single_value;
        }
        push @ret_lines, "$name: $value_as_string";
      }
    } else {
      push @ret_lines, "$name: $value";
    }

    return @ret_lines;
  };

  for my $field_name (@field_names) {
    my $field_value = $self->{$field_name};

    if (defined $field_value) {
      push @lines, $line_maker->($field_name, $field_value);
    }
  }

  return join "\n", @lines;
}

1;
