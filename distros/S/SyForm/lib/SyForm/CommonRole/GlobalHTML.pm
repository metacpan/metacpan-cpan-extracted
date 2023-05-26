package SyForm::CommonRole::GlobalHTML;
BEGIN {
  $SyForm::CommonRole::GlobalHTML::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Standard role for objects with HTML global attributes
$SyForm::CommonRole::GlobalHTML::VERSION = '0.103';
use Moo::Role;

our @attributes = qw(
  class
  accesskey
  contenteditable
  contextmenu
  dir
  draggable
  dropzone
  hidden
  lang
  spellcheck
  style
  tabindex
  title
  translate
  id
  name
);

for my $attribute (@attributes) {
  has $attribute => (
    is => 'ro',
    predicate => 1,
  );
}

has data => (
  is => 'ro',
  predicate => 1,
);

has data_attributes => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_data_attributes {
  my ( $self ) = @_;
  return {} unless $self->has_data;
  my %data_attributes;
  for my $key (sort { $a cmp $b } keys %{$self->data}) {
    my $value = $self->data->{$key};
    $key =~ s/_/-/g;
    $data_attributes{'data-'.$key} = $value;
  }
  return { %data_attributes };
}

1;

__END__

=pod

=head1 NAME

SyForm::CommonRole::GlobalHTML - Standard role for objects with HTML global attributes

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
