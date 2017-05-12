package Net::Gnip::Activity;

use strict;
use DateTime;
use DateTime::Format::ISO8601;
use base qw(Net::Gnip::Base);
use Net::Gnip::Activity::Payload;

=head1 NAME

Net::Gnip::Activity - a single item of activity in Gnip

=head1 SYNOPSIS

    # Create a new activity
    # 'at' defaults to now
    my $activity = Net::Gnip::Activity->new($action, $actor, %opts);
    
    # ... or parse from xml
    my $activity = Net::Gnip::Activity->parse($xml);

    # at, uid and type are always present
    print "At: ".$activity->at;   # returns a DateTime objec
    $activity->at(DateTime->now); # Can take a string or a DateTime

    print "Actor: ".$activity->actor;
    print "Action: ".$activity->action;

    # These are optional
    print "Url: ".$activity->url;
    print "To: ".$activity->to."\n";
    print "Regarding: ".$activity->regarding."\n";
    print "Source: ".$activity->source."\n";
    print "Tags: ".$activity->tags."\n";

    my $payload = Net::Gnip::Activity::Payload->new($body);
    $activity->payload($payload);

    print $activity->as_xml;

=head1 METHODS

=cut

=head2 new <action> <actor> [option[s]]

Takes a C<action> and a C<actor> as mandatory parameters. 

Options is a hash and can contain C<at>, C<url>, C<regarding>, C<source> and <tags>.

If C<at> isn't passed in then the current time is used.

=cut

sub new {
    my $class    = shift;
    my $action   = shift || die "You must pass in an action";
    my $actor    = shift || die "You must pass in an actor";
    my %opts     = @_;
    my $no_dt    = $opts{_no_dt};
    my $at       = delete $opts{at} || DateTime->now;
    my $self     = bless { %opts, action => $action, actor => $actor }, ref($class) || $class;
    $self->at($at);
    return $self;   
}


=head2 at [value]

Returns the current at value.

Optionally takes either a string or a DateTime object to set 
the at time.

=cut

sub at {
    my $self = shift;
    if (@_) {
        my $dt = shift;
        # normalise to DateTime
        if (ref($dt) && $dt->isa('DateTime')) {
            # normalise to epoch time if we're forcing no DateTime
            $dt = $dt->epoch if $self->{_no_dt};
        } else {
            $dt = $self->_handle_datetime($dt) unless $self->{_no_dt};
        }
        $self->{at} = $dt;
    }

    return $self->{at};
}

=head2 actor [actor]

Gets or sets the current actor.

=cut

sub actor { my $self = shift; $self->_do('actor', @_) }

=head2 action [action]

Gets or sets the current action.

=cut

sub action { my $self = shift; $self->_do('action', @_) }

=head2 url [url]

Gets or sets the current url.

=cut

sub url { my $self = shift; $self->_do('url', @_) }

=head2 to [to]

Gets or sets the current to.

=cut

sub to { my $self = shift; $self->_do('to', @_) }

=head2 regarding [regarding]

Gets or sets the current regarding.

=cut

sub regarding { my $self = shift; $self->_do('regarding', @_) }

=head2 source [source]

Gets or sets the current source.

=cut

sub source { my $self = shift; $self->_do('source', @_) }

=head2 tags [tags]

Gets or sets the current tags.

The param either a list or comma separated string.

Returns a list.

=cut

sub tags { 
    my $self = shift;
    my @args;
    if (@_) {
        push @args, join(", ", @_);
    }
    split /\s*,\s*/, $self->_do('to', @args);
}


=head2 payload [payload]

Get or sets the current payload.

=cut
sub payload { my $self = shift; $self->_do('payload', @_) }




=head2 parse <xml> 

Parse some xml into an activity.

=cut

sub parse {
    my $class  = shift;
    my $xml    = shift;
    my %opts   = @_;
    my $parser = $class->parser();
    my $doc    = $parser->parse_string($xml);
    my $elem   = $doc->documentElement();
    return $class->_from_element($elem, %opts);
}

sub _from_element {
    my $class = shift;
    my $elem  = shift;
    my %opts  = @_;
    my $no_dt  = (ref($class) && $class->{_no_dt}) || $opts{_no_dt};
    foreach my $attr ($elem->attributes()) {
        my $name = $attr->name; 
        $opts{$name} = $attr->value;
    }
    foreach my $payload ($elem->getChildrenByTagName('payload')) {
        $opts{payload}  = Net::Gnip::Activity::Payload->_from_element($payload, _no_dt => $no_dt);
        last;
    }

    $opts{at} = $class->_handle_datetime($opts{at});
    return $class->new(delete $opts{action}, delete $opts{actor}, %opts,  _no_dt => $no_dt);
}

=head2 as_xml 

Return the activity as xml

=cut

sub as_xml {
    my $self       = shift;
    my $as_element = shift;
    my $element    = XML::LibXML::Element->new('activity');
    my $payload    = delete $self->{payload}; 
    foreach my $key (keys %$self) {
        next if '_' eq substr($key, 0, 1); 
        my $value = $self->{$key};
        if ('at' eq $key) {
            $value = DateTime->from_epoch( epoch => $value ) unless ref($value);
            $value = $self->_handle_datetime($value);
        }
        $element->setAttribute($key, $value);
    }
    $element->addChild($payload->as_xml(1)) if defined $payload;
    return ($as_element) ? $element : $element->toString(1);    
}

sub _handle_datetime {
    my $self  = shift;
    my $dt    = shift;

    if (ref $dt && $dt->isa('DateTime')) {
        return $dt->strftime("%FT%H:%M:%SZ")
    } else {
        return DateTime::Format::ISO8601->parse_datetime($dt) 
    }
}
1;
