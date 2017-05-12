package Silki::AppRole::User;
{
  $Silki::AppRole::User::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Schema::User;

use Moose::Role;

has 'user' => (
    is      => 'ro',
    isa     => 'Silki::Schema::User',
    lazy    => 1,
    builder => '_build_user',
);

sub _build_user {
    my $self = shift;

    my $cookie = $self->authen_cookie_value();

    my $user;
    $user = Silki::Schema::User->new( user_id => $cookie->{user_id} )
        if $cookie->{user_id};

    return $user ||= Silki::Schema::User->GuestUser();
}

1;

# ABSTRACT: Adds $c->user() to the Catalyst object

__END__
=pod

=head1 NAME

Silki::AppRole::User - Adds $c->user() to the Catalyst object

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

