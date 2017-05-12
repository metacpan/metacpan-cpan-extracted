package OpenInteract2::Action::FlickrFeed;

use strict;
use base qw( OpenInteract2::Action::RSS );

$OpenInteract2::Action::FlickrFeed::VERSION = '0.02';

my $URL_TEMPLATE   = 'http://www.flickr.com/services/feeds/photos_public.gne?id=%s&format=%s';
my $DEFAULT_FORMAT = 'atom_03';

sub _get_feed_url {
    my ( $self ) = @_;
    my $feed_id = $self->param( 'feed_id' );
    unless ( $feed_id ) {
        die "To download a Flickr feed you must specify the parameter ",
            "'feed_id' in the configuration for action ", $self->name, "\n";
    }
    my $format  = $self->param( 'feed_format' ) || $DEFAULT_FORMAT;
    return sprintf( $URL_TEMPLATE, $feed_id, $format );
}

sub _modify_template_params {
    my ( $self, $params ) = @_;
    my $num_photos = $self->param( 'num_photos' ) || 0;
    my $feed = $params->{feed};
    my @entries = ();
    foreach my $entry ( $feed->entries ) {
        my $content = $entry->content->body; # already escaped
        my $photo_data = $self->_parse_flickr_content( $content );
        push @entries, $photo_data;
        last if ( $num_photos and scalar( @entries ) == $num_photos );
    }
    $params->{photos} = \@entries;
}

# We use simple regexes to extract the data from the content Flickr
# emits; therefore this is very dependent on the format, which is:

# <p><a href="http://www.flickr.com/people/FLICKRID/">USER NAME</a> posted a photo:</p>
#
# <p><a href="http://www.flickr.com/photos/FLICKRID/PHOTOID/" title="TITLE"><img src="http://photosSOMESERVER.flickr.com/PHOTOID_CHECKSUM.jpg" width="WIDTH" height="HEIGHT" alt="TITLE" style="border: 1px solid #000000;" /></a></p>

# Or with some data filled in:
#
# <p><a href="http://www.flickr.com/people/cwinters/">Chris Winters</a> posted a photo:</p>
#
# <p><a href="http://www.flickr.com/photos/cwinters/23093459/" title="Finished dining room with built-ins"><img src="http://photos17.flickr.com/23093459_db3244f1ef_m.jpg" width="240" height="180" alt="Finished dining room with built-ins" style="border: 1px solid #000000;" /></a></p> 

sub _parse_flickr_content {
    my ( $self, $content ) = @_;
    $content =~ s|^.*?</p>||;
    my ( $link )    = $content =~ m|<a href="([^"]+)"|;
    my ( $title )   = $content =~ m|title="([^"]+)"|;
    my ( $img_src ) = $content =~ m|src="([^"]+)"|;
    my ( $width, $height ) = $content =~ m|width="(\d+)"\s+height="(\d+)"|;
    return {
        link  => $link,  title  => $title, img_src => $img_src,
        width => $width, height => $height
    };
}

1;

__END__

=head1 NAME

OpenInteract2::Action::FlickrFeed - OpenInteract2 action to retrieve a Flickr feed and display it through a template

=head1 SYNOPSIS

First, you need to register your type; in your website's
conf/server.ini:

 [action_types]
 ...
 flickr = OpenInteract2::Action::FlickrFeed

Next, reference the action type in your package's conf/action.ini:

 [my_flickr]
 type         = flickr
 title        = My Flickr Photos
 feed_id      = 62037332@N99
 template     = myapp::flickr_feed
 cache_expire = 30m

Now you can deposit the results of your feed married to your
'myapp::flickr_feed' template:

 [% OI.action_execute( 'my_flickr' ) %]

You can also add it as a box:

 [% OI.box_add( 'my_flickr' ) %]

=head1 DESCRIPTION

This is a simple extension of L<OpenInteract2::Action::RSS> which
grabs interesting data out of the Atom/RSS Flickr feed and makes them
available to your template. So in addition to the 'feed' variable you
also have access to an array 'photos' which contains a number of
hashrefs with the following keys:

=over 4

=item *

B<link>: URL to the full page of this photo

=item *

B<title>: Title of this photo

=item *

B<img_src>: URL to small photo

=item *

B<width>: Image width (pixels)

=item *

B<height>: Image height (pixels)

=back

So you can do something like this in your template:

 Recent photos:<br /> 
 [% FOREACH photo = photos %]
   <a href="[% photo.link %]"
      title="[% photo.title %]"><img src="[% photo.img_src %]"
                                     width="[% photo.width %]"
                                     height="[% photo.height %]" /></a> <br />
 [% END %]

=head2 Properties

To make this happen you can define the following properties in your
action:

B<feed_id> (required)

This is the ID of your feed. To find it just browse to your Flickr
home page and find the 'RSS 2.0' or 'Atom' links toward the
bottom. They'll look something like this:

 http://www.flickr.com/services/feeds/photos_public.gne?id=62037332@N00&format=atom_03

The value following the C<id> parameter is what you want; in this case
it's '62037332@N00'.

B<template> (optional; default is defined in L<OpenInteract2::Action::RSS>)

Specify the template used to display your photos.

B<feed_format> (optional; default 'atom_03')

Define the 'format' to be passed in the URL. By default this is
'atom_03' and you'll probably never need to change it. (If you have
philosophical objections to Atom you can use 'rss_200'.)

B<cache_expire> (optional but strongly recommended)

Same as L<OpenInteract2::Action::RSS>

B<num_photos> (optional; default 0, which means display all)

Number of photos to display; by default we show all of them. You can
also control this from your template if you wish.

=head1 SEE ALSO

L<OpenInteract2::Action::RSS>

L<XML::Feed>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Chris Winters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters, E<lt>chris@cwinters.comE<gt>

=cut
