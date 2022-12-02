package Module::Faker::Package 0.023;
# ABSTRACT: a faked package in a faked module

use Moose;

use Moose::Util::TypeConstraints;

has name     => (is => 'ro', isa => 'Str', required => 1);
has version  => (is => 'ro', isa => 'Maybe[Str]');
has abstract => (is => 'ro', isa => 'Maybe[Str]');
has style    => (is => 'ro', default => 'legacy');

has in_file  => (
  is       => 'ro',
  isa      => 'Str',
  lazy     => 1,
  default  => sub {
    my ($self) = @_;
    my $name = $self->name;
    $name =~ s{::}{/}g;
    return "lib/$name";
  },
);

sub _format_legacy {
  my ($self) = @_;

  my $string = q{};

  $string .= sprintf "package %s;\n", $self->name;
  $string .= sprintf "our \$VERSION = '%s';\n", $self->version
    if defined $self->version;

  return $string;
}

sub _format_statement {
  my ($self) = @_;

  my $string = q{};

  $string .= sprintf "package %s%s;\n",
    $self->name,
    (defined $self->version ? (q{ } . $self->version) : '');

  return $string;
}

sub _format_block {
  my ($self) = @_;

  my $string = sprintf "package %s%s {\n\n  # Your code here\n\n}\n",
    $self->name,
    (defined $self->version ? (q{ } . $self->version) : '');

  return $string;
}

sub as_string {
  my ($self) = @_;

  my $style = $self->style;

  unless (ref $style) {
    confess("unknown package style: $style") unless $self->can("_format_$style");
    $style = "_format_$style";
  }

  return $self->$style;
}

subtype 'Module::Faker::Type::Packages'
  => as 'ArrayRef[Module::Faker::Package]';

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Faker::Package - a faked package in a faked module

=head1 VERSION

version 0.023

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
