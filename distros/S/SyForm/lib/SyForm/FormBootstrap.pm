package SyForm::FormBootstrap;
BEGIN {
  $SyForm::FormBootstrap::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Bootstrap Form
$SyForm::FormBootstrap::VERSION = '0.102';
use Moo;
use HTML::Declare ':all';
use Safe::Isa;

with qw(
  MooX::Traits
);

our @attributes = qw();

for my $attribute (@attributes) {
  has $attribute => (
    is => 'ro',
    predicate => 1,
  );
}

has syform_formhtml => (
  is => 'ro',
  required => 1,
);

has layout => (
  is => 'lazy',
);

sub _build_layout {
  my ( $self ) = @_;
  return 'basic';
}

1;

__END__

=pod

=head1 NAME

SyForm::FormBootstrap - Bootstrap Form

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
