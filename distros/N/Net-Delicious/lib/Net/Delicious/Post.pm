# $Id: Post.pm,v 1.25 2008/03/03 16:55:04 asc Exp $
use strict;

package Net::Delicious::Post;
use base qw (Net::Delicious::Object);

$Net::Delicious::Post::VERSION = '1.14';

=head1 NAME

Net::Delicious::Post - OOP for del.icio.us post thingies

=head1 SYNOPSIS

  use Net::Delicious;
  my $del = Net::Delicious->new({...});

  foreach my $post ($del->recent_posts()) {

      # $post is a Net::Delicious::Post 
      # object.

      print "$post\n";
  }

=head1 DESCRIPTION

OOP for del.icio.us post thingies.

=head1 NOTES

=over 4

=item *

This package overrides the perl builtin I<stringify> operator and returns the value of the object's I<href> method.

=item *

It isn't really expected that you will instantiate these
objects outside of I<Net::Delicious> itself.

=back

=cut

use Net::Delicious::User;
use overload q("") => sub { shift->href() };

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Returns a I<Net::Delicious::Post> object. Woot!

=cut

sub new {
    my $pkg  = shift;
    my $args = shift;
    
    my $self = $pkg->SUPER::new($args);

    # this one seems to be the source of some
    # confusion - unclear whether it's me or
    # inconsistency in the API itself

    $self->{tags} ||= $args->{ tag };

    $self->{user} = Net::Delicious::User->new({name => $args->{user}});
    return $self;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->description()

Returns a string.

=cut

# Defined in Net::Delicious::Object

=head2 $obj->extended()

Returns a string.

=cut

# Defined in Net::Delicious::Object

=head2 $obj->href()

Returns a string.

=cut

# Defined in Net::Delicious::Object

sub url {
        return shift->href();
}

sub link {
        return shift->href();
}

=head2 $obj->tag()

Returns a string.

=cut

# Defined in Net::Delicious::Object

=head2 $obj->tags()

Returns a string.

=cut

sub tags {
    return shift->tag();
}

=head2 $obj->user()

Returns a Net::Delicious::User object.

=cut

sub user {
        return shift->{user};
}

=head2 $obj->time()

Returns a string, formatted I<YYYY-MM-DD>

=cut

# Defined in Net::Delicious::Object

=head2 $obj->shared($raw)

Returns a boolean, unless $raw is true in which case the method will return
"no" or ""

=cut

sub shared {
        my $self = shift;
        my $raw  = shift;

        if ($raw) {
                return $self->{shared};
        }

        return ($self->{shared} eq "no") ? 0 : 1;
}

=head2 $obj->as_hashref()

Return the object as a hash ref safe for serializing and re-blessing.

=cut

sub as_hashref {
        my $self = shift;

        my $data      = $self->SUPER::as_hashref();
        $data->{user} = $self->user()->name();

        return $data;
}

=head1 VERSION

1.13

=head1 DATE

$Date: 2008/03/03 16:55:04 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

L<Net::Delicious>

=head1 LICENSE

Copyright (c) 2004-2008 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
