package Template::Plugin::MARC::Field;

=head1 Template::Plugin::MARC::Field

Object class to allow nested auto-loading. Not used directly.

=cut

use 5.010000;
use strict;
use warnings;
use MARC::Field;

use Template::Plugin::MARC::Subfield;

our $VERSION = '0.04';

our $AUTOLOAD;

sub new {
    my ($class, $field) = @_;
    my $fieldhash = {
        'tag' => $field->tag(),
        'subfields' => [],
    };
    if ($field->is_control_field()) {
        $fieldhash->{'value'} = $field->data();
            push @{$fieldhash->{'subfields'}}, Template::Plugin::MARC::Subfield->new('@' => $field->data());
    } else {
        $fieldhash->{'ind1'} = $field->indicator(1);
        $fieldhash->{'ind2'} = $field->indicator(2);
        my @subfields = $field->subfields();
        foreach my $subf (@subfields) {
            $fieldhash->{"s$subf->[0]"} = $subf->[1] unless $fieldhash->{"s$subf->[0]"};
            $fieldhash->{'all'} .= ' ' if $fieldhash->{'all'};
            $fieldhash->{'all'} .= $subf->[1];
            push @{$fieldhash->{'subfields'}}, Template::Plugin::MARC::Subfield->new($subf->[0] => $subf->[1]);
        }
    }

    return bless $fieldhash, $class;
}

sub has {
    my ($self, $selector, $match) = @_;

    unless ($selector eq 'ind1' || $selector eq 'ind2' || $selector eq 'tag') {
        $selector = "s$selector"; # Everything else is a subfield
    }

    return $self->{$selector} eq $match if (defined $self->{$selector} && defined $match);
    return defined $self->{$selector};
}

sub filter {
    my ($self, $selectors) = @_;

    my $result = '';
    foreach my $selector (keys %$selectors) {
        if ($selector eq 'code') {
            foreach my $subf (@{$self->{'subfields'}}) {
                if (index($selectors->{$selector}, $subf->code) >= 0) {
                    $result .= ' ' if $result;
                    $result .= $subf->value;
                }
            }
        }
    }
    return $result;
}

sub AUTOLOAD {
    my $self = shift;
    (my $a = $AUTOLOAD) =~ s/.*:://;

    return $self->{"$a"};
}

1;
