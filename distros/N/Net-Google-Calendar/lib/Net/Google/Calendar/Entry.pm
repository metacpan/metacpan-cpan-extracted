package Net::Google::Calendar::Entry;
{
  $Net::Google::Calendar::Entry::VERSION = '1.05';
}

use strict;
use Data::Dumper;
use DateTime;
use XML::Atom;
use XML::Atom::Entry;
use XML::Atom::Util qw( set_ns first nodelist childlist iso2dt create_element);
use base qw(XML::Atom::Entry Net::Google::Calendar::Base);
use Net::Google::Calendar::Person;
use Net::Google::Calendar::Comments;


=head1 NAME

Net::Google::Calendar::Entry - entry class for Net::Google::Calendar

=head1 SYNOPSIS

    my $event = Net::Google::Calendar::Entry->new();
    $event->title('Party!');
    $event->content('P-A-R-T-Why? Because we GOTTA!');
    $event->location("My Flat, London, England");
    $event->status('confirmed'); 
    $event->transparency('opaque');
    $event->visibility('private'); 

    my $author = Net::Google::Calendar::Person->new;
    $author->name('Foo Bar');
    $author->email('foo@bar.com');
    $entry->author($author);



=head1 DESCRIPTION

=head1 METHODS

=head2 new 

Create a new Event object

=cut

sub new {
    my ($class, %opts) = @_;
    my $self  = $class->SUPER::new( Version => '1.0', %opts );
    $self->_initialize();
    return $self;
}

sub _initialize {
    my ($self)  = @_;
	$self->SUPER::_initialize();
    $self->category({ scheme => 'http://schemas.google.com/g/2005#kind', term => 'http://schemas.google.com/g/2005#event' } );
    $self->set_attr('xmlns:gd', 'http://schemas.google.com/g/2005');
    $self->set_attr('xmlns:gCal', 'http://schemas.google.com/gCal/2005');
    unless ( $self->{_gd_ns} ) {
        $self->{_gd_ns} = XML::Atom::Namespace->new(gd => 'http://schemas.google.com/g/2005');
    }
    unless ( $self->{_gcal_ns} ) {
        $self->{_gcal_ns} = XML::Atom::Namespace->new(gCal => 'http://schemas.google.com/gCal/2005');
    }

}

=head2 id [id]

Get or set the id.

=cut

=head2 title [title]

Get or set the title.

=cut

=head2 content [content]

Get or set the content.

=cut

sub content {
    my $self= shift;
    if (@_) {
        $self->set($self->ns, 'content', shift);  
    }
    return $self->SUPER::content;
}

=head2 author [author]

Get or set the author

=cut

=head2 transparency [transparency] 

Get or set the transparency. Transparency should be one of

    opaque
    transparent

=cut

sub transparency {
    my $self = shift;
    return $self->_gd_element('transparency', @_);
}


=head2 visibility [visibility] 

Get or set the visibility. Visibility should be one of

    confidential
    default
    private
    public 

=cut

sub visibility {
    my $self = shift;
    return $self->_gd_element('visibility', @_);
}

=head2 status [status]

Get or set the status. Status should be one of

    canceled
    confirmed
    tentative

=cut

sub status {
    my $self = shift;
    return $self->_gd_element('eventStatus', @_);    
}



=head2 is_allday                                                                                                                                          
                                                                                                                                                           
Get the allday flag.                                                                                                                                      
                                                                                                                                                           
Returns 1 of event is an All Day event, 0 if not, undef if it can't be                                                                                    
determined.                                                                                                                                               
                                                                                                                                                           
=cut                                                                                                                                                      
                                                                                                                                                           
sub is_allday {                                                                                                                                           
     my $self = shift;                                                                                                                                     
                                                                                                                                                           
     my $start = $self->_attribute_get($self->{_gd_ns}, 'when', 'startTime');                                                                              
     my $end   = $self->_attribute_get($self->{_gd_ns}, 'when', 'endTime');                                                                                
                                                                                                                                                           
     my $startok = undef;                                                                                                                                  
     my $endok = undef;                                                                                                                                    
                                                                                                                                                           
     if ($start =~ /^[0-9]{4}-[0-1][0-9]-[0-3][0-9]$/) { $startok = 1; }                                                                                   
     if ($end   =~ /^[0-9]{4}-[0-1][0-9]-[0-3][0-9]$/) { $endok = 1; }                                                                                     
                                                                                                                                                           
     if ($startok && $endok)   { return 1; }                                                                                                                
     if (!$startok && !$endok) { return 0; }                                                                                                              
     return undef;                                                                                                                                        
}                                                                                                                                                         
         

=head2 extended_property [property]

Get or set an extended property

=cut

sub extended_property {
	my $self = shift;
	return $self->_multi_gd_element('extendedProperty', @_);
}

sub _multi_gd_element {
    my $self = shift;
    $self->_gd_elem_generic(1, @_);
}

sub _gd_element{
    my $self = shift;
    $self->_gd_elem_generic(0, @_);
}

sub _gd_elem_generic{
    my $self  = shift;
    my $multi = shift;
    my $elem  = shift;

    if ($elem eq "extendedProperty") {
      	if (@_) {
           	my $name = shift;
           	my $val  = shift;
           	my $op   = $multi ? 'add' : 'set';
           	$self->$op($self->{_gd_ns}, "${elem}" => "", { name => $name, value => $val } );
           	return $val;
       	}
       	my $ret = {};
       	for my $item ($self->_my_getlist($self->{_gd_ns} ,$elem)) {
          	$ret->{$item->getAttribute('name')} = $item->getAttribute('value');
       	}
    	return $ret;
    }

    if (@_) {
        my $val = lc(shift);
        my $op  = ($multi)? 'add' : 'set';
        $self->$op($self->{_gd_ns}, "${elem}",  '', { value => "http://schemas.google.com/g/2005#event.${val}" });
        return $val;
    }
    my $val = $self->_attribute_get($self->{_gd_ns}, $elem, 'value');
    $val =~ s!^http://schemas.google.com/g/2005#event\.!!;
    return $val;
}

sub _attribute_get {
    my ($self, $ns, $what, $key) = @_;
    my $elem = $self->_my_get($self->{_gd_ns}, $what, $key);
    
    if (defined($elem) && $elem->hasAttribute($key)) {
        return $elem->getAttribute($key);
    } else {
        return $elem;
    }
}

=head2 location [location]

Get or set the location

=cut

sub location {
    my $self = shift;

    if (@_) {
        my $val = shift;
        $self->set($self->{_gd_ns}, 'where' => '', { valueString => $val});
        return $val;
    }
    
    return $self->_attribute_get($self->{_gd_ns}, 'where', 'valueString');
}


=head2 quick_add [bool]

Get or set whether this is a a quick add entry or not.

=cut 
sub quick_add {
    my $self = shift;

    if (@_) {
        my $val = ($_[0])? 'true' : 'false';
        $self->set( $self->{_gcal_ns}, quickadd => '', { value => $val } );        
        return $_[0];
    }
    my $val = $self->_attribute_get($self->{_gcal_ns}, 'quickadd', 'valueString');
    return ($val eq 'true');
}



=head2 when [<start> <end> [allday]]

Get or set the start and end time as supplied as DateTime objects. 
End must be more than start.

You may optionally pass a paramter in designating if this is an all day event or not.

Returns two DateTime objects depicting the start and end and a flag noting whether it's an all day event. 


=cut

sub when {
    my $self = shift;

    if (@_) {
        my ($start, $end, $allday) = @_;
        $allday = 0 unless defined $allday;
        unless ($end>=$start) {
            $@ = "End is not less than start";
            return undef;
        }
        $start->set_time_zone('UTC');
        $end->set_time_zone('UTC');
        
        my $format = $allday ? "%F" : "%FT%TZ";

        $self->set($self->{_gd_ns}, "when",  '', { 
            startTime => $start->strftime($format),
            endTime   => $end->strftime($format),
        });        
    }
    my $start = $self->_attribute_get($self->{_gd_ns}, 'when', 'startTime');
    my $end   = $self->_attribute_get($self->{_gd_ns}, 'when', 'endTime');
    my @rets;
    if (defined $start) {
        push @rets, $start;
    } else {
        return @rets;
        #die "No start date ".$self->as_xml;
    }
    if (defined $end) {
        push @rets, $end;
    } 
    return (map { iso2dt($_) } @rets), $self->is_allday;

}

=head2 reminder <method> <type> <when>

Sets a reminder on this entry.

C<method> must be one of:

    alert email sms

C<type> must be one of 

    days hours minutes absoluteTime

If the type is C<absoluteTime> then C<when> should be either a iso formatted date string or a DateTime object.

=cut

sub reminder {
    my $self = shift;
    my ($method, $type, $time) = @_;
    return undef unless ($method =~ /alert|email|sms/);
    return undef unless ($type =~ /days|hours|minutes|absoluteTime/);
    $time = $time->strftime("%FT%TZ") if ref($time) && $time->isa('DateTime');
    for my $item ($self->_my_getlist($self->{_gd_ns} ,'when')) {
       my $elem = create_element($self->{_gd_ns}, 'reminder');
       $elem->setAttribute('method', $method);
       $elem->setAttribute($type, $time);
       $item->appendChild($elem);
    }
    return 1;
}





=head2 who [Net::Google::Calendar::Person[s]]

Get or set the list of event invitees.

If no parameters are passed then it returns a list containing zero 
or more Net::Google::Calendar::Person objects.

If you pass in one or more Net::Google::Calendar::Person objects then 
they get set as the invitees.

=cut

# http://code.google.com/apis/gdata/elements.html#gdWho
sub who {
    my $self = shift;

    my $ns_uri = ""; # $self->{_gd_ns};
    my $name   = 'gd:who';
    foreach my $who (@_) {
        $self->add($ns_uri,"${name}", $who, {});
    }
    my @who = map {
       my $person = Net::Google::Calendar::Person->new();
       for my $attr ($_->attributes) {
                my $name = $attr->nodeName;
                my $val  = $attr->value || "";
                #print "$name = $val\n";
                eval { $person->_do('@'.$name, $val) };
                next if $@;
       }
       foreach my $child ($_->childNodes) {
            my $name = $child->nodeName;
            my $val  = $child->getAttribute('value');
            #print "$name = $val\n";
            $person->_do($name, $val);
       }
       #print $person->as_xml;
       #print "\n\n";
       $person;
    } $self->_my_getlist($ns_uri,$name);
}

=head2 comments [comment[s]]

Get or set Comments object.

=cut

sub comments {
    my $self = shift;

    my $ns_uri = $self->{_gd_ns};
    my $name   = 'gd:comments';
    if (@_) {
        $self->add($ns_uri,"${name}", shift, {});
    }

    my $tmp = $self->_my_get($ns_uri, $name);
    my $comment = Net::Google::Calendar::Comments->new();
    for my $attr ($tmp->attributes) {
           my $name = $attr->nodeName;
        my $val  = $attr->value || "";
        eval { $comment->_do('@'.$name, $val) };
        next if $@;
    }
    my $feed = Net::Google::Calendar::FeedLink->new(Elem => $tmp->firstChild);
    $comment->feed_link($feed) if $feed;
    return $comment;
}




=head2 edit_url 

Return the edit url of this event.

=cut


sub edit_url {
    return $_[0]->_generic_url('edit');
}


=head2 self_url

Return the self url of this event.

=cut



sub self_url {
    return $_[0]->_generic_url('self');
}


=head2 html_url

Return the 'alternate' browser-friendly url of this event.

=cut

sub html_url {
    return $_[0]->_generic_url('alternate');
}



=head2 recurrence [ Data::ICal::Entry::Event ]

Get or set a recurrence for an entry - this is in the form of a Data::ICal::Entry::Event object. 

Returns undef if there's no recurrence event

This will not work if C<Data::ICal> is not installed and will return undef.

For example ...

    $event->title('Pay Day');
    $event->start(DateTime->now);

    my $recurrence = Data::ICal::Entry::Event->new();


    my $last_day_of_the_month = DateTime::Event::Recurrence->monthly( days => -1 );
    $recurrence->add_properties(
               dtstart   => DateTime::Format::ICal->format_datetime(DateTime->now),
               rrule     => DateTime::Format::ICal->format_recurrence($last_day_of_the_month),
    );

    $entry->recurrence($recurrence);

To get the recurrence back:

    print $entry->recurrence->as_string;

See 

    http://code.google.com/apis/gdata/common-elements.html#gdRecurrence

For more details

=cut

sub recurrence {
    my $self = shift;
    
    # we need Data::ICal for this but we don't wnat to require it
    eval {
        require Data::ICal;
        Data::ICal->import;
        require Data::ICal::Entry::Event;
        Data::ICal::Entry::Event->import;
    
    };
    if ($@) {
        $@ = "Couldn't load Data::ICal or Data::ICal::Entry::Event: $@";
        return;
    }

    # this is all one massive hack. 
    # I hate myself for writing this.
    if (@_) {
        my $event  = shift;
        # pesky Google Calendar needs you to remove the BEGIN:VEVENT END:VEVENT. TSSSK
        my $recur =  $event->as_string;

        $recur =~ s!(^BEGIN:VEVENT\n|END:VEVENT\n$)!!sg; 
        $self->set($self->{_gd_ns}, 'recurrence', $recur);

        return $event;
    }
    my $string = $self->get($self->{_gd_ns}, 'recurrence');
    return undef unless defined $string;
    $string =~ s!\n+$!!g;
    $string = "BEGIN:VEVENT\n${string}\nEND:VEVENT";
    my $vfile = Text::vFile::asData->new->parse_lines( split(/\n/, $string) );
    my $event = Data::ICal::Entry::Event->new();
    #return $event;

    $event->parse_object($vfile->{objects}->[0]);
    return $event->entries->[0];

}

=head2 add_link <link>

Adds the link $link, which must be an XML::Atom::Link object, to the entry as a new <link> tag. For example:

    my $link = XML::Atom::Link->new;
    $link->type('text/html');
    $link->rel('alternate');
    $link->href('http://www.example.com/2003/12/post.html');
    $entry->add_link($link);

=cut

sub add_link {
    my ($self, $link) = @_;
    # workaround bug in XML::Atom
    $link = bless $link, 'XML::Atom::Link' if ref($link) && $link->isa('XML::Atom::Link');
    $self->SUPER::add_link($link);
}

=head2 original_event [event]

Get or set the original event ID.

=cut

sub original_event {
    my $self = shift;
    return $self->_gd_element('originalEvent', @_);
}

=head1 TODO

=over 4

=item more complex content

=item more complex locations

=item recurrency

=item comments

=back

See http://code.google.com/apis/gdata/common-elements.html for details

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright Simon Wistow, 2006

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

http://code.google.com/apis/gdata/common-elements.html

L<Net::Google::Calendar>

L<XML::Atom::Event>

=cut



1;
