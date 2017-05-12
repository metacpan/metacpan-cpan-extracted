package Syccess::Validator::Required;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A validator to check for a required field
$Syccess::Validator::Required::VERSION = '0.104';
use Moo;

with qw(
  Syccess::Validator
);

has message => (
  is => 'lazy',
);

sub _build_message {
  return '%s is required.';
}

sub validate {
  my ( $self, %params ) = @_;
  my $name = $self->syccess_field->name;
  return $self->message if !exists($params{$name})
    || !defined($params{$name})
    || $params{$name} eq '';
  return;
}

1;

__END__

=pod

=head1 NAME

Syccess::Validator::Required - A validator to check for a required field

=head1 VERSION

version 0.104

=head1 SYNOPSIS

  Syccess->new(
    fields => [
      foo => [ required => 1 ],
      bar => [ required => {
        message => 'You have 5 seconds to comply.'
      } ],
    ],
  );

=head1 DESCRIPTION

This validator allows to check if a field is required. The default error
message is B<'%s is required.'> and can be overriden via the L</message>
parameter.

=head1 ATTRIBUTES

=head2 message

This contains the error message or the format for the error message
generation. See L<Syccess::Error/validator_message>.

=encoding utf8

=head1 SUPPORT

IRC

  Join irc.perl.org and msg Getty

Repository

  http://github.com/Getty/p5-syccess
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-syccess/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
