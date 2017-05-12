package Net::Google::PicasaWeb::Comment;
{
  $Net::Google::PicasaWeb::Comment::VERSION = '0.12';
}
use Moose;

# ABSTRACT: represents a single Picasa Web comment

extends 'Net::Google::PicasaWeb::Feed';


has content => (
    is          => 'rw',
    isa         => 'Str',
);


override from_feed => sub {
    my ($class, $service, $entry) = @_;
    my $self = super();

    $self->content($entry->field('content'));
    return $self;
};


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Net::Google::PicasaWeb::Comment - represents a single Picasa Web comment

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  my @comments = $service->list_comments;
  for my $comment (@comments) {
      print "Title: ", $comment->title, "\n";
      print "Content: ", $photo->content, "\n";
  }

=head1 DESCRIPTION

Represents an individual Picasa Web comment. This class extends L<Net::Google::PicasaWeb::Feed>.

=head1 ATTRIBUTES

=head2 url

The URL used to get information about the object. See L<Net::Google::PicasaWeb::Feed/url>.

=head2 title

This is the name of the person that made the comment. See L<Net::Google::PicasaWeb:::Feed/title>.

=head2 content

This is the comment that was made.

=head2 author_name

This is the author of the comment. See L<Net::Google::PicasaWeb::Feed/author_name>.

=head2 author_uri

This is the URL to get to the author's public albums on Picasa Web. See L<Net::Google::PicasaWeb::Feed/author_uri>.

=head2 entry_id

This is the unique ID for the comment. See L<Net::Google::PicasaWeb::Feed/entry_id>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Sterling Hanenkamp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
