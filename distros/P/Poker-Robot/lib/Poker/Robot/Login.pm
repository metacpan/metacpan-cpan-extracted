package Poker::Robot::Login;
use Moo;

=encoding utf8

=head1 NAME

Poker::Robot::Login - Simple class to represent a user. Used internally by Poker::Robot

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


has 'login_id' => (
  is       => 'rw',
  required => 1,
);

has 'user_id' => (
  is        => 'rw',
  predicate => 'has_user_id',
);

has 'block' => (
  is  => 'rw',
  isa => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { return {} },
);

has 'level' => (
  is      => 'rw',
);

has 'bookmark' => ( is => 'rw', );

has 'chips' => (
  is      => 'rw',
  isa => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { return {} },
);

has 'username'   => ( is => 'rw', );
has 'password'   => ( is => 'rw', );
has 'email'      => ( is => 'rw', );
has 'birthday'   => ( is => 'rw', );
has 'reg_date'   => ( is => 'rw', );
has 'last_visit' => ( is => 'rw', );
has 'handle'     => ( is => 'rw', );
has 'remote_address' => ( is => 'rw', );

=head1 AUTHOR

Nathaniel Graham, C<ngraham@cpan.org> 

=head1 BUGS

Please report any bugs or feature requests directly to C<ngraham@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT license.

=cut

1;

