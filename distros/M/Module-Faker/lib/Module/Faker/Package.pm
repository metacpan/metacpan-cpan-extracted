package Module::Faker::Package;
# ABSTRACT: a faked package in a faked module
$Module::Faker::Package::VERSION = '0.022';
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

version 0.022

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
