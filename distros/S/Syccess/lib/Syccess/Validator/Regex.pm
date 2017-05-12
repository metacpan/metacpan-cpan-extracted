package Syccess::Validator::Regex;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A validator to check with a regex
$Syccess::Validator::Regex::VERSION = '0.104';
use Moo;

with qw(
  Syccess::ValidatorSimple
);

has message => (
  is => 'lazy',
);

sub _build_message {
  return 'Your value for %s is not valid.';
}

sub validator {
  my ( $self, $value ) = @_;
  my $regex = $self->arg;
  my $r = ref $regex eq 'Regexp' ? $regex : qr{$regex};
  return $self->message unless $value =~ m/$r/;
  return;
}

1;

__END__

=pod

=head1 NAME

Syccess::Validator::Regex - A validator to check with a regex

=head1 VERSION

version 0.104

=head1 SYNOPSIS

  Syccess->new(
    fields => [
      foo => [ regex => qr/^\w+$/ ],
      bar => [ regex => {
        arg => '^[a-z]+$', # will be converted to regexp
        message => 'We only allow lowercase letters on this field.',
      } ],
    ],
  );

=head1 DESCRIPTION

This validator allows checking against a regular expression. The regular
expression can be given as Regex or plain scalar, which will be converted
to a Regex.

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
