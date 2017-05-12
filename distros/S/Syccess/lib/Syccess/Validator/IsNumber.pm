package Syccess::Validator::IsNumber;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A validator to check if value is a number
$Syccess::Validator::IsNumber::VERSION = '0.104';
use Moo;
use Scalar::Util qw( looks_like_number );

with qw(
  Syccess::ValidatorSimple
);

has message => (
  is => 'lazy',
);

sub _build_message {
  return '%s must be a number.';
}

sub validator {
  my ( $self, $value ) = @_;
  return $self->message unless looks_like_number($value);
  return;
}

1;

__END__

=pod

=head1 NAME

Syccess::Validator::IsNumber - A validator to check if value is a number

=head1 VERSION

version 0.104

=head1 SYNOPSIS

  Syccess->new(
    fields => [
      foo => [ is_number => 1 ],
      bar => [ is_number => { message => 'This is not cool!' } ],
    ],
  );

=head1 DESCRIPTION

This simple validator only checks if the given value is a number (using
I<looks_like_number> of L<Scalar::Util>). The parameter given will not be used,
but as usual you can override the error message by given B<message>.

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
