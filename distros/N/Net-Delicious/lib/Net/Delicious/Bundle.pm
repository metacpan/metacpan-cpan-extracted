# $Id: Bundle.pm,v 1.13 2008/03/03 16:55:04 asc Exp $
use strict;

package Net::Delicious::Bundle;
use base qw (Net::Delicious::Object);

$Net::Delicious::Bundle::VERSION = '1.14';

use overload q("") => sub { shift->name(); };

=head1 NAME

Net::Delicious::Bundle - OOP for del.icio.us bundle thingies

=head1 SYNOPSIS

  use Net::Delicious;
  my $del = Net::Delicious->new({...});

  foreach my $bundle ($del->bundles()) {

      # $post is a Net::Delicious::Bundle 
      # object.

      print "$bundle\n";
  }

=head1 DESCRIPTION

OOP for del.icio.us bundle thingies.

=head1 NOTES

=over 4

=item *

This package overrides the perl builtin I<stringify> operator and
returns the value of the object's I<name> method.

=item *

It isn't really expected that you will instantiate these
objects outside of I<Net::Delicious> itself.

=back

=cut

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Returns a I<Net::Delicious::Bundle> object. Woot!

=cut

# Defined in Net::Delicious::Object

=head1 OBJECT METHODS

=cut

=head2 $obj->name()

Returns a string.

=cut

# Defined in Net::Delicious::Object

=head2 $obj->tags()

Returns a list.

=cut

sub tags {
        my $self = shift;
        my $tags = $self->{tags};
        
        if (wantarray) {
                return (split(" ",$tags));
        }
        
        return $tags;
}

=head2 $obj->as_hashref()

Return the object as a hash ref safe for serializing and re-blessing.

=cut

# Defined in Net::Delicious::Object

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
