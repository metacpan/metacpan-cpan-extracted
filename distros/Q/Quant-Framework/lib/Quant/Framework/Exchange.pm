package Quant::Framework::Exchange;

use Moose;
use Carp qw(croak);
use Date::Utility;
use List::Util qw(first);
use List::MoreUtils qw(uniq);
use Clone qw(clone);
use File::ShareDir;
use YAML::XS qw(LoadFile);

=head1 NAME

Quant::Framework::Exchange - A module to save/load exchange information

=head1 DESCRIPTION

This module saves/loads holidays to/from Chronicle. 

=cut

has symbol => (
    is       => 'ro',
    required => 1,
);

has [qw(
        pretty_name
        offered
        )
    ] => (
    is  => 'ro',
    isa => 'Str',
    );

has delay_amount => (
    is      => 'ro',
    isa     => 'Num',
    default => 60,
);

=head2 currency

Exchange's main currency.

=cut

has currency => (
    is => 'ro',
);

=head2 display_name

A name we can show to someone someday

=cut

has display_name => (
    is      => 'ro',
    lazy    => 1,
    default => sub { return shift->symbol },
);

my $exchanges;

BEGIN {
    $exchanges = YAML::XS::LoadFile(File::ShareDir::dist_file('Quant-Framework', 'exchange.yml'));
}

=head2 BUILDARGS

internal function to pre-process construction arguments

=cut

sub BUILDARGS {
    my ($class, $symbol) = @_;

    my $params_ref = clone($exchanges->{$symbol});
    $params_ref->{symbol} = $symbol;

    return $params_ref;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
