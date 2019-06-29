package Telegram::Bot::Object::User;
$Telegram::Bot::Object::User::VERSION = '0.012';
# ABSTRACT: The base class for Telegram message 'User' type.

use Mojo::Base 'Telegram::Bot::Object::Base';

has 'id';
has 'first_name';
has 'last_name';
has 'username';

sub fields {
  return { scalar => [qw/id first_name last_name username/]
         };
}

sub is_group { 0 }
sub is_user  { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::User - The base class for Telegram message 'User' type.

=head1 VERSION

version 0.012

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
