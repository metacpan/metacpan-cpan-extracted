package Module::Faker::Module;
# ABSTRACT: a faked module
$Module::Faker::Module::VERSION = '0.022';
use Moose;
with 'Module::Faker::Appendix';

use Module::Faker::Package;

has filename => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has packages => (
  is         => 'ro',
  isa        => 'ArrayRef[Module::Faker::Package]',
  required   => 1,
  auto_deref => 1,
);

sub as_string {
  my ($self) = @_;

  my $string = '';

  my @packages = $self->packages;

  for ($packages[0]) {
    $string .= sprintf "\n=head1 NAME\n\n%s - %s\n\n=cut\n\n",
      $_->name, $_->abstract // 'a cool package';
  }

  for my $pkg ($self->packages) {
    $string .= $pkg->as_string . "\n";
  }

  $string .= "1\n";
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Faker::Module - a faked module

=head1 VERSION

version 0.022

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
