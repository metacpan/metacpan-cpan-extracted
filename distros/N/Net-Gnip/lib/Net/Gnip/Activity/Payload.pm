package Net::Gnip::Activity::Payload;

use strict;
use base qw(Net::Gnip::Base);
use Carp qw(confess);

=head1 NAME

Net::Gnip::Activity::Payload - represent the payload in a Gnip activity item

=head1 SYNOPSIS

    my $payload = Net::Gnip::Activity::Payload->new($body);
    $payload->raw($meta_data);

    $activity->payload($payload);
    my $payload = $activity->payload;

=head1 METHODS;

=cut

=head2 new <body> [opt[s]]

Create a new payload.

=cut
sub new {
    my $class = shift;
    my $body  = shift || confess "You must pass in a body\n";
    my %opts  = @_;
    $opts{body} ||= $body;
    return bless {%opts}, ref($class) || $class;
}

=head2 body [body]

Get or set the body of this payload.

=cut
sub body { shift->_do('body', @_); }

=head2 raw [raw]

Get or set the raw of this payload.

=cut
sub raw { shift->_do('raw', @_); }

=head2 parse <xml>

Takes a string of XML, parses it and returns a new,
potentially populated payload

=cut
sub parse {
    my $class  = shift;
    my $xml    = shift;
    my %opts   = @_;
    my $no_dt  = (ref($class) && $class->{_no_dt}) || $opts{_no_dt};
    my $parser = $class->parser;
    my $doc    = $parser->parse_string($xml);
    my $elem   = $doc->documentElement();
    return $class->_from_element($elem);
}

sub _from_element {
    my $class  = shift;
    my $elem   = shift;

    my %opts;
    foreach my $child ($elem->childNodes) {
        my $name = $child->nodeName;
        my $text = ($child->firstChild()) ? $child->firstChild()->textContent() : undef;
        next unless defined $text;
        $opts{$name} = $text;
    }
    my $body = delete $opts{body} || return undef;
    return $class->new($body, %opts);
}

=head2 as_xml

Return this payload as xml

=cut

sub as_xml {
    my $self       = shift;
    my $as_element = shift;
    my $element = XML::LibXML::Element->new('payload');
    foreach my $name (qw(body raw)) {
        next unless defined $self->{$name};
        my $tmp = XML::LibXML::Element->new($name);
        $tmp->appendTextNode($self->{$name});
        $element->addChild($tmp);
    }
    return ($as_element) ? $element : $element->toString(1);

}



1;
