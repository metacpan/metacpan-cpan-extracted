package Syccess::Validator::Call;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A validator to check via call to a method
$Syccess::Validator::Call::VERSION = '0.104';
use Moo;
use Carp qw( croak );

with qw(
  Syccess::ValidatorSimple
);

has not => (
  is => 'ro',
  predicate => 1,
);

sub BUILD {
  my ( $self ) = @_;
  croak __PACKAGE__.' cant have arg and not'
    if $self->has_arg and $self->has_not;
  croak __PACKAGE__.' requires arg or not'
    unless $self->has_arg or $self->has_not;
}

has message => (
  is => 'lazy',
);

sub _build_message {
  return 'Your value for %s is not valid.';
}

sub validator {
  my ( $self, $value ) = @_;
  # probably making function() possible, don't know yet how, as the
  # function will be not available in my scope probably, and calling
  # on main:: doesnt sound much of a "functionality"
  my ( $thing, $method ) = @{$self->has_arg ? $self->arg : $self->not};
  my $not = $self->has_not ? 1 : 0;
  my $return = $thing->$method($value) ? 1 : 0;
  return if ( $return and !$not ) or ( !$return and $not );
  return $self->message;
}

1;

__END__

=pod

=head1 NAME

Syccess::Validator::Call - A validator to check via call to a method

=head1 VERSION

version 0.104

=head1 SYNOPSIS

  Syccess->new(
    fields => [
      foo => [ call => [ $thing, 'whitelisted' ] ],
      baz => [ call => { not => [ $thing, 'blacklisted' ] } ],
      bar => [ call => {
        not => [ $thing, 'blacklisted' ],
        message => 'You have 5 seconds to comply.'
      } ],
    ],
  );

=head1 DESCRIPTION

This validator allows checking against a method call on an object. If used
with the B<not> parameter, it will see success if the called method gives back
a B<false> value, else it will succeed on a B<true> value.

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
