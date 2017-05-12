package Silki::Role::Schema::Serializes;
{
  $Silki::Role::Schema::Serializes::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Types qw( ArrayRef Str );

use MooseX::Role::Parameterized;

parameter skip => (
    isa => ArrayRef [Str],
    default => sub { [] },
);

role {
    my $p     = shift;
    my %extra = @_;

    my %skip = map { $_ => 1 } @{ $p->skip() };

    my %map;

    for my $attr ( $extra{consumer}->get_all_attributes() ) {

        next if $skip{ $attr->name() };
        next if $attr->name() =~ /_raw$/;

        # We only want to serialize data from the class's the associated table
        if ( $attr->isa('Fey::Meta::Attribute::FromInflator') ) {
            $map{ $attr->name() } = $attr->raw_attribute()->name();
        }
        elsif ( $attr->isa('Fey::Meta::Attribute::FromColumn') ) {
            $map{ $attr->name() } = $attr->name();
        }
    }

    method serialize => sub {
        my $self = shift;

        return {
            map {
                my $meth = $map{$_};
                $_ => $self->$meth();
                } keys %map
        };
    };
};

1;
