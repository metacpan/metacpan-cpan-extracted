package Slack::BlockKit::Block::Image 0.005;
# ABSTRACT: a Block Kit image block, used to show an image

use Moose;
use MooseX::StrictConstructor;

with 'Slack::BlockKit::Role::Block';

#pod =head1 OVERVIEW
#pod
#pod This represents an C<image> block, which displays an image.
#pod
#pod =cut

use v5.36.0;

use Moose::Util::TypeConstraints qw(class_type);
use MooseX::Types::Moose qw(ArrayRef);

#pod =attr alt_text
#pod
#pod This is a simple string, which provides alt text.  It's I<not> a text
#pod composition object, and can't contain Markdown or mrkdwn.
#pod
#pod =cut

has alt_text => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

#pod =attr image_url
#pod
#pod This is a string giving the URL for the image.  If you don't provide this,
#pod you'd have to provide C<slack_file>.  Unfortunately, though, Slack::BlockKit
#pod doesn't support that!
#pod
#pod =cut

has image_url => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_image_url',
  required => 1, # eventually, allow an unset image_url if we add slack_file
);

#pod =attr title
#pod
#pod This attribute stores a title to display for the image.  It should be a L<text
#pod composition object|Slack::BlockKit::CompObj::Text>, but it's optional and you
#pod can leave it out.
#pod
#pod =cut

has title => (
  is => 'ro',
  isa => class_type('Slack::BlockKit::CompObj::Text'),
  predicate => 'has_title',
);

sub BUILD ($self, @) {
  if ($self->has_title && $self->title->type ne 'plain_text') {
    Carp::croak("non-plain_text text object provided as title for image");
  }
}

sub as_struct ($self) {
  return {
    type => 'image',
    image_url => $self->image_url,
    alt_text  => $self->alt_text,
    ($self->has_title
      ? (title => $self->title->as_struct)
      : ()),
  };
}

no Moose;
no Moose::Util::TypeConstraints;
no MooseX::Types::Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::Image - a Block Kit image block, used to show an image

=head1 VERSION

version 0.005

=head1 OVERVIEW

This represents an C<image> block, which displays an image.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 alt_text

This is a simple string, which provides alt text.  It's I<not> a text
composition object, and can't contain Markdown or mrkdwn.

=head2 image_url

This is a string giving the URL for the image.  If you don't provide this,
you'd have to provide C<slack_file>.  Unfortunately, though, Slack::BlockKit
doesn't support that!

=head2 title

This attribute stores a title to display for the image.  It should be a L<text
composition object|Slack::BlockKit::CompObj::Text>, but it's optional and you
can leave it out.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
