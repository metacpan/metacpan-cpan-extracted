package Net::Social::Mapper;

use strict;
use Email::Valid;
use LWP::UserAgent;
use Encode qw(decode_utf8);
use Net::Social::Mapper::SiteMap;

our $VERSION = '0.5';

=head1 NAME

Net::Social::Mapper - utilities for dealing with internet persona

=head1 SYNOPSIS


    my $mapper   = Net::Social::Mapper->new;
    my $persona  = $mapper->persona('daveman692', 'livejournal');

    print $persona->user;    # daveman692
    print $persona->service; # livejournal
    print $persona->domain;  # livejournal.com
    print $persona->name;    # LiveJournal

    # Print out any feeds available (if any exist)
    print "Feeds : ".join(", ", @feeds);

    # What type are the feed items 
    print "Feeds contain : ".join(", ", $persona->types);

    # These other options may or may not be available
    print "Home page   : ".$persona->homepage;
    print "Profile url : ".$persona->profile;
    print "Full Name   : ".$persona->full_name;
    print "Service id  : ".$persona->id;
    print "Photo url   : ".$persona->photo;
    print "FOAF  url   : ".$persona->foaf;

    # If you have network access then you can query 
    # who they are elsewhere on the web
    my @personas = $persona->elsewhere;

    # Other examples ...

    my $persona  = $mapper->persona('daveman692', 'flickr');
    print $persona->user;    # daveman692
    print $persona->id;      # 36381329@N00

    my $persona  = $mapper->persona('http://davidrecordon.com');
    print $persona->user;    # http://davidrecordon.com 
    print $persona->service; # website
    print $persona->domain;  # davidrecordon.com

    my $persona  = $mapper->persona('test@example.com');
    print $persona->user;    # test@example.com
    print $persona->service; # email
    print $persona->id;      # test
    print $person->domain;   # example.com

    # Moreover Net::Social::Mapper tries to work out the service from the url so that  ...
    my $persona  = $mapper->persona('http://daveman692.livejournal.com');
    my $persona  = $mapper->persona('http://daveman692.livejournal.com/data/rss');
    my $persona  = $mapper->persona('http://daveman692.livejournal.com/data/atom');
    my $persona  = $mapper->persona('http://www.livejournal.com/userinfo.bml?user=daveman692');
    # ... all return 
    print $persona->user;    # daveman692
    print $persona->service; # livejournal
    print $persona->domain;  # livejournal.com
    print $persona->name;    # LiveJournal

=head1 METHODS

=cut

=head2 new 

Get a new C<Net::Social::Mapper> object.

=cut
sub new {
    my $class = shift;
    my %opts  = @_;
    my $self  = bless \%opts, $class;
    $self->_init;
    return $self;
}

sub _init { }

=head2 persona <user> [service]

Return a C<Net::Social::Mapper::Persona> object representing the user.

Returns undef if it doesn't know anything about the service.

=cut
sub persona {
    my $self      = shift;
    my $user      = shift;
    my $service   = shift;

    unless (defined $service) {
        if ($user =~ m!@! && $user !~ m!/!) {
            my $original = $user;
            my @pieces   = split '@', $user;
            $service     = pop @pieces;
            $user        = join '@', @pieces;
            my $persona  = $self->_load_persona($user, $service);
            return $persona if $persona; 
            $user        = $original;
        }
        if (Email::Valid->address($user)) {
            $service = 'email';
        } else {
            $service = 'website';
        }
    }
    return $self->_load_persona($user, $service); 
}

sub _load_persona {
    my $self     = shift;
    my $user     = shift || return;
    my $service  = shift;
    my %classmap = $self->classmap; 

    ($user, $service) = $self->sitemap->url_to_service($user) if $service eq 'website';

    my $class     = $classmap{lc($service)} || 'Net::Social::Mapper::Persona::Generic';
    eval "require $class";
    return undef if $@;
    return $class->new($user, lc($service), _mapper => $self);
}

=head2 sitemap 

The C<Net::Social::Mapper::SiteMap> object containing everything we know about various services.

=cut
sub sitemap {
    my $self = shift;
    return $self->{_sitemap} || Net::Social::Mapper::SiteMap->new;
}

=head2 classmap [key value]

Return a hash of (lowercase) service names to classes;

Alternatively if you pass in a key, value pair then that 
will be added to the map.

Passing in C<undef> as the value will delete the key.

=cut
sub classmap {
    my $self = shift;
    $self->{_class_map} ||= {
        email    => 'Net::Social::Mapper::Persona::Email',
        website  => 'Net::Social::Mapper::Persona::Website',
        flickr   => 'Net::Social::Mapper::Persona::Flickr',
        myspace  => 'Net::Social::Mapper::Persona::Myspace',
    };
    if (@_) {
        my %tmp = @_;
        foreach my $key (keys %tmp) {
            my $value = $tmp{$key};
            if (defined $value) {
                $self->{_class_map}->{$key} = $value; 
            } else {
                delete $self->{_class_map}->{$key};
            }
        }
    }
    return %{$self->{_class_map}};
}

=head2 get <url>

Get the contents of the url or undef on failure;

=cut
sub get {
    my $self = shift;
    my $url  = shift             || return;
    my $r    = $self->_get($url) || return;
    return $r->decoded_content;
}

sub _get {
    my $self = shift;
    my $url  = shift || return;
    my $ua   = $self->{_ua} ||= LWP::UserAgent->new(parse_head => 0);
    $self->{_ua}->env_proxy(1);
    my $r    =  $self->{_ua}->get("$url");
    return unless $r->is_success;
    return $r;
}


# a list of all content types that are feeds
sub _feed_types {(
    "text/xml"               => 1,
    "application/xml"        => 1,
    "application/rdf+xml"    => 1,
    "application/rss+xml"    => 1,
    "application/atom+xml"   => 1,
    "application/x.atom+xml" => 1, 
)};

sub _get_feeds {
    my $self  = shift;
    my $url   = shift;
    my %types = $self->_feed_types;
    my $r     = $self->_get($url);
    my $mime  = $r->header('Content-Type') || "";
    $mime =~ s!;.*$!!;
    return ($url) if $types{$mime};
    my $page  = $r->decoded_content;

    my $tmp = eval { decode_utf8($page) };
    $tmp = $page unless defined $tmp;

    return Feed::Find->find_in_html(\$tmp, $url);
}

=head1 AUTHOR

Simon Wistow <swistow@sixapart.com>

=head1 COPYRIGHT

Copyright 2008, Six Apart Ltd.

Released under the same terms as Perl itself.

=cut


1;
