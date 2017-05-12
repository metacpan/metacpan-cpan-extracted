package Net::Posterous::Site;

use strict;
use base qw(Net::Posterous::Object);
use Class::Accessor "antlers";

=head1 NAME

Net::Posterous::Site - represent a site instance in Net::Posterous

=head1 METHODS

=cut

=head2 id

Get or set the id for this Site.

=cut

has id              => ( is => "rw", isa => "Int"  );

=head2 name

Get or set the name for this Site.

=cut

has name            => ( is => "rw", isa => "Str"  );

=head2 url

Get or set the url for this Site.

=cut

has url             => ( is => "rw", isa => "Str"  );

=head2 private

Get or set whether this Site is private or not.

=cut

has private         => ( is => "rw", isa => "Bool" );

=head2 primary

Get or set whether this Site is the primary site or not.

=cut

has primary         => ( is => "rw", isa => "Bool" );

=head2 comments_enabled

=head2 commentsenabled

Get or set whether this Site has comments enabled.

C<commentsenabled> is an alias due to Posterous having interestingly inconsistent naming schema.

=cut

sub comments_enabled { shift->commentsenabled(@_); }

has commentsenabled => ( is => "rw", isa => "Bool" );

=head2 num_posts

Get or set the number of posts this Site has.

=cut

has num_posts        => ( is => "rw", isa => "Int"  );

1;