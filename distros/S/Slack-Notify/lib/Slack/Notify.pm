package Slack::Notify {
$Slack::Notify::VERSION = '0.002';
# ABSTRACT: Trigger Slack incoming webhooks

use namespace::autoclean;

use Moo;
use Types::Standard qw(Str);
use Type::Utils qw(class_type);

use HTTP::Tiny;
use JSON::MaybeXS;

has hook_url => ( is => 'ro', isa => Str, required => 1 );

has _http => ( is => 'lazy', isa => class_type('HTTP::Tiny') );
sub _build__http { HTTP::Tiny->new }

sub post {
  my ($self, %args) = @_;
  my $payload = Slack::Notify::Payload->new(%args);
  $self->_http->post_form(
    $self->hook_url,
    { payload => encode_json($payload->to_hash) },
  );
}

}

package # hide from PAUSE
  Slack::Notify::Payload {

use namespace::autoclean;

use Moo;
use Types::Standard qw(Str ArrayRef HashRef);
use Type::Utils qw(class_type);


has text       => ( is => 'ro', isa => Str );
has username   => ( is => 'ro', isa => Str );
has icon_url   => ( is => 'ro', isa => Str );
has icon_emoji => ( is => 'ro', isa => Str );

has attachments => (
  is     => 'ro',
  isa    => ArrayRef[class_type('Slack::Notify::Attachment')->plus_coercions(HashRef, 'Slack::Notify::Attachment->new(%$_)')],
  coerce => 1,
);

sub to_hash { shift->_hash }
has _hash => ( is => 'lazy', isa => HashRef );
sub _build__hash {
  my ($self) = @_;
  +{
    %$self,
    map { defined $self->$_ ? ($_ => [ map { $_->to_hash } @{$self->{$_}} ]) : () } qw(attachments),
  };
}

}

package # hide from PAUSE
  Slack::Notify::Attachment {

use namespace::autoclean;

use Moo;
use Types::Standard qw(Str Int ArrayRef HashRef);
use Type::Utils qw(class_type);

has fallback    => ( 'is' => 'ro', isa => Str );
has color       => ( 'is' => 'ro', isa => Str );
has pretext     => ( 'is' => 'ro', isa => Str );
has author_name => ( 'is' => 'ro', isa => Str );
has author_link => ( 'is' => 'ro', isa => Str );
has author_icon => ( 'is' => 'ro', isa => Str );
has title       => ( 'is' => 'ro', isa => Str );
has title_link  => ( 'is' => 'ro', isa => Str );
has text        => ( 'is' => 'ro', isa => Str );
has image_url   => ( 'is' => 'ro', isa => Str );
has thumb_url   => ( 'is' => 'ro', isa => Str );
has footer      => ( 'is' => 'ro', isa => Str );
has footer_icon => ( 'is' => 'ro', isa => Str );
has ts          => ( 'is' => 'ro', isa => Int );

has fields => (
  is     => 'ro',
  isa    => ArrayRef[class_type('Slack::Notify::Field')->plus_coercions(HashRef, 'Slack::Notify::Field->new(%$_)')],
  coerce => 1,
);

sub to_hash { shift->_hash }
has _hash => ( is => 'lazy', isa => HashRef );
sub _build__hash {
  my ($self) = @_;
  +{
    %$self,
    map { defined $self->$_ ? ($_ => [ map { $_->to_hash } @{$self->{$_}} ]) : () } qw(fields),
  };
}

}

package # hide from PAUSE
  Slack::Notify::Field {

use namespace::autoclean;

use Moo;
use Types::Standard qw(Str Bool HashRef);

has title => ( 'is' => 'ro', isa => Str );
has value => ( 'is' => 'ro', isa => Str );
has short => ( 'is' => 'ro', isa => Bool );

sub to_hash { shift->_hash }
has _hash => ( is => 'lazy', isa => HashRef );
sub _build__hash { my ($self) = @_; +{ %$self } }

}

1;

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/Slack-Notify.png)](http://travis-ci.org/robn/Slack-Notify)

=head1 NAME

Slack-Notify - Trigger Slack incoming webhooks

=head1 SYNOPSIS

    use Slack::Notify;

    my $n = Slack::Notify->new(
      hook_url => 'https://hooks.slack.com/services/...',
    );

    $n->post(
      text => "something happened",
    );

=head1 DESCRIPTION

This is a simple client for L<Slack incoming webhooks|https://api.slack.com/incoming-webhooks>.

Create a C<Slack::Notify> object with the URL of an incoming hook, then call
the C<post> method to trigger it.

=head1 CONSTRUCTOR

=head2 new

    my $n = Slack::Notify->new;

This constructor returns a new Slack::Notify object. Valid arguments include:

=over 4

=item *

C<hook_url>

The Slack incoming hook URL. Create one of these in the Slack integrations config.

=back

=head1 METHODS

=head2 post

    $n->post(
      text => 'something happened',

Triggers the hook. There's several arguments you can supply, which are
described in more detail in the
L<incoming hook documentation|https://api.slack.com/incoming-webhooks>.

=over 4

=item *

C<text>

A simple, multi-line message without special formatting.

=item *

C<username>

Value to use for the username, overriding the one set in the hook config.

=item *

C<icon_url>

URL of an image to use for the icon, overriding the one set in the hook config.

=item *

C<icon_emoji>

An emoji code (eg C<:+1:>) to use for the icon, overriding the one set in the hook config.

=item *

C<attachments>

An arrayref containing some attachment objects. See the
L<attachment guide|https://api.slack.com/docs/message-attachments> for details.
At the moment this module supports attachment fields, but not buttons, menus
and other interactive ocontent.

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/Slack-Notify/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Slack-Notify>

  git clone https://github.com/robn/Slack-Notify.git

=head1 AUTHORS

=over 4

=item *

Rob N ★ <robn@robn.io>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Rob N ★

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
