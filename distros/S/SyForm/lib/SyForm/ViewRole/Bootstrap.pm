package SyForm::ViewRole::Bootstrap;
BEGIN {
  $SyForm::ViewRole::Bootstrap::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Bootstrap view functions
$SyForm::ViewRole::Bootstrap::VERSION = '0.103';
use Moo::Role;
use SyForm::FormBootstrap;

# Should be on, when the roles are dynamical
#use overload '""' => sub { $_[0]->html_bootstrap };

has html_bootstrap => (
  is => 'lazy',
);

sub _build_html_bootstrap {
  my ( $self ) = @_;
  return $self->html_declare_bootstrap->as_html;
}

has html_declare_bootstrap => (
  is => 'lazy',
);

sub _build_html_declare_bootstrap {
  my ( $self ) = @_;
  return $self->syform_formbootstrap->html_declare;
}

has syform_formbootstrap => (
  is => 'lazy',
);

sub _build_syform_formbootstrap {
  my ( $self ) = @_;
  return SyForm::FormBootstrap->new(
    syform_formhtml => $self->syform_formhtml,
    $self->syform->has_bootstrap ? ( %{$self->syform->bootstrap} ) : (),
  );
}

1;

__END__

=pod

=head1 NAME

SyForm::ViewRole::Bootstrap - Bootstrap view functions

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
