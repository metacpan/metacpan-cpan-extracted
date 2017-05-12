package SyForm::ViewRole::HTML;
BEGIN {
  $SyForm::ViewRole::HTML::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: HTML view functions
$SyForm::ViewRole::HTML::VERSION = '0.102';
use Moo::Role;
use SyForm::FormHTML;

use overload '""' => sub { $_[0]->html };

has html => (
  is => 'lazy',
);

sub _build_html {
  my ( $self ) = @_;
  return $self->html_declare->as_html;
}

has html_declare => (
  is => 'lazy',
);

sub _build_html_declare {
  my ( $self ) = @_;
  return $self->syform_formhtml->html_declare;
}

has syform_formhtml => (
  is => 'lazy',
);

sub _build_syform_formhtml {
  my ( $self ) = @_;
  return SyForm::FormHTML->new(
    children => [
      map {
        $_->has_syform_formhtml_children ? (
          @{$_->syform_formhtml_children}
        ) : (),
      } $self->fields->Values
    ],
    no_submit => $self->syform->no_html_submit,
    $self->syform->has_html_submit ? (
      submit_attributes => $self->syform->html_submit,
    ) : (),
    $self->syform->has_html ? ( %{$self->syform->html} ) : ()
  );
}

1;

__END__

=pod

=head1 NAME

SyForm::ViewRole::HTML - HTML view functions

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
