package Net::Google::Calendar::WebContent;
{
  $Net::Google::Calendar::WebContent::VERSION = '1.05';
}

use strict;
use XML::Atom;
use XML::Atom::Link;
#use XML::LibXML;
#use XML::Atom::Namespace;
use base qw(XML::Atom::Link Net::Google::Calendar::Base);
use vars qw(@ISA);
unshift @ISA, 'XML::Atom::Link';
my $ns = XML::Atom::Namespace->new(
    gCal => 'http://schemas.google.com/gCal/2005'
);


=head1 NAME

Net::Google::Calendar::WebContent - handle web content

=head1 SYNOPSIS

Web content can be images ...

    my $content = Net::Google::Calendar::WebContent->new(
        title       => 'World Cup',
        href        => 'http://www.google.com/calendar/images/google-holiday.gif',
        web_content => {
            url     => "http://www.google.com/logos/worldcup06.gif" 
            width   => 276,
            height  => 120,
            type    => 'image/gif',
        }
    );
    $entry->add_link($content);

or html ...

    my $content = Net::Google::Calendar::WebContent->new(
        title       => 'Embedded HTML',
        href        => 'http://www.example.com/favico.icon',
        web_content => {
            url     => "http://www.example.com/some.html" 
            width   => 276,
            height  => 120,
            type    => 'text/html',
        }
    );
    $entry->add_link($content);


or special Google Gadgets (http://www.google.com/ig/directory)

    my $content = Net::Google::Calendar::WebContent->new(
        title       => 'DateTime Gadget (a classic!)',
        href        => 'http://www.google.com/favicon.ico',
        web_content => {
            url     => 'http://google.com/ig/modules/datetime.xml',
            width   => 300,
            height  => 136,
            type    => 'application/x-google-gadgets+xml',
        }
    );


or
    my $content = Net::Google::Calendar::WebContent->new(
        title      => 'Word of the Day',
        href       => 'http://www.thefreedictionary.com/favicon.ico',
    );
    $content->web_content(
            url    => 'http://www.thefreedictionary.com/_/WoD/wod-module.xml',
            width  => 300,
            height => 136,
            type   => 'application/x-google-gadgets+xml',
            prefs  => { Days => 1, Format => 0 },
    );

(note the ability to set webContentGadgetPrefs using the special prefs attribute).

=head1 METHODS

=head2 new  [opt[s]]

Options can be 

=over 4

=item title

The title of the web content

=item href
A url of an icon to use

=item type

The mime type of content. Can be either C<text/html> C<image/*> or C<application/x-google-gadgets+xml>

Not needed for C<text/html>.

=item web_content

The actual web content. This just gets passed to the C<web_content()> method.

=back

=cut


sub new {
    my $class  = shift;
    my %params = @_;
    
    #my $self   =  XML::Atom::Link->new(Version => "1.0");
    #$self = bless $self, $class;
    my $ns    = XML::Atom::Namespace->new(gd => 'http://schemas.google.com/g/2005');
    my $self = $class->SUPER::new(Version => "1.0", );
    $self->{_gd_ns} = $ns;
    $self->rel('http://schemas.google.com/gCal/2005/webContent');
    for my $field (qw(title href)) {
        die "You must pass in the field '$field' to a WebContent link\n" 
            unless defined $params{$field};
        $self->$field($params{$field}); 
    }
    my $type = $params{type};
    #die "You must pass a type" unless defined $type;
    $self->_set_type($type) if defined $type;

    if ($params{web_content}) {
        $self->web_content(%{$params{web_content}}); 
    } else {
        # h-h-hack
        $self->web_content(empty => 1);
    }
    return $self;
}

sub _set_type {
     my $self = shift;
     my $type = shift;
     unless ($type eq 'text/html' or 
             $type eq 'application/x-google-gadgets+xml' or
             $type =~ m!^image/!) {
         die "The type param must be text/html or application/x-google-gadgets+xml or image/*\n";
     }
     $self->type($type);

}

=head2 web_content [param[s]]

Takes a hash of parameters. Valid are 

=over 4

=item url

The url of the content.

=item width

The width of the content.

=item height

The height of the content.

=item type

The mime-type (see above)

=item prefs

This takes a hash ref and all pairs are turned into C<webContentGadgetPref> entries.

=back

=cut

sub web_content {
    my $self = shift;
    my $name    = 'gCal:webContent';
    if (@_) {
        my %params = @_;
        # h-h-hack
        %params    = () if $params{empty};
        if (my $type = delete $params{type}) {
            $self->_set_type($type);
        }  
        # egregious hack
        $params{'xmlns:gd'}   = 'http://schemas.google.com/g/2005';
        $params{'xmlns:gCal'} = 'http://schemas.google.com/gCal/2005';
        my $prefs   = delete $params{prefs};    
        XML::Atom::Base::set($self, '', $name, '', \%params);
        my $content = $self->_my_get('', $name); 
        foreach my $key (keys %{$prefs}) {
            # TODO: this feels icky
            my $node;
            if (LIBXML) {
                $node = XML::LibXML::Element->new($name.'GadgetPref');
                $node->setAttribute( name  => $key );
                $node->setAttribute( value => $prefs->{$key} );
            } else {
                $node = XML::XPath::Node::Element->new($name.'GadgetPref');
                $node->addAttribute(XML::XPath::Node::Attribute->new(name  => $key));
                $node->addAttribute(XML::XPath::Node::Attribute->new(value => $prefs->{key}));
            }
            $content->appendChild($node);
        }
    }
    return $self->_my_get('', $name);
}

1;


