package Mojo::URL::Role::Auth;

use Mojo::Base -role, -signatures;
has [qw(username password)];

our $VERSION = '0.1.0';

sub auth {
  my ($self, $user, $pass)  = @_;

  if(!defined $user && !defined $pass) {
    return undef unless defined $self->username;
    return $self->username unless defined $self->password;
    return sprintf("%s:%s", $self->username, $self->password);
  }
  elsif(!defined $pass) {
    ($user, $pass) = split ':', $user, 2;
  }

  $self->username($user);
  $self->password($pass);

  return $self->userinfo($self->auth);
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::URL::Role::Auth - Use 2-arg function to add userinfo to url

=head1 SYNOPSIS

    my $url = Mojo::URL->new('https://example.com')->with_roles('+Auth');
    $url->auth('u53rn4m3', 'p455w0rd');
    say $url->to_unsafe_string; # gives https://u53rn4m3:p455w0rd@example.com

=head1 DESCRIPTION

This role adds a new method that takes two arguments to set userinfo for a url

=head1 METHODS

=head2 auth

    my $url = Mojo::URL->new->with_roles('+Auth');
    $url->auth('u53rn4m3', 'p455w0rd');

=head1 LICENSE

Copyright (C) Jari Matilainen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

vague E<lt>vague@cpan.orgE<gt>

=cut

