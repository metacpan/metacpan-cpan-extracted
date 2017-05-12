package SoggyOnion::Plugin::ImageScraper;
use warnings;
use strict;
use base qw( SoggyOnion::Plugin );

our $VERSION = '0.04';

use Template;
use constant TEMPLATE_FILE => 'imagescraper.tt2';

use LWP::Simple qw(get head $ua);
use constant MOD_TIME => 2;

use HTML::TokeParser;
use constant { TYPE => 0, TAG => 1, ATTR => 2 };

# set our useragent to be nice
sub init {
    $ua->agent( SoggyOnion->useragent );
}

# try getting the modification time of the RSS feed from the web server.
# if we can't, just return the current time to make sure the feed is
# processed.
sub mod_time {
    my $self  = shift;
    my $mtime = [ head( $self->{rss} ) ]->[MOD_TIME];
    return $mtime || time;    # in case no modification time is available
}

sub content {
    my $self = shift;

    # error checking for required options
    die "'images' attribute is required\n"
        unless ( exists $self->{images} );

    # setup defaults for other options
    $self->{offset} ||= 0;
    $self->{limit}  ||= 1;

    # get the URL
    my $document = get( $self->{images} );
    die "couldn't get document" unless defined $document;

    # cheap way of getting title! FIXME
    # URI::Title doesn't do much more anyway
    $document =~ m#<title>(.+?)</title>#si;
    my $title = $1;

    # process links
    my $parser = HTML::TokeParser->new( \$document ) or die $!;
    my $i      = 0;
    my @links  = ();
    while ( my $token = $parser->get_token ) {
        next unless ref $token eq 'ARRAY';
        next unless $token->[TYPE] eq 'S' && $token->[TAG] eq 'img';
        next unless $i++ >= $self->{offset};
        push @links, $token->[ATTR]->{src};
        last if @links >= $self->{limit};
    }

    # did we specify a prefix in the config? if so, prefix all links
    if ( exists $self->{prefix} ) {
        @links = map { $self->{prefix} . $_ } @links;
    }

    # no prefix in the conf? go through and make sure that all our links are
    # absolute. if they're relative, prepend the source URL
    else {

        # determine protocol -- use if double-slash shorthand is used
        $self->{images} =~ m/^(\w+):/;
        my $protocol = $1;

        # strip connecting slash
        $self->{images} =~ s#/+$##;

        for (@links) {

            # valid but uncommon URI shorthand
            $_ = "$protocol\:$_" if m#^//[^/]#;

            # strip connecting slashes
            s#^/+##;

            # prepend relative URIs with our source URI
            $_ = $self->{images} . '/' . $_
                unless m/^\w+:\/\//;
        }
    }

    # run it through our template
    my $tt
        = Template->new( INCLUDE_PATH => SoggyOnion->options->{templatedir} )
        or die "couldn't create Template object\n";
    my $output;
    $tt->process( TEMPLATE_FILE,
        { links => \@links, src => $self->{images}, title => $title },
        \$output )
        or die $tt->error;
    return $output;
}

1;

__END__

=head1 NAME

SoggyOnion::Plugin::ImageScraper - get images from a page

=head1 SYNOPSIS

In F<config.yaml>:

    layout:
      - title: Comic Strips
        name:  comics.html
        items:
          - images: http://www.myfavoritestrip.com/
            id:  myfavoritestrip
            offset: 4
            limit: 1

=head1 DESCRIPTION

This is a plugin for L<SoggyOnion> that grabs a series of E<lt>IMGE<gt> tags from a URI and adds them to the SoggyOnion output page.

=head2 Item Options

=over 4

=item * C<images> - the URI of the page to scrape the image(s) from

=item * C<id> - the item ID that appears in the HTML C<E<lt>DIVE<gt>> tag

=item * C<offset> - (optional) the index of the first image, default is 0 (first image)

=item * C<limit> - (optional) how many images to show past the C<offset>, default is 1

=item * C<prefix> - (optional) prefix the output URI of the image with this. By default, checks the C<IMG SRC>. If it's relative it prepends the C<prefix> if you set it or the URI specified with C<images>.

=back

=head1 SEE ALSO

L<SoggyOnion>

=head1 AUTHOR

Ian Langworth, C<< <ian@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
