package Net::Google::Calendar::FeedLink;
{
  $Net::Google::Calendar::FeedLink::VERSION = '1.05';
}

use strict;
use XML::Atom::Feed;
use XML::Atom::Link;
use base qw(XML::Atom::Link Net::Google::Calendar::Base);
use LWP::Simple qw(get);

=head1 NAME

Net::Google::Calendar::FeedLink - represents a link to a feed

=head1 SYNOPSIS

    my @feeds = $comments->feeds;

    foreach my $feed (@feeds) {
        print "There are ".$feed->count_hint." comments in this feed\n";
        print "Is this feed read only? ".$feed->read_only."\n";
        print "This feed ".(($feed->href)? "is" : "isn't" )." remote\n";
        print "This feed is of type ".$feed->rel."\n";

        my $atom = $cal->get_feed($feed->feed); # $obj is an XML::Atom::Feed
        foreach my $comment ($atom->entries) {
            print "\t".$comment->title."\n";
        }
    }

=head1 METHODS

=cut

=head2 new

Create a new FeedLink

=cut

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

=head2 count_hint 

Hints at the number of entries in the feed. 
Depending on the implementation, may not be a precise count.

=cut

sub count_hint {
    my $self = shift;
    return $self->_do('@countHint', @_);
}

=head2 element_name

Return our Element name

=cut

sub element_name {
    return 'gd:feedLink';
}

=head2 read_only  [boolean]

Specifies whether the contained feed is read-only.

=cut

sub read_only {
    my $self = shift;
    if (@_) {
        my $val = @_;
        push @_, ($val)? 'true' : 'false';
    }
    return _convert_bool($self->_do('@readOnly', @_));
}

sub _convert_bool {
    my $val = shift;
    return ''   if !defined $val;
    return $val if ($val =~ m!^(\d+)$! && ($val==0 or $val==1));
    return 0    if $val eq 'false';
    return 1    if $val eq 'true';
    #die "Illegal boolean value $val";
	return ($val)? 1 : 0;
}

=head2 rel [rel]

Specifies the link relation; allows the service to provide 
multiple types of feed links for a single entity. Has the 
same semantics and allowed values as the rel attribute of 
the <atom:link> element.
 
=cut

sub rel {
    my $self = shift;
    return $self->_do('@rel', @_);
}


=head2 href [url]

Specifies the feed URI. If the nested feed is embedded and not 
linked, this attribute may be omitted.

=cut

sub href {
    my $self = shift;
    return URI->new($self->_do('@href'));
}


sub _do {
    my $self = shift;
    my $name  = shift;
    my $attr  = ($name =~ s!^@!!);
    my $gd_ns = ''; # $self->{_gd_ns};
    if (@_) {
        my $new = shift;
        if ($attr) {
            $self->set_attr($name, $new);
        } else {
            $self->set($gd_ns, "${name}", '', { value => "${new}" });
        }
    }
    my $val;
    if ($attr) {
        $val = $self->get_attr($name);
    } else { 
        $val = $self->_my_get($gd_ns, "${name}");
    }
    return $val;
}

=head2 feed [feed]

Get the Atom feed. 

Returns a URI object if the feed is remote 
or a scalar containing an XML::Atom::Feed object

=cut

sub feed {
    my $self = shift;
    my $ns   = ""; # "http://purl.org/atom/ns#";
    if (@_) {
        my $feed = shift;
        XML::Atom::Base::set($self, $ns, 'feed', $feed, {});
        #$self->add($ns, 'feed', $feed, {});
    }
    my $href = $self->href;
    if (defined $href) {
        return URI->new($href);
    } else {
        my $feed = $self->_do('feed') || return;
        my $tmp = XML::Atom::Feed->new( Elem => $feed );
        $tmp->{ns} = $ns;
        return $tmp;
    }
}
1;
