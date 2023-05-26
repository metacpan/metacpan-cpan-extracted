package SyForm::ViewField::InputHTML;
BEGIN {
  $SyForm::ViewField::InputHTML::AUTHORITY = 'cpan:GETTY';
}
$SyForm::ViewField::InputHTML::VERSION = '0.103';
use Moo;
use List::MoreUtils qw( uniq );
use HTML::Declare ':all';

with qw(
  MooX::Traits
  SyForm::CommonRole::EventHTML
  SyForm::CommonRole::GlobalHTML
);

our @input_attributes = qw(
  accept
  align
  alt
  autocomplete
  autofocus
  checked
  disabled
  form
  formaction
  formenctype
  formmethod
  formnovalidate
  formtarget
  height
  list
  max
  maxlength
  min
  multiple
  name
  pattern
  placeholder
  readonly
  required
  size
  src
  step
  type
  value
  width
);

our @textarea_attributes = qw(
  autocomplete
  autofocus
  cols
  disabled
  form
  maxlength
  minlength
  name
  placeholder
  readonly
  required
  rows
  selectionDirection
  selectionEnd
  selectionStart
  spellcheck
  wrap
);

our @valid_types = qw(
  button
  checkbox
  color
  date
  datetime
  datetime-local
  email
  file
  hidden
  image
  month
  number
  password
  radio
  range
  reset
  search
  submit
  tel
  text
  time
  url
  week
);

my @own_attributes = uniq(
  @input_attributes,
  @textarea_attributes,
);

my @remote_attributes = uniq(
  @SyForm::CommonRole::EventHTML::attributes,
  @SyForm::CommonRole::GlobalHTML::attributes,
);

our @attributes;

for my $own_attribute (@own_attributes) {
  push @attributes, $own_attribute
    unless grep { $own_attribute eq $_ } @remote_attributes;
}

for my $attribute (@attributes) {
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
  for my $key (@remote_attributes) {
    my $has = 'has_'.$key;
    $html_attributes{$key} = $self->$key if $self->$has;
  }
  if ($self->type eq 'textarea') {
    for my $key (@textarea_attributes) {
      my $has = 'has_'.$key;
      $html_attributes{$key} = $self->$key if $self->$has;
    }
    delete $html_attributes{value} if defined $html_attributes{value};
    my $value = $self->has_value ? $self->value : "";
    return TEXTAREA { %html_attributes, _ => $value };
  } else {
    SyForm->throw("Unknown type")
      unless grep { $self->type eq $_ } @valid_types;
    for my $key (@input_attributes) {
      my $has = 'has_'.$key;
      $html_attributes{$key} = $self->$key if $self->$has;
    }
    return INPUT { %html_attributes };
  }
}

1;

__END__

=pod

=head1 NAME

SyForm::ViewField::InputHTML

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
