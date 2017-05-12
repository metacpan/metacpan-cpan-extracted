package SoggyOnion::Plugin::RSS;
use warnings;
use strict;
use base qw( SoggyOnion::Plugin );

our $VERSION = '0.04';

use Template;
use constant TEMPLATE_FILE => 'rss.tt2';

use LWP::Simple qw(get head $ua);
use constant MOD_TIME => 2;

use XML::RSS;
use HTML::Strip;

our $DEFAULT_MAXLEN;

sub init {

    # set our useragent to be nice
    $ua->agent( SoggyOnion->useragent );

    # set default maximum length using global option
    $DEFAULT_MAXLEN = SoggyOnion->options->{maxlen}
        if not defined $DEFAULT_MAXLEN
        && not defined SoggyOnion->options->{maxlen};
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

    # get the feed
    my ( $rss, $xml );
    eval {
        $xml = get( $self->{rss} );
        $rss = XML::RSS->new;
        $rss->parse($xml);
    };
    die $@ if $@;

    # honor maxlen
    my $maxlen =
          defined $DEFAULT_MAXLEN ? $DEFAULT_MAXLEN
        : defined $self->{maxlen} ? $self->{maxlen}
        : 0;

    # honor limit option
    @{ $rss->{items} } = splice( @{ $rss->{items} }, 0, $self->{limit} )
        if $self->{limit};

    # honor strip-html option (after limiting items)
    my $allow_html
        = ( exists $self->{html} && $self->{html} =~ /^(0$|n)/i ) ? 0 : 1;

   # create stripped html, should do entities conversion so that we don't have
   # any quotes or brackets in the title
    my $hs = HTML::Strip->new;
    map {

        # create HTML-less version of descriptions
        $_->{stripped_description} = $hs->parse( $_->{description} );

        # shorten it if asked to
        $_->{stripped_description}
            = substr( $_->{stripped_description}, 0, $maxlen )
            if $maxlen;

    } @{ $rss->{items} } unless $allow_html;

    # honor show-description option
    my $show_descriptions = ( exists $self->{descriptions}
            && $self->{descriptions} =~ /^(0$|n)/i ) ? 0 : 1;

    # trim description if needed
    map {
        $_->{description} = substr( $_->{description}, 0, $maxlen );

    } @{ $rss->{items} } if $maxlen;

    # honor icon
    if ( defined $self->{icon} ) {
        $rss->{image}{url}  = $self->{icon};
        $rss->{image}{link} = $rss->{channel}{link}
            unless $rss->{image}{link};
    }

    # run it through our template
    my $tt
        = Template->new( INCLUDE_PATH => SoggyOnion->options->{templatedir} )
        or die "couldn't create Template object\n";
    my $output;
    $tt->process(
        TEMPLATE_FILE,
        {   %$rss,
            allow_html        => $allow_html,
            show_descriptions => $show_descriptions,
        },
        \$output
        )
        or die $tt->error;
    return $output;
}

1;

__END__

=head1 NAME

SoggyOnion::Plugin::RSS - get feeds using XML::RSS

=head1 SYNOPSIS

In F<config.yaml>:

    options:
      maxlen: 100

    layout:
      - title: Stuff
        name:  stuff.html
        items:
          - rss: http://search.cpan.org/recent.rdf
            id:     cpan
            limit:  10
            description: no
            html:   no
            maxlen: 150
            icon:   http://cpan.org/images/icon.png

=head1 DESCRIPTION

This is a plugin for L<SoggyOnion> that gets RSS feeds.

=head2 Item Options

=over 4

=item * C<rss> - the URI of the feed

=item * C<id> - the item ID that appears in the HTML C<E<lt>DIVE<gt>> tag

=item * C<limit> - (optional) maximum items to show, default is
unlimited

=item * C<description> - (optional) whether to show the description
(yes/no), default is yes

=item * C<maxlen> - (optional) what length to trim the description
returned by the feeds. Default is 0, which lets the description be of infinite length.Note: if you change this, you might clip 

=item * C<html> - (optional) if set to "no" will strip html from the description using L<HTML::Strip>

=item * C<icon> - (optional) URI of an image to use as the channel icon

=back

=head2 Global Options

=over 4

=item * C<maxlen> - (optional) same as the item option, but sets the default maximun length for all items unless you specify it per-item.

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
