package Serengeti::Backend::Native;

use strict;
use warnings;

use Module::Load qw();

use JavaScript;
use Scalar::Util qw(weaken refaddr);

require Exporter;

use Serengeti::Backend::Native::Document;
use Serengeti::Backend::Native::HTMLCollection;
use Serengeti::Backend::Native::HTMLElement;
use Serengeti::Backend::Native::Window;

use Serengeti::NotificationCenter;
use Serengeti::Notifications;

our @ISA = qw(Exporter);

our $UserAgent = 
    "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; " .
    "en-US; rv:1.9.1.8) Gecko/20100202 Firefox/3.5.8";

our %DefaultHeaders = (
    "Accept"            => "text/html,application/xhtml+xml," .
                           "application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language"   => "en-us,en;q=0.5",
    "Accept-Encoding"   =>  "gzip,deflate",
    "Accept-Charset"    => "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
);

our $Transport = "Serengeti::Backend::Native::Transport::Curl";

our @EXPORT = qw();
our @EXPORT_OK = qw($UserAgent %DefaultHeaders);

use accessors::ro qw(transport session current_document);

sub setup_document_jsapi {
    my ($self, $ctx) = @_;

    use Data::Dumper qw(Dumper);
    
    Serengeti::Backend::Native::Document->setup_jsapi($ctx);
    Serengeti::Backend::Native::HTMLElement->setup_jsapi($ctx);
    
    $ctx->bind_class(
        name    => "NodeList",
        package => "XML::XPathEngine::NodeSet",
        methods => {
            item => sub { shift->get_node(shift() + 1); },
        },
        getter => sub {
            my ($node_list, $property) = @_;
            return $node_list->size() if $property eq "length";
            if ($property >= 0 && $property < $node_list->size() ) {
                return $node_list->get_node($property + 1);
            }

            return;
        },
        flags   => JS_CLASS_NO_INSTANCE,
    );
        
    $ctx->bind_class(
        name => "HTMLCollection",
        package => "Serengeti::Backend::Native::HTMLCollection",
        flags => JS_CLASS_NO_INSTANCE,
        getter => \&Serengeti::Backend::Native::HTMLCollection::get_property,
    );
    
    1;
}

sub setup_window_jsapi {
    my ($self, $ctx) = @_;
    
    Serengeti::Backend::Native::Window->setup_jsapi($self, $ctx);
    
    1;
}

sub new {
    my ($pkg) = @_;
    
    Module::Load::load $Transport;
    
    my $self = bless {
        transport => $Transport->new(),
        session   => undef,
    }, $pkg;
    
    return $self;
}

sub _handle_response {
    my ($self, $response, $url, $options) = @_;

    my $document = Serengeti::Backend::Native::Document->new(
        $response->decoded_content(),
        { 
            location => URI->new($url),
            browser => $self, 
        }
    );
    
    $self->{current_document} = $document;
    
    $options = {} unless ref $options eq "HASH";
    
    unless ($options->{no_broadcast}) {
        # Notify listeners that we've got a new global doc if it's
        # not requested by a frame
        Serengeti::NotificationCenter->post_notification(
            $self, DOCUMENT_CHANGED_NOTIFICATION, $document
        );
    }
    
    return $document;
}

sub get {
    my ($self, $url, $query_data, $options) = @_;
    
    my $response = $self->transport->get($url, $query_data, $options);
    
    return $self->_handle_response($response, $url, $options);
}

sub post {
    my ($self, $url, $form_data, $options) = @_;
    
    my $response = $self->transport->post($url, $form_data, $options);
    
    return $self->_handle_response($response);
}


1;
__END__