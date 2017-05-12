package Pegex::CPAN::Packages::Data;

use Pegex::Base;
extends 'Pegex::Tree';

has data => {};

sub final {
    my ($self, $got) = @_;
    return $self->data;
}

sub got_meta_section {
    my ($self, $got) = @_;
    $self->{data}{meta} = { map { @$_ } @$got };
}

sub got_index_line {
    my ($self, $got) = @_;

    my ( $package, $version, $distribution ) = @$got;

    $self->{data}{index}{$distribution}{$package} =
      'undef' eq $version
      ? undef
      : $version;
}

1;
