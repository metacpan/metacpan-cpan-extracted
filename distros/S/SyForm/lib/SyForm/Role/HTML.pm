package SyForm::Role::HTML;
BEGIN {
  $SyForm::Role::HTML::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: SyForm::ViewRole::HTML configuration of the form
$SyForm::Role::HTML::VERSION = '0.102';
use Moo::Role;

has html => (
  is => 'ro',
  predicate => 1,
);

has html_submit => (
  is => 'ro',
  predicate => 1,
);

has no_html_submit => (
  is => 'lazy',
);

sub _build_no_html_submit {
  my ( $self ) = @_;
  return 0;
}

1;

__END__

=pod

=head1 NAME

SyForm::Role::HTML - SyForm::ViewRole::HTML configuration of the form

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
