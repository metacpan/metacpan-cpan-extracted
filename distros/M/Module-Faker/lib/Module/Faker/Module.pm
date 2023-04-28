package Module::Faker::Module 0.024;
# ABSTRACT: a faked module

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

version 0.024

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
