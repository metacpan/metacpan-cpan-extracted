package PomBase::Chobo::OntologyConf;

=head1 NAME

PomBase::Chobo::OntologyConf - Configuration for ontology data

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomBase::Chobo::OntologyConf

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

our $VERSION = '0.040'; # VERSION

use warnings;
use Carp;

our %field_conf = (
  id => {
    type => 'SINGLE',
  },
  name => {
    type => 'SINGLE',
    process => sub {
      my $val = shift;
      $val =~ s/\\"/"/g;
      $val;
    }
  },
  def => {
    type => 'SINGLE_HASH',
    process => sub {
      my $val = shift;
      if ($val =~ /"(.*)"(?:\s+\[(.*)\])?/) {
        my $definition = $1;
        my $dbxrefs = $2 // '';

        my @dbxrefs =
          map {
            # remove quoting
            s|\\(.)|$1|g;
            $_;
          }
          grep {
            !m|^(?:url:)?https?\\?:| && /^\S+:\S+$/;
          } split /\s*,\s/, $dbxrefs;

        return {
          definition => $definition,
          dbxrefs => \@dbxrefs,
        }
      } else {
        croak qq(failed to parse "def:" line: $val);
      }
    },
    merge => sub {
      my $self = shift;
      my $other = shift;

      if (!defined $other->def()) {
        return $self->def();
      } else {
        if (!defined $self->def()) {
          return $other->def();
        } else {
          if ($self->def()->{definition} ne $other->def()->{definition}) {
            warn qq("def:" line differ\n  ) . $self->def()->{definition} . "\nversus:\n  " .
              $other->def()->{definition};
          }
          return $self->def();
        }
      }
    },
    to_string => sub {
      my $val = shift;
      my $ret_string = $val->{definition};
      $ret_string .= ' [' . (join ", ", @{$val->{dbxrefs}}) . ']';
    }
  },
  comment => {
    type => 'SINGLE',
  },
  replaced_by => {
    type => 'SINGLE',
  },
  consider => {
    type => 'SINGLE',
  },
  is_obsolete => {
    type => 'SINGLE',
    process => sub {
      my $val = shift;
      if ($val eq 'true') {
        return 1;
      } else {
        return 0;
      }
    },
  },
  namespace => {
    type => 'SINGLE',
    merge => sub {
      my $self = shift;
      my $other = shift;

      my $self_namespace = $self->{namespace};
      my $other_namespace = $other->{namespace};
      if (defined $self_namespace &&
          defined $other_namespace) {
        # if the namespace is the same as the db_name, remove it and use the
        # namespace from the other term to avoid a namespace clash
        if ($self_namespace eq $self->{db_name}) {
          $self->{namespace} = undef;
        } else {
          if ($other_namespace eq $other->{db_name}) {
            $other->{namespace} = undef;
          }
        }
      }
      # do default merging
      return undef;
    },
  },
  alt_id => {
    type => 'ARRAY',
  },
  is_a => {
    type => 'ARRAY',
  },
  part_of => {
    type => 'ARRAY',
  },
  subset => {
    type => 'ARRAY',
  },
  xref => {
    type => 'ARRAY',
    process => sub {
      my $val = shift;

      if ($val =~ /^([^\s:]+:[^\s]+)(?:$|\s)/) {
        return $1;
      } else {
        return undef;
      }
    },
  },
  relationship => {
    type => 'ARRAY',
    process => sub {
      my $val = shift;

      if ($val =~ /^\s*(\S+)\s+(\S+)\s*(?:\{(.*)\})?$/) {
        my $relationship_name = $1;
        my $other_term = $2;

        if ($relationship_name =~ /^:|:$/) {
          warn "illegal relationship name: $relationship_name\n";
          return undef;
        }

        return {
          relationship_name => $relationship_name,
          other_term => $other_term,
        };
      } else {
        warn "can't parse relationship: $val\n";
        return undef;
      }
    },
    to_string => sub {
      my $val = shift;

      if (ref $val) {
        return $val->{relationship_name} . ' ' . $val->{other_term};
      } else {
        croak "can't output relationship '$val' - expected a reference";
      }
    },
  },
  synonym => {
    type => 'ARRAY',
    process => sub {
      my $val = shift;
      if ($val =~ /^"(.*?[^\\])"\s*(.*)/) {
        my $synonym = $1;
        my @dbxrefs = ();
        my $rest = $2;

        $synonym =~ s/\\(.)/$1/g;

        my %ret = (
          synonym => $synonym,
        );

        my $scope_and_type;

        if ($rest =~ /^(?:\s*(\S.*)\s+)?\[([^\]]*)\]/) {
          if (defined $1) {
            $scope_and_type = $1;
          } else {
            $scope_and_type = 'RELATED';
          }

          my $dbxrefs_match = $2;

          if (defined $dbxrefs_match) {
            @dbxrefs = split /\s*,\s*/, $dbxrefs_match;
          }
        } else {
          $scope_and_type = $rest;
        }

        if (defined $scope_and_type) {
          if ($scope_and_type =~ /(\S+)\s+(\S+)/) {
            my ($scope, $type) = ($1, $2, $3);

            $ret{scope} = $scope;
            $ret{type} = $type;
          } else {
            $ret{scope} = $scope_and_type;
          }
        }

        $ret{dbxrefs} = \@dbxrefs;

        return \%ret;
      } else {
        die "unknown synonym format: $val\n";
      }
    },
    to_string => sub {
      my $val = shift;
      my $ret_string = $val->{synonym};
      if (defined $val->{scope}) {
        $ret_string .= ' ' . $val->{scope};
      }
      if (defined $val->{type}) {
        $ret_string .= ' ' . $val->{type};
      }
      if (defined $val->{dbxrefs}) {
        $ret_string .= ' [' . (join ", ", @{$val->{dbxrefs}}) . ']';
      }

      return $ret_string;
    },
  },
  property_value => {
    type => 'ARRAY',
    process => sub {
      my $raw_value = shift;

      $raw_value =~ s/\s+xsd:\w+\s*$//;

      my ($name, $value) = split(/\s+/, $raw_value, 2);

      return [
        $name, $value
      ]
    },
  },
);

1;
