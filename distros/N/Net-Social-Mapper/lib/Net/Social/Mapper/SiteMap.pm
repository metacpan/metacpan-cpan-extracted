package Net::Social::Mapper::SiteMap;

use strict;
use JSON::Any;

=head1 NAME

Net::Social::Mapper::SiteMap - information about know services around the internet

=head1 SYNOPSIS

    my $sitemap = Net::Social::Mapper::SiteMap;
    my $info    = $sitemap->profile($user, $service);
    my ($user, $service) = $sitemap->url_to_service($url);
    

=head1 DESCRIPTION

This is designed to be overriden and replaced with a more scalable
database if necessary. 

Alternatively the information could come from Google's C<sgnodemapper> 

    http://code.google.com/p/google-sgnodemapper/

=head1 METHODS

=head2 new 

Instantiate a new sitemap.

=cut
sub new {
    my $class = shift;
    my %opts  = @_;
    my $self  = bless \%opts, $class;
    $self->_init;
    return $self;
}

sub _init { }


sub _get_sitemap {
    my $self = shift;
    return $self->{_sitemap} if $self->{_sitemap};
    my $fh    = *DATA;
    my $off   = tell($fh);
    my $json = JSON::Any->new;
    my $data = do { local $/; <$fh> };
    seek($fh, $off, 0);
    return $self->{_sitemap} ||= $json->decode($data);
}

=head2 profile <service> [user]

Returns a hash ref with all the known information about C<service>.

If C<user> is passed in then any urls will be updated to include that information;

Returns undef if the service isn't known.

=cut
sub profile {
    my $self     = shift;
    my $service  = shift || return;
    my $user     = shift;
    my $site     = $self->_get_sitemap;
    my $val      = $service;
    do {
        $val     = $site->{$val};
        return unless defined $val && $val !~ m!^\s*$!;
        $service = $val unless ref($val) ne "";
    } until (ref($val) ne "");
    $val = $self->_visit($val, $user) if defined $user;
    $val->{service} = $service;
    return $val;
}

sub _visit {
    my $self    = shift;
    my $struct  = shift;
    my $user    = shift;
    my $ref     = ref($struct);

    if (!defined $ref || $ref eq "") {
        $struct =~ s!%user!$user!msg;
    } elsif ($ref eq 'SCALAR') {
        $$struct = $self->_visit($$struct, $user);
    } elsif ($ref eq 'HASH') {
        foreach my $key (keys %$struct) {
            $struct->{$key} = $self->_visit($struct->{$key}, $user);
        }
    } elsif ($ref eq 'ARRAY') {
        $struct =  [ map { $self->_visit($_, $user) } @$struct ];
    }
    return $struct;
}

=head2 url_to_service <url>

Take a url and work out what username and service it is

=cut
sub url_to_service {
    my $self    = shift;
    my $url     = shift;
    $url        = "http://$url" unless $url =~ m![a-z]+:\/\/!i;

    my $sitemap = $self->_get_sitemap;

    foreach my $service (keys %$sitemap) {
        next unless ref($sitemap->{$service});
        my $regex   = $sitemap->{$service}->{regex} || next;
        my @regexes = (ref($regex)) ? @$regex : ($regex);
        foreach my $test (@regexes) { 
            $test =~ s!\?!\\?!g;
            next unless $url =~ m!$test!;
            next unless defined $1;
            return ($1, $service);
        }
    }

    # The default
    return ($url, 'website');
}

###
# Needed
##

# Catser
# ColourLovers
# Corkd
# Dogster
# Gametap
# Goodreads
# Google
# Hi5
# Iconbuffet
# Icq
# Iminta
# IStockPhoto
# IUseThis
# IWatchThis
# Mog
# Multiply
# Netflix
# NetVibes
# NewsVine
# Ning
# Ohloh
# Opera
# p0pulist
# Skype
# Sonicliving
# Spin.de
# Stumbleupon
# Tabblo
# Technorati
# Threadless
# Uncrate
# Viddler
# Virb
# Wakoopa
# Wists
1;
__DATA__
{
    "43things":    {
        "name"     : "43 Things",
        "domain"   : "43things.com",
        "homepage" : "http://www.43things.com/person/%user/",
        "profile"  : "http://www.43things.com/person/%user/",
        "feeds"    : [ "http://www.43things.com/rss/uber/author?username=%user" ],
        "regex"    : [ "43things.com/rss/uber/author?username=([^&]+)", "43things.com/person/([^/]+)" ]
    },
    "advogato":    {
        "name"     : "Advogato",
        "domain"   : "advogato.org",
        "homepage" : "http://advogato.org/person/%user/",
        "profile"  : "http://advogato.org/person/%user/",
        "foaf"     : "http://advogato.org/person/%user/foaf.rdf",
        "regex"    : [ "advogato.org/person/([^/]+)" ]
    },
    "aim":         {
        "name"     : "AIM",
        "domain"   : "profiles.aim.com",
        "homepage" : "http://profiles.aim.com/%user/",
        "profile"  : "http://profiles.aim.com/%user/",
        "photo"    : "http://www.aimpages.com/%user/.aim/aimface.200.jpg",
        "regex"    : [ "profiles.aim.com/([^/]+)", "aimpages.comom/([^/]+)" ]
    },
    "amazon":      {
        "name"     : "Amazon",
        "domain"   : "amazon.com",
        "homepage" : "http://www.amazon.com/gp/pdp/profile/%user",
        "profile"  : "http://www.amazon.com/gp/pdp/profile/%user",
        "feeds"    : [ ],
        "regex"    : [ "amazon.com/gp/pdp/profile/([^/]+)" ]
    },
    "bebo":        {
        "name"     : "Bebo",
        "domain"   : "bebo.com",
        "homepage" : "http://bebo.com/%user",
        "profile"  : "http://bebo.com/%user",
        "regex"    : [ "bebo.com/api/.*?MemberId=([0-9]+)", "bebo.com/([^/]+)" ]
    },
    "blogger":     {
        "name"     : "Blogger",
        "domain"   : "blogger.com",
        "homepage" : "http://blogger.com/profile/%user",
        "profile"  : "http://blogger.com/profile/%user",
        "regex"    : [ "blogger.com/profile/([^/]+)" ]
    },
    "blogspot":    {
        "name"     : "Blogspot",
        "domain"   : "blogspot.com",
        "favicon"  : "http://blogger.com/favicon.ico",
        "homepage" : "http://%user.blogspot.com",
        "profile"  : "http://%user.blogspot.com",
        "feeds"    : [ "http://%user.blogspot.com/feeds/posts/default", "http://%user.blogspot.com/feeds/posts/default?alt=rss" ],
        "regex"    : [ "http://([^.]+).blogspot.com" ]
    },
    "delicious": "del.icio.us",
    "del.icio.us": {
        "name"     : "del.icio.us",
        "domain"   : "delicious.com",
        "verbs"    : [ "favorite" ],
        "homepage" : "http://delicious.com/%user",
        "profile"  : "http://delicious.com/%user",
        "feeds"    : [ "http://feeds.delicious.com/v2/atom/%user", "http://feeds.delicious.com/v2/rss/%user" ],
        "regex"    : [ "feeds.delicious.com/v2/[^/]+/([^/]+)", "feeds.del.icio.us/v2/[^/]+/([^/]+)", "delicious.com/([^/]+)", "del.icio.us/([^/]+)" ]
    },
    "digg":        {
        "name"     : "Digg",
        "domain"   : "digg.com",
        "verbs"    : [ "favorite" ],
        "types"    : [ "favorites" ],
        "homepage" : "http://digg.com/users/%user/",
        "profile"  : "http://digg.com/users/%user/",
        "feeds"    : [ "http://digg.com/users/%user/history/diggs.rss" ],
        "regex"    : [ "digg.com/users/([^/]+)" ]
    },
    "disqus":      {
        "name"     : "Disqus",
        "domain"   : "disqus.com",
        "types"    : [ "comments" ],
        "favicon"  : "http://media.disqus.com/images/dsq-favicon-16x16.ico",
        "homepage" : "http://disqus.com/people/%user/",
        "profile"  : "http://disqus.com/people/%user/",
        "feeds"    : [ "http://disqus.com/people/%user/comments.rss" ],
        "regex"    : [ "disqus.com/people/([^/]+)" ]
    },
    "dodgeball":   {
        "name"     : "Dodgeball",
        "domain"   : "dodgeball.com",
        "favicon"  : "http://dodgeball.com/static/4021100690-favicon.ico",
        "types"    : [ "trips" ],
        "homepage" : "http://www.dodgeball.com/user?uid=%user",
        "profile"  : "http://www.dodgeball.com/user?uid=%user",
        "feeds"    : [ ],
        "regex"    : [ "dodgeball.com/user?uid=(\\d+)" ]
    },
    "dopplr":      {
        "name"     : "Dopplr",
        "domain"   : "dopplr.com",
        "types"    : [ "trips" ],
        "favicon"  : "http://dopplr.com/favicon.png",
        "homepage" : "http://dopplr.com/traveller/%user",
        "profile"  : "http://dopplr.com/traveller/%user",
        "regex"    : [ "dopplr.com/traveller/([^/]+)" ]
    },
    "evernote":    {
        "name"     : "EverNote",
        "domain"   : "evernote.com",
        "homepage" : "http://evernote.com/pub/%user/broadcast",
        "profile"  : "http://evernote.com/pub/%user/broadcast",
        "regex"    : [ "evernote.com/pub/([^/]+)" ]
    },
    "facebook":    {
        "name"     : "Facebook",
        "domain"   : "facebook.com",
        "homepage" : "http://www.facebook.com/people/%user",
        "profile"  : "http://www.facebook.com/people/%user",
        "regex"    : [ "http://www.facebook.com/people/([^/]+/[0-9]+)" ]
    },
    "ffound":     "ffffound",
    "fffound":    "ffffound",
    "ffffound":    {
        "name"     : "Ffffound",
        "domain"   : "ffffound.com",
        "types"    : [ "photos" ],
        "homepage" : "http://ffffound.com/home/%user/",
        "profile"  : "http://ffffound.com/home/%user/",
        "feeds"    : [ "http://ffffound.com/home/%user/post/feed" ],
        "regex"    : [ "ffffound.com/home/([^/]+)" ]        
    },
    "flickr":      {
        "name"     : "Flickr",
        "domain"   : "flickr.com",
        "types"    : ["photos"],
        "homepage" : "http://www.flickr.com/photos/%user/",
        "profile"  : "http://www.flickr.com/people/%user/",
        "regex"    : [ "api.flickr.com/services/feeds/photos_public.gne?id=([^&]+)", "flickr.com/[^/]+/([^/]+)"]        
    },
    "fortythreethings": "43things",
    "friendfeed":  {
        "name"     : "FriendFeed",
        "domain"   : "friendfeed.com",
        "homepage" : "http://friendfeed.com/%user",
        "profile"  : "http://friendfeed.com/%user",
        "feeds"    : [ "http://friendfeed.com/%user?format=atom" ],
        "regex"    : [ "friendfeed.com/([^/]+)"]            
    },
    "getsatisfaction": {
        "name"     : "Get Satisfaction",
        "domain"   : "getsatisfaction.com",
        "favicon"  : "http://getsatisfaction.com/favicon.gif",
        "homepage" : "http://getsatisfaction.com/people/%user",
        "profile"  : "http://getsatisfaction.com/people/%user",
        "feeds"    : [ "http://getsatisfaction.com/people/%user.rss" ],
        "regex"    : [ "getsatisfaction.com/people/([^/.]+)" ]
    },
    "gravatar":    {
        "name"     : "Gravatar",
        "domain"   : "gravatar.com",
        "favicon"  : "http://www.gravatar.com/avatar/%user.jpg?s=16",
        "homepage" : "http://www.gravatar.com/avatar/%user",
        "profile"  : "http://www.gravatar.com/avatar/%user",
        "regex"    : [ "gravatar.com/avatar/([A-Fa-f0-9]+)" ]
    },
    "google":      {
        "name"     : "Google",
        "domain"   : "google.com",
        "homepage" : "http://www.google.com/s2/profiles/%user",
        "profile"  : "http://www.google.com/s2/profiles/%user",
        "feeds"    : [ ],
        "regex"    : [ "google.com/s2/profiles/([^/]+)" ]
    },
    "googlereader":{
        "name"     : "Google Reader",
        "domain"   : "google.com",
        "homepage" : "http://google.com/reader/shared/%user",
        "profile"  : "http://google.com/reader/shared/%user",
        "feeds"    : [ "http://google.com/reader/public/atom/user/%user/state/com.google/broadcast" ],
        "regex"    : [ "google.com/reader/shared/([^/]+)", "google.com/reader/public/atom/user/([^/]+)" ]            
    },
    "identica": "identi.ca",
    "identi.ca":   {
        "name"     : "identi.ca",
        "domain"   : "identi.ca",
        "types"    : [ "notes" ],
        "homepage" : "http://identi.ca/%user",
        "profile"  : "http://identi.ca/%user",
        "foaf"     : "http://identi.ca/%user/foaf",
        "feeds"    : [ "http://identi.ca/api/statuses/user_timeline/%user.atom", "http://identi.ca/api/statuses/user_timeline/%user.rss" ],
        "regex"    : [ "identi.ca/api/statuses/user_timeline/([^.]+)", "identi.ca/([^/]+)" ]
    },
    "jaiku":       {
        "name"     : "Jaiku",
        "domain"   : "jaiku.com",
        "homepage" : "http://%user.jaiku.com",
        "profile"  : "http://%user.jaiku.com",
        "foaf"     : "http://%user.livejournal.com/data/foaf",
        "feeds"    : [ "http://%user.jaiku.com/feed/atom", "http://%user.jaiku.com/feed/rss"],
        "regex"    : [ "http://([^.]+).jaiku.com" ]
    },
    "kongregate":  {
        "name"     : "Kongregate",
        "domain"   : "kongregate.com",
        "homepage" : "http://kongregate.com/accounts/%user",
        "profile"  : "http://kongregate.com/accounts/%user",
        "feeds"    : [ "http://kongregate.com/accounts/%user/badges.rss"],
        "regex"    : [ "kongregate.com/accounts/([^/]+)" ]
    },
    "lastfm": "last.fm",
    "last.fm":      {
        "name"     : "Last.fm",
        "domain"   : "last.fm",
        "homepage" : "http://www.last.fm/user/%user",
        "profile"  : "http://www.last.fm/user/%user",
        "feeds"    : [ "http://ws.audioscrobbler.com/1.0/user/%user/recentactivity.rss" ],
        "regex"    : [ "last.fm/user/([^/]+)", "audioscrobbler.com/.*/user/([^/]+)" ]
    },
    "linkedin":    {
        "name"     : "LinkedIn",
        "domain"   : "linkedin.com",
        "favicon"  : "http://www.linkedin.com/favicon.ico",
        "homepage" : "http://linkedin.com/in/%user",
        "profile"  : "http://linkedin.com/in/%user",
        "regex"    : [ "linkedin.com/in/([^/]+)" ]
    },
    "livejournal": {
        "name"     : "LiveJournal",
        "domain"   : "livejournal.com",
        "homepage" : "http://%user.livejournal.com",
        "profile"  : "http://%user.livejournal.com/profile",
        "foaf"     : "http://%user.livejournal.com/data/foaf",
        "feeds"    : [ "http://%user.livejournal.com/data/atom", "http://%user.livejournal.com/data/rss"],
        "regex"    : [ "livejournal.com/userinfo.bml?user=([^&]+)", "^http://([^.]+).livejournal.com" ]
    },
    "ma.gnolia":   {
        "name"     : "ma.gnolia",
        "domain"   : "ma.gnolia.com",
        "homepage" : "http://ma.gnolia.com/people/%user",
        "profile"  : "http://ma.gnolia.com/people/%user",
        "feeds"    : [ "http://ma.gnolia.com/atom/full/people/%user", "http://ma.gnolia.com/rss/full/people/%user" ],
        "regex"    : [ "ma.gnolia.com.*/people/([^/]+)" ]
    },
    "magnolia"     : "ma.gnolia",
    "meetup":      {
        "name"     : "Meetup",
        "domain"   : "meetup.com",
        "types"    : [ "events" ],
        "homepage" : "http://www.meetup.com/members/%user",
        "profile"  : "http://www.meetup.com/members/%user",
        "regex"    : [ "meetup.com/members/([^/]+)" ]
    },
    "mybloglog":   {
        "name"     : "MyBlogLog",
        "domain"   : "mybloglog.com",
        "favicon"  : "http://www.mybloglog/favicon.ico",
        "homepage" : "http://www.mybloglog.com/buzz/members/%user",
        "profile"  : "http://www.mybloglog.com/buzz/members/%user/hcard",
        "foaf"     : "http://www.mybloglog.com/buzz/members/%user/foaf",
        "feeds"    : [ "http://www.mybloglog.com/buzz/members/%user/me/rss.xml" ],
        "regex"    : [ "mybloglog.com/buzz/members/([^/]+)" ]
    },
    "myspace":     {
        "name"     : "MySpace",
        "domain"   : "myspace.com",
        "homepage" : "http://myspace.com/%user",  
        "profile"  : "http://myspace.com/%user",
        "regex"    : [ "blogs.myspace.com/.*friendID=([0-9]+)", "myspace.com/([^/]+)" ]
    },
    "multiply":    {
        "name"     : "Multiply",
        "domain"   : "multiply.com",
        "homepage" : "http://%user.multiply.com",
        "profile"  : "http://%user.multiply.com",
        "feeds"    : [ "http://%user.multiply.com/feed.rss" ],
        "regex"    : [ "http://([^.]+).multiply.com" ]
    },
    "orkut":       {
        "name"     : "Orkut",
        "domain"   : "orkut.com",
        "homepage" : "http://www.orkut.com/Main#Profile.aspx?uid=%user",
        "profile"  : "http://www.orkut.com/Main#Profile.aspx?uid=%user",
        "feeds"    : [ ],
        "regex"    : [ "orkut.com/Profile.aspx?uid=(\\d+)", "orkut.com/Main#Profile.aspx?uid=(\\d+)" ]
    },
    "pandora":     {
        "name"     : "Pandora",
        "domain"   : "pandora.com",
        "types"    : [ "audio" ],
        "homepage" : "http://pandora.com/people/%user",
        "profile"  : "http://pandora/people/%user",
        "feeds"    : [ "http://feeds.pandora.com/feeds/people/%user/favorites.xml" ],
        "regex"    : [ "feeds.pandora.com/feeds/people/([^/]+)", "pandora.com/people/([^/]+)" ]
    },
    "picasaweb": "picasa",
    "picasa":      {
        "name"     : "Picasa",
        "domain"   : "picasaweb.com",
        "types"    : [ "photos" ],
        "homepage" : "http://picasaweb.google.com/%user",
        "profile"  : "http://picasaweb.google.com/%user",
        "feeds"    : [ "http://picasaweb.google.com/data/feed/base/user/%user?alt=atom&kind=album&hl=en_US&access=public", "http://picasaweb.google.com/data/feed/base/user/%user?alt=rss&kind=album&hl=en_US&access=public" ],
        "regex"    : [ "picasaweb.google.com/data/feed/base/user/([^?]+)", "picasaweb.google.com/([^/]+)" ]
    },
    "plinky":      {
        "name"     : "Plinky",
        "domain"   : "plinky.com",
        "homepage" : "http://www.plinky.com/people/%user",
        "profile"  : "http://www.plinky.com/people/%user",
        "feeds"    : [ "http://www.plinky.com/people/%user.xml" ],
        "regex"    : [ "plinky.com/people/([^.]+)" ]
    },
    "posterous":   {
        "name"     : "Posterous",
        "domain"   : "posterous.com",
        "favicon"  : "http://posterous.com/images/favicon.png",
        "homepage" : "http://%user.posterous.com",
        "profile"  : "http://%user.posterous.com",
        "feeds"    : [ "http://%user.posterous.com/rss.xml" ],
        "regex"    : [ "posterous.com/(people/[^/]+)", "http://([^.]+).posterous.com/" ]
    },
    "pownce":      {
        "name"     : "Pownce",
        "domain"   : "pownce.com",
        "favicon"  : "http://pownce.com/img/favicon.ico",
        "homepage" : "http://pownce.com/%user",
        "profile"  : "http://pownce.com/%user",
        "foaf"     : "http://pownce.com/%user/foaf",
        "feeds"    : [ "http://pownce.com/feeds/public/%user.atom", "http://pownce.com/feeds/public/%user.rss" ],
        "regex"    : [ "pownce.com/feeds/public/([^.]+)", "pownce.com/([^/]+)" ]
    },
    "reddit":      {
        "name"     : "Reddit",
        "domain"   : "reddit.com",
        "homepage" : "http://reddit.com/user/%user",
        "profile"  : "http://reddit.com/user/%user",
        "feeds"    : [ "http://reddit.com/user/%user/.rss" ],
        "regex"    : [ "reddit.com/user/([^/]+)" ] 
    },
    "skitch":      {
        "name"     : "Skitch",
        "domain"   : "skitch.com",
        "homepage" : "http://skitch.com/%user",
        "profile"  : "http://skitch.com/%user",
        "feeds"    : [ "http://skitch.com/feeds/%user/atom.xml" ],
        "regex"    : [ "skitch.com/feeds/([^/]+)", "skitch.com/avatar/([^/]+)", "skitch.com/([^/]+)" ]
    },
    "slashdot":    {
        "name"     : "Slashdot",
        "domain"   : "slashdot.org",
        "homepage" : "http://slashdot.org/~%user",
        "profile"  : "http://slashdot.org/~%user",
        "feeds"    : [ "http://slashdot.org/~%user/journal/rss" ],
        "regex"    : [ "slashdot.org/~([^/]+)" ]
    },
    "slideshare":  {
        "name"     : "SlideShare",
        "domain"   : "slideshare.net",
        "homepage" : "http://slideshare.net/%user",
        "profile"  : "http://slideshare.net/%user",
        "photo"    : "http://cdn.slideshare.net/profile-photo-%user",
        "feeds"    : [ "http://slideshare.net/rss/user/%user" ],
        "regex"    : [ "slideshare.net/rss/user/([^/]+)", "slideshare.net/([^/]+)" ]
    },
    "smugmug":     {
        "name"     : "SmugMug",
        "domain"   : "smugmug.com",
        "homepage" : "http://%user.smugmug.com",
        "profile"  : "http://%user.smugmug.com",
        "feeds"    : [ "http://%user.smugmug.com/hack/feed.mg?Type=nicknameRecentPhotos&Data=%user&format=atom10", "http://%user.smugmug.com/hack/feed.mg?Type=nicknameRecentPhotos&Data=%user&format=rss200"  ],
        "regex"    : [ "smugmug.com/hack/feed.mg\\?.*Data=([^&]+)", "http://([^.]+).smugmug.com" ]
    },
    "steam":       {
        "name"     : "Steam",
        "domain"   : "steamcommunity.com",
        "homepage" : "http://steamcommunity.com/id/%user",
        "profile"  : "http://steamcommunity.com/id/%user",
        "feeds"    : [ "http://pipes.yahoo.com/pipes/pipe.run?_id=IH0KF8OZ3RGJPl7dBR50VA&_render=rss&steamid=%user"  ],
        "regex"    : [ "steamcommunity.com/id/([^/]+)" ]
    },
    "tribe":       {
        "name"     : "Tribe",
        "domain"   : "tribe.net",
        "homepage" : "http://people.tribe.net/%user",
        "profile"  : "http://people.tribe.net/%user",
        "regex"    : [ "people.tribe.net/([^/]+)" ]
    },
    "tumblr":      {
        "name"     : "Tumblr",
        "domain"   : "tumblr.com",
        "favicon"  : "http://tumblr.com/images/favicon.gif",
        "homepage" : "http://%user.tumblr.com",
        "profile"  : "http://%user.tumblr.com",
        "feeds"    : [ "http://%user.tumblr.com/rss" ],
        "regex"    : [ "http://([^.]+).tumblr.com" ]
    },
    "twitpic":     {
        "name"     : "TwitPic",
        "domain"   : "twitpic.com",
        "types"    : [ "photos" ],
        "homepage" : "http://twitpic.com/photos/%user",
        "profile"  : "http://twitpic.com/photos/%user",
        "feeds"    : [ "http://twitpic.com/photos/%user/feed.rss" ],
        "regex"    : [ "twitter.com/photos/([^/]+)" ]
    },

    "twitter":     {
        "name"     : "Twitter",
        "domain"   : "twitter.com",
        "types"    : [ "notes" ],
        "homepage" : "http://twitter.com/%user",
        "profile"  : "http://twitter.com/%user",
        "feeds"    : [ "http://twitter.com/statuses/user_timeline/%user.atom", "http://twitter.com/statuses/user_timeline/%user.rss" ],
        "regex"    : [ "twitter.com/statuses/user_timeline/([^.]+)", "twitter.com/([^/]+)" ]
    },
    "tpprofiles":       "typepad-profiles",
    "tp.profiles":      "typepad-profiles",
    "typepadprofiles":  "typepad-profiles",
    "typepad-profiles": "typepad-profiles",
    "typepad.profiles": "typepad-profiles",
    "tpprofile":        "typepad-profiles",
    "tp.profile":       "typepad-profiles",
    "typepadprofile":   "typepad-profiles",
    "typepad-profile":  "typepad-profiles",
    "typepad.profile":  "typepad-profiles",
    "tp-profile":       "typepad-profiles",
    "tp-profiles":      "typepad-profiles",
    "typepad-profiles": {
        "name"     : "TypePad Profiles",
        "domain"   : "profile.typepad.com",
        "homepage" : "http://profile.typepad.com/%user",
        "profile"  : "http://profile.typepad.com/%user",
        "favicon"  : "http://www.typepad.com/favicon.ico",
        "feeds"    : [ "http://profile.typepad.com/%user/comments/atom.xml" ],
        "regex"    : [ "http://profile.typepad.com[^/]*/([^/]+)" ]        
    },
    "typepad":     {
        "name"     : "TypePad",
        "domain"   : "typepad.com",
        "homepage" : "http://%user.typepad.com",
        "profile"  : "http://%user.typepad.com",
        "regex"    : [ "^http://([^.]+)(?<!profile).typepad.com" ]
    },
    "upcoming":    {
        "name"     : "Upcoming",
        "domain"   : "upcoming.yahoo.com",
        "types"    : [ "events" ],
        "homepage" : "http://upcoming.yahoo.com/user/%user",
        "profile"  : "http://upcoming.yahoo.com/user/%user",
        "feeds"    : [ "http://upcoming.yahoo.com/syndicate/v2/my_events/%user" ],
        "regex"    : [ "upcoming.yahoo.com/user/([^/]+)", "http://upcoming.yahoo.com/syndicate/v2/my_events/([^/]+)" ]
    },
    "useperl": "use.perl",
    "use.perl":    {
        "name"     : "use.perl",
        "domain"   : "use.perl.org",
        "homepage" : "http://use.perl.org/~%user",
        "profile"  : "http://use.perl.org/~%user",
        "feeds"    : [ "http://use.perl.org/~%user/journal/rss" ],
        "regex"    : [ "use.perl.org/~([^/]+)" ]
    },
    "yelp":        {
        "name"     : "Yelp",
        "domain"   : "yelp.com",
        "types"    : [ "reviews" ],
        "homepage" : "http://yelp.com/user_details?user_id=%user",
        "profile"  : "http://yelp.com/user_details?user_id=%user",
        "feeds"    : [ "http://www.yelp.com/syndicate/user/%user/atom.xml", "http://www.yelp.com/syndicate/user/%user/rss.xml" ],
        "regex"    : [ "yelp.com/user_details?.*user_*id=([^&;]+)", "yelp.com/syndicate/user/([^/]+)", "http://([^.]+).yelp.com" ]
    },
    "youtube":     {
        "name"     : "YouTube",
        "domain"   : "youtube.com",
        "types"    : [ "videos" ],
        "homepage" : "http://youtube.com/%user",
        "profile"  : "http://youtube.com/%user",
        "feeds"    : [ "http://gdata.youtube.com/feeds/users/%user/uploads" ],
        "regex"    : [ "youtube.com/[^/]*/users/([^/]+)", "youtube.com/user/([^/]+)", "youtube.com/([^/]+)" ]
    },
    "wordpress":   {
        "name"     : "Wordpress",
        "domain"   : "wordpress.com",
        "homepage" : "http://%user.wordpress.com",
        "profile"  : "http://%user.wordpress.com/about/",
        "feeds"    : ["http://%user.wordpress.com/feed/" ],
        "regex"    : ["^http://([^.]+).wordpress.com" ]
    },
    "worldofwarcraft": "wow", 
    "wow": {
        "name"     : "World of Warcraft",
        "domain"   : "wowarmory.com",
        "regex"    : ["wowarmory.com" ]
    },
    "vimeo":       {
        "name"     : "Vimeo",
        "domain"   : "vimeo.com",
        "homepage" : "http://vimeo.com/%user",
        "profile"  : "http://vimeo.com/%user",
        "feeds"    : [ "http://vimeo.com/%user/videos/rss" ],
        "regex"    : [ "vimeo.com/([^/]+)" ]
    },
    "vox":         {
        "name"     : "Vox",
        "domain"   : "vox.com",
        "favicon"  : "http://static.vox.com/.shared:v42.22:vox:en/images/favicon.ico",
        "homepage" : "http://%user.vox.com",
        "profile"  : "http://%user.vox.com/profile/",
        "foaf"     : "http://%user.vox.com/profile/foaf.rdf",
        "feeds"    : ["http://%user.vox.com/library/posts/atom-full.xml", "http://%user.vox.com/library/posts/rss-full.xml"],
        "regex"    : ["^http://([^.]+).vox.com" ]
    },
    "xbl": "xboxlive",
    "xboxlive":    {
        "name"     : "XBox Live",
        "domain"   : "xboxlive.com",
        "homepage" : "http://avatar.xboxlive.com/avatar/%user/avatar-body.png",
        "profile"  : "http://avatar.xboxlive.com/avatar/%user/avatar-body.png",
        "favicon"  : "http://avatar.xboxlive.com/avatar/%user/avatarpic-s.png",
        "feeds"    : [ "http://pipes.yahoo.com/pipes/pipe.run?_id=6d0f56fb09827655d1327aa2b6840d90&_render=rss&gamertag=%user" ],
        "regex"    : [ "xboxlive.com/avatar/([^/]+)" ]
    },
    "zooomr":      {
        "name"     : "Zooomr",
        "domain"   : "zooomr.com",
        "types"    : [ "photos" ],
        "homepage" : "http://www.zooomr.com/photos/%user/",
        "profile"  : "http://www.zooomr.com/people/%user/",
        "regex"    : [ "api.zooomr.com/services/feeds/public_photos/?id=([^&]+)", "zooomr.com/[^/]+/([^/]+)"]        
    }
}
