package OpenInteract2::Action::RSS;

# $Id: RSS.pm,v 1.2 2004/12/02 04:31:30 cwinters Exp $

use strict;
use base qw( OpenInteract2::Action );
use Digest::MD5              qw( md5_hex );
use File::Spec::Functions    qw( catfile );
use Log::Log4perl            qw( get_logger );
use OpenInteract2::Constants qw( :log );
use OpenInteract2::Context   qw( CTX );
use OpenInteract2::Exception qw( oi_error );
use URI;
use XML::Feed;

$OpenInteract2::Action::RSS::VERSION          = '0.10';

# Use this if the action does not define its own template
$OpenInteract2::Action::RSS::DEFAULT_TEMPLATE = 'rss_feed_default';

# Use this if the action does not define its own title or title_key
$OpenInteract2::Action::RSS::DEFAULT_TITLE    = 'Feed';

my ( $log );

# always run the 'process' task

sub _find_task {
    return 'process';
}

# NOTE: we don't need to bother with caching the output content here
# -- execute() in the parent class takes care of it for us

sub process {
    my ( $self ) = @_;
    $log ||= get_logger( LOG_ACTION );

    my ( $url, $template, $feed );
    eval {
        $url = $self->_get_feed_url();
        $log->is_debug &&
            $log->debug( "Will load from feed URL '$url'" );
        $feed = $self->_load_feed( $url );
        $template = $self->_get_template_name();
        $log->is_debug &&
            $log->debug( "Will send feed and data to template '$template'" );
    };
    return "$@"  if ( $@ );
    $log->is_info && $log->info( "Got all necessary data, processing feed..." );
    my $title = $self->_get_title( $feed ) || $feed->title;
    my %params = (
        feed  => $feed,
        title => $title,
    );
    $self->_modify_template_params( \%params );
    return $self->generate_content( \%params, { name => $template } );
}


sub _get_feed_url {
    my ( $self ) = @_;
    my $class = ref( $self );
    my $url = $self->param( 'feed_url' );
    unless ( $url ) {
        $log->error( "No 'feed_url' defined for action ", $self->name );
        die "Cannot get feed: parameter 'feed_url' must be defined " .
            "for action '", $self->name, "'. (See $class for details).\n";
    }
    return $url;
}


sub _load_feed {
    my ( $self, $url ) = @_;
    my ( $feed );
    if ( $url =~ m|^file://| ) {
        my $file = $url;
        $file =~ s|^file://||;
        $log->is_info && $log->info( "Loading feed from file '$file'" );
        $feed = XML::Feed->parse( $file );
    }
    else {
        $log->is_info && $log->info( "Loading feed from URL '$url'" );
        $feed = XML::Feed->parse( URI->new( $url ) )
    }
    unless ( $feed ) {
        my $error = XML::Feed->errstr();
        $log->error( "Failed to load feed: ",  );
        die "Failed to load feed from '$url': $error\n";
    }
    return $feed;
}


sub _get_template_name {
    my ( $self ) = @_;
    my $template = $self->param( 'template' );
    if ( $template ) {
        $log->is_debug &&
            $log->debug( "Found template '$template' in action params" );
    }
    else {
        $log->is_debug &&
            $log->debug( "No RSS template configured, using default" );
        $template = $OpenInteract2::Action::RSS::DEFAULT_TEMPLATE;
        my $full_template_path =
            catfile( CTX->lookup_directory( 'template' ), $template );
        unless ( -f $full_template_path ) {
            $log->is_debug &&
                $log->debug( "Default template file does not exist, ",
                             "writing for the first time" );
            open( DEFAULT, '>', $full_template_path )
                || oi_error "Cannot create default RSS template at ",
                            "'$full_template_path': $!";
            print DEFAULT _get_default_template_content();
            close( DEFAULT );
            $log->is_debug &&
                $log->debug( "Wrote default RSS template ok" );
        }
    }
    return $template;
}


sub _get_default_template_content {
    return <<'CONTENT';
[%- rss_display_cap = OI.action_param( 'num_display' ) || feed.entries.size;
    count = 0; -%]
<h3>[% title %]</h3>
[% FOREACH entry = feed.entries;
       IF count < rss_display_cap; -%]
 - [% OI.date_format( entry.issued, '%b %d, %r' ) %]:
   <a href="[% entry.link %]">[% entry.title %]</a><br />
[%     END;
       count = count + 1;
   END -%]
CONTENT
}

sub _get_title {
    my ( $self, $feed ) = @_;
    my $title = $self->param( 'title' );
    unless ( $title ) {
        my $title_key = $self->param( 'title_key' );
        if ( $title_key ) {
            $title = CTX->request->language_handle->maketext( $title_key );
        }
    }
    return $title;
}

# For overriding...
sub _modify_template_params {}

1;

__END__

=head1 NAME

OpenInteract2::Action::RSS - OpenInteract2 action type for displaying RSS feeds

=head1 SYNOPSIS

 # Define the action type in your server configuration
 
 # In '$WEBSITE/conf/server.ini' (do this once per site)
 
 [action_types]
 ...
 rss = OpenInteract2::Action::RSS
 
 # Define the action that will use a RSS feed
 
 # In your package's 'conf/action.ini'
 
 [myaction]
 action_type  = rss
 feed_url     = http://somesite/rss.xml
 title        = My Feed
 template     = mypackage::myfeed
 cache_expire = 180m
 
 # Another example of an action:
 # Pull from a local file, grab the 'title' from the feed, use the
 # default template, and don't do any caching (NOT RECOMMENDED)
 
 [myaction]
 action_type = rss
 feed_url    = file:///home/httpd/mysite/html/feeds/rss.xml
 
 # Sample Template Toolkit Template displaying the feed
 
 <h3>[% title %]</h3>
 [% FOREACH entry = feed.entries -%]
 - [% OI.date_format( entry.issued, '%b %d, %r' ) %]:
     <a href="[% entry.link %]">[% entry.title %]</a><br />
 [% END -%]

=head1 DESCRIPTION

This module defines an OpenInteract2 action type. An action type is a
class that can generally be instantiated through configuration only --
in this case we can define a component that fetches and displays an
RSS feed without writing any code. (See L<OpenInteract2::Action> for
details on action types.)

Executing the action will ask L<XML::Feed> to retrieve the RSS/Atom
feed for us and parse it into an object. That object is passed to your
template as 'feed' and you can then iterate over the items in the feed
(with the C<entries()> method). See the L<XML::Feed> docs for more.

Note that the 'cache_expire' property (STRONGLY recommended) applies
to the generated content.

=head2 Usage method: fetch feed separately

It doesn't seem that we can give L<XML::Feed> a timeout value, so you
may find it a good idea to decouple fetching the feed from parsing the
feed:

=over 4

=item *

Assume we start with the following action (which specifies a box):

 [delicious_links]
 action_type  = rss
 feed_url     = http://del.icio.us/rss/cwinters/
 title        = Recent Links
 cache_expire = 180m
 template     = my_custom::delicious
 url_none     = yes
 weight       = 2
 num_display  = 8

=item *

Using C<cron> to fetch the RSS/Atom feed using C<wget>; the following
quietly retrieves the feed every 30 minutes:

 $ crontab -l
 
 # DO NOT EDIT THIS FILE - edit the master and reinstall.
 # (/tmp/crontab.XXXXQmyjPY installed on Wed Dec  8 08:46:34 2004)
 # (Cron version V5.0 -- $Id: crontab.c,v 1.12 2004/01/23 18:56:42 vixie Exp $)
 */30 * * * * /usr/bin/wget -q -O /tmp/delicious-cwinters.xml http://del.icio.us/rss/cwinters

Adjust the time to whatever's appropriate for your feed source.

=item *

Modify your action to reference the file:

 [delicious_links]
 action_type = rss
 feed_url    = file:///tmp/delicious-cwinters.xml
 ...

=item *

Restart the server; you're good to go.

=back

=head1 OBJECT METHODS

B<process()>

Retrieve the feed from the given location, parse it and send it to a
template. The parameters you can use to control this are:

=over 4

=item B<feed_url> (required)

URL from which we fetch the RSS/Atom. If you are fetching the feed
using other means and want to retrieve it locally you can use a
'file://' URL as well.

=item B<template> (optional)

Template to which we send feed data to generate the content. If you do
not specify we use a default (listed below).

=item B<title> (optional)

Title to use for feed in template. If you do not specify this or
'title_key' we pull the title from the feed.

=item B<title_key> (optional)

Message key to use for the title. (See L<OpenInteract2::I18N>.)

=item B<num_display> (optional)

Number of entries to display. Defaults to displaying all.

=back

=head2 Default template

Here is the default TT template we use:

 [%- rss_display_cap = OI.action_param( 'num_display' ) || feed.entries.size;
     count = 0; -%]
 <h3>[% title %]</h3>
 [% FOREACH entry = feed.entries;
        IF count < rss_display_cap; -%]
  - [% OI.date_format( entry.issued, '%b %d, %r' ) %]:
    <a href="[% entry.link %]">[% entry.title %]</a><br />
 [%     END;
        count = count + 1;
    END -%]

To use your own specify a 'template' parameter in the action. This
template name should be in the normal 'package::template' format.

=head1 SUBCLASSING

If you want to modify how this action does some of its job you can
subclass it and override some parts of C<process()>. Here are the
hooks available to you:

B<_get_feed_url()>

Should return the URL for this feed. By default we use the value of
the action parameter 'feed_url'.

If you cannot determine a feed URL you should C<die> with an
appropriate message.

B<_get_template_name()>

Should return the fully-qualified name of a template. The default
implementation looks in the 'template' parameter and if that's empty
will use a default template.

If you cannot return a template name you should C<die> with an
appropriate message.

B<_get_title()>

Return the feed title; if none returned we use the title from the
L<XML::Feed> object.

B<_modify_template_params( \%params )>

Gives you a chance to modify the parameters passed to the
template. The hashref C<\%params> will contain the keys 'feed' (with
an L<XML::Feed> object) and 'title' (with the feed title). You can add
new parameters, modify the feed or title, whatever you want.

B<_load_feed( $url )>

Should return an L<XML::Feed> object. Note that the implementation in
this class takes care of 'file://' URL references as well as caching,
so you might not want to override.

If you cannot return an L<XML::Feed> object you should C<die> with an
appropriate message.

=head1 SEE ALSO

L<XML::Feed>

=head1 COPYRIGHT

Copyright (c) 2004-5 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

