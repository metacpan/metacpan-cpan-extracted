package SyForm::FormHTML;
BEGIN {
  $SyForm::FormHTML::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: HTML Form
$SyForm::FormHTML::VERSION = '0.102';
use Moo;
use HTML::Declare ':all';
use List::MoreUtils qw( uniq );
use Safe::Isa;
use SyForm::ViewField::InputHTML;

with qw(
  MooX::Traits
  SyForm::CommonRole::GlobalHTML
  SyForm::CommonRole::EventHTML
);

our @attributes = qw(
  action
  autocomplete
  enctype
  method
  target
);

for my $attribute (@attributes) {
  has $attribute => (
    is => 'ro',
    predicate => 1,
  );
}

my @remote_attributes = uniq(
  @SyForm::CommonRole::EventHTML::attributes,
  @SyForm::CommonRole::GlobalHTML::attributes,
);

has submit_attributes => (
  is => 'lazy',
);

sub _build_submit_attributes {
  my ( $self ) = @_;
  return {};
}

has no_submit => (
  is => 'lazy',
);

sub _build_no_submit {
  my ( $self ) = @_;
  return 0;
}

has submit => (
  is => 'lazy',
);

sub _build_submit {
  my ( $self ) = @_;
  return SyForm::ViewField::InputHTML->new(
    type => 'submit',
    %{$self->submit_attributes},
  );
}

has children => (
  is => 'ro',
  predicate => 1,
);

has html_attributes => (
  is => 'lazy',
);

sub _build_html_attributes {
  my ( $self ) = @_;
  my %html_attributes = %{$self->data_attributes};
  for my $key (@remote_attributes, @attributes) {
    my $has = 'has_'.$key;
    $html_attributes{$key} = $self->$key if $self->$has;
  }
  return { %html_attributes };
}

has html_declare => (
  is => 'lazy',
);

sub _build_html_declare {
  my ( $self ) = @_;
  return FORM {
    %{$self->html_attributes},
    _ => [
      $self->has_children ? ( map { $_->html_declare } @{$self->children} ) : (),
      $self->no_submit ? () : ( $self->submit->html_declare ),
    ],
  };
}

has html_declare_children => (
  is => 'lazy',
);

sub _build_html_declare_children {
  my ( $self ) = @_;
  my @children;
  for my $child (@{$self->children}) {
    if (!ref $child || $child->$_isa('HTML::Declare')) {
      push @children, $child;
    } else {
      push @children, $child->html_declare;
    }
  }
  return;
}

1;

__END__

=pod

=head1 NAME

SyForm::FormHTML - HTML Form

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
