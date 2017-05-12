package OpenFrame::AppKit::Session;

use strict;
use warnings::register;

use Cache::FileCache;
use Digest::MD5 qw(md5_hex);

our $VERSION=3.03;

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  $self->generate_id;
}

sub id {
  my $self = shift;
  return $self->{_id};
}

sub generate_id {
  my $self = shift;
  return $self->{_id} if exists $self->{_id};
  my $id = substr(md5_hex(time() . md5_hex(time(). {}. rand(). $$)), 0, 16);
  $self->{_id} = $id;
}

sub store {
  my $self = shift;
  Cache::FileCache->new()->set( $self->id, $self );
  return $self->id;
}

sub fetch {
  my $class = shift;
  my $id    = shift;
  return Cache::FileCache->new()->get( $id );
}

sub get {
  my $self = shift;
  my $key  = shift;
  return $self->{ $key };
}

sub set {
  my $self = shift;
  my $key  = shift;
  $self->{ $key } = shift;
  return $self;
}

1;

=head1 NAME 

OpenFrame::AppKit::Session - sessions for OpenFrame

=head1 SYNOPSIS

  use OpenFrame::AppKit::Session;
  
  my $session = OpenFrame::AppKit::Session->new();

  my $id = $session->id();
  $session->store();

  my $restored = OpenFrame::AppKit::Session->fetch( $id );

=head1 DESCRIPTION

OpenFrame::AppKit::Session provides a session class that is capable of 
being stored and restored from disk.  The session expects you to treat
it as a standard HASH for all intents and purposes, but does allow you
to encapsulate that with the methods get and set for top level keys.

=head1 METHODS

=over 4

=item * new

The C<new()> method instantiates a new OpenFrame::AppKit::Session and returns
it.

=item * init 

The C<init()> method provides initialization routines for OpenFrame::AppKit::Session

=item * id

The C<id()> method returns the sessions id

=item * generate_id

The C<generate_id()> method returns a new id, or the old id if it has already been generated.

=item * store

The C<store()> method serializes the session to disk.  It returns the session id that can be
used to restore the session.

=item * fetch

The C<fetch()> method takes a session id as a parameter and returns a restored session from disk.
In the case that the session is unavailable it returns nothing.

=item * get

The C<get()> method simply returns a key as specified by the first parameter and returns its value.

=item * set

The C<set()> method simply sets a key value pair as specified by the first two parameters.

=back

=head1 SEE ALSO

OpenFrame::AppKit::Segment::Sesssion

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd. All Rights Reserved

This program is released under the same license as Perl itself.

=cut
