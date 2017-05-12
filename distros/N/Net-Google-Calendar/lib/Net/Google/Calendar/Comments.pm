package Net::Google::Calendar::Comments;
{
  $Net::Google::Calendar::Comments::VERSION = '1.05';
}

use strict;
use Net::Google::Calendar::FeedLink;
use base qw(Net::Google::Calendar::Base XML::Atom::Link);

=head1 NAME

Net::Google::Calendar::Comments - represent comments

=head1 SYNOPSIS

    my ($event)  = $cal->get_events;
    my $comments = $event->comments;
    
    if (!defined $comments) {
        die "No comments!\n";
    } 

    print "Comments are of type: ".$comments->rel."\n";
    my $feed = $comments->feed_link;

    print "There are ".$feed->count_hint." comments in this feed\n";
    print "Is this feed read only? ".$feed->read_only."\n";
    print "This feed ".(($feed->href)? "is" : "isn't" )." remote\n";
    print "This feed is of type ".$feed->rel."\n";
    foreach my $comment ($cal->get_feed($feed->feed)->entries) {
        print "\t".$comment->title."\n";
    }

=head1 METHODS 

=cut

=head2 new 

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    my $self = $class->SUPER::new(Version => "1.0", %opts);
    return $self;
}

=head2 rel [rel]

Type of comments contained within. Currently, there's a 
distinction between regular comments and reviews.

Returns either C<regular> (or C<undef> which means the same) or C<reviews>.

=cut

sub rel {
    my $self = shift;
    my $pre  = "http://schemas.google.com/g/2005#";
    if (@_) {
        my $new  = shift;
        my @vals = qw(regular reviews); 
        die "$new is not one of the allowed values for rel (".join(",", @vals).")"
            unless grep { $new eq $_ } @vals;
        $self->set_attr('rel', "${pre}${new}");
    }
    my $rel = $self->get_attr('rel');
    $rel =~ s!^$pre!! if defined $rel;
    return $rel;
}

=head2 element_name

Our element name

=cut

sub element_name {
    return 'gd:comments';
}

=head2 feed_link [feed_link]

Get or set the feed link objects.

=cut 

sub feed_link {
    my $self = shift;
    my $name = 'gd:feedLink';
    my $ns   = '';
    #my $ns = "http://schemas.google.com/g/2005";
    if (@_) {
        my $feed = shift;
        XML::Atom::Base::set($self, $ns, $name, $feed, {});
        #$self->set($ns, $name, $feed, {});

    }
    my $tmp = $self->_my_get($ns, $name);
    return Net::Google::Calendar::FeedLink->new(Elem => $tmp);
}

1;
