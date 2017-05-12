package Module::Faker::Module;
# ABSTRACT: a faked module
$Module::Faker::Module::VERSION = '0.017';
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

  for my $pkg ($self->packages) {
    $string .= sprintf "package %s;\n", $pkg->name;
    $string .= sprintf "our \$VERSION = '%s';\n", $pkg->version
      if defined $pkg->version;

    if (defined $pkg->abstract) {
      $string .= sprintf "\n=head1 NAME\n\n%s - %s\n\n=cut\n\n",
        $pkg->name, $pkg->abstract
    }
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

version 0.017

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
