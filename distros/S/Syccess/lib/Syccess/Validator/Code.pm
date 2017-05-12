package Syccess::Validator::Code;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A validator to check a value through a simple coderef
$Syccess::Validator::Code::VERSION = '0.104';
use Moo;

with qw(
  Syccess::Validator
);

has message => (
  is => 'lazy',
);

sub _build_message {
  return 'Your value for %s is not valid.';
}

sub validate {
  my ( $self, %params ) = @_;
  my $name = $self->syccess_field->name;
  return if !exists($params{$name})
    || !defined($params{$name})
    || $params{$name} eq '';
  my $value = $params{$name};
  my $code = $self->arg;
  my @return;
  for ($value) {
    push @return, $code->($self,%params);
  }
  return map { !defined $_ ? $self->message : $_ } @return;
}

1;

__END__

=pod

=head1 NAME

Syccess::Validator::Code - A validator to check a value through a simple coderef

=head1 VERSION

version 0.104

=head1 SYNOPSIS

  Syccess->new(
    fields => [
      foo => [ code => sub { $_ > 3 ? () : ('You are WRONG!') } ],
      bar => [ code => {
        arg => sub { $_ > 5 ? () : (undef) },
        message => 'You have 5 seconds to comply.'
      } ],
    ],
  );

=head1 DESCRIPTION

This validator allows checking against a CodeRef. The CodeRef will be getting
all parameters on B<@_> as Hash, and the specific parameter value for to check
against will be in B<$_>, so the coderef can decide which way he want to check.

The CodeRef should give back nothing (not even B<undef>) if its a success. Else
if should give back B<undef> to release the error message given on L</message>
or the default error message B<'Your value for %s is not valid.'>. Alternative
it can also give back a string which will be used as B<message> for the error.

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
