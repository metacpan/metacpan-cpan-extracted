package ObjectDB::With;

use strict;
use warnings;

our $VERSION = '3.25';

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{meta} = $params{meta};
    $self->{with} = $params{with};
    $self->{with} = [ $self->{with} ]
      if $self->{with} && ref $self->{with} ne 'ARRAY';

    my $joins = { join => [] };

    my %seen;
    if (my @with = sort grep { defined } @{ $self->{with} || [] }) {
        foreach my $with (@with) {
            my $meta = $self->{meta};

            my $name = $with;
            my $columns;
            if (ref $name eq 'HASH') {
                $name    = $with->{name};
                $columns = $with->{columns};
            }

            my @parts = split /[.]/xms, $name;

            my $seen        = q{};
            my $parent_join = $joins;
            foreach my $part (@parts) {
                $seen .= q{.} . $part;

                my $rel = $meta->get_relationship($part);

                if ($seen{$seen}) {
                    $parent_join = $seen{$seen};
                    $meta        = $rel->class->meta;
                    next;
                }

                my $parent_as = $parent_join->{as};

                my $name_prefix = $parent_as ? $parent_as . '_' : '';
                my @joins = $rel->to_source(
                    table       => $parent_join->{as},
                    name_prefix => $name_prefix
                );

                foreach my $join (@joins) {
                    push @{ $parent_join->{join} },
                      {
                        source   => $join->{table},
                        rel_name => $join->{as},
                        as       => $name_prefix . $join->{as},
                        on       => $join->{constraint},
                        op       => $join->{join},
                        columns  => $columns || $join->{columns},
                        join     => []
                      };
                }

                $parent_join = $parent_join->{join}->[-1];
                $seen{$seen} = $parent_join;

                $meta = $rel->class->meta;
            }
        }
    }

    $self->{joins} = $joins->{join};

    return $self;
}

sub to_joins {
    my $self = shift;

    return $self->{joins};
}

1;
