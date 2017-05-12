package SyForm::ViewField::LabelHTML;
BEGIN {
  $SyForm::ViewField::LabelHTML::AUTHORITY = 'cpan:GETTY';
}
$SyForm::ViewField::LabelHTML::VERSION = '0.102';
use Moo;
use List::MoreUtils qw( uniq );
use HTML::Declare ':all';

with qw(
  MooX::Traits
  SyForm::CommonRole::GlobalHTML
);

has label => (
  is => 'ro',
  required => 1,
);

my @own_attributes = qw( for );

for my $attribute (@own_attributes, qw( errors )) {
  has $attribute => (
    is => 'ro',
    predicate => 1,
  );
}

has html_declare => (
  is => 'lazy',
);

sub _build_html_declare {
  my ( $self ) = @_;
  my %html_attributes = %{$self->data_attributes};
  for my $key (@SyForm::CommonRole::GlobalHTML::attributes) {
    my $has = 'has_'.$key;
    $html_attributes{$key} = $self->$key if $self->$has;
  }
  for my $key (@own_attributes) {
    my $has = 'has_'.$key;
    $html_attributes{$key} = $self->$key if $self->$has;
  }
  $html_attributes{_} = [
    $self->label,
    $self->has_errors ? (
      map { EM { _ => $_->message } } @{$self->errors}
    ) : (),
  ],
  return LABEL { %html_attributes };
}

1;

__END__

=pod

=head1 NAME

SyForm::ViewField::LabelHTML

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
