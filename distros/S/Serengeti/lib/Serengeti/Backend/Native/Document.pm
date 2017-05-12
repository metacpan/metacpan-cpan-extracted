package Serengeti::Backend::Native::Document;

use strict;
use warnings;

use Encode qw();
use HTML::TreeBuilder::XPath;
use HTML::Selector::XPath::Serengeti;
use JavaScript;
use Scalar::Util qw(refaddr);
use URI;

use Serengeti::Backend::Native::DocumentElement;
use Serengeti::Backend::Native::HTMLElementProperties;

use accessors::ro qw(dom location referrer browser);

my %document_for_root;

sub setup_jsapi {
    my ($self, $ctx) = @_;
    
    $ctx->bind_class(
        name => "Document",
        package => __PACKAGE__,
        methods => {
            find                    => \&find,
            findFirst               => \&find_first,
            getElementsByTagName    => \&get_elements_by_tag_name,
            getElementById          => \&get_element_by_id,
        },
        properties => {
            documentElement => sub { shift->dom; },
            location        => sub { shift->location; },
            title           => \&get_title, 
            referrer        => \&get_referrer,
            domain          => sub { shift->location->host; },
            URL             => sub { shift->location->as_string; },
            body            => \&get_body,
            forms           => \&get_forms,
            links           => \&get_links,
            anchors         => \&get_anchors,
            images          => \&get_images,
        },
        flags => JS_CLASS_NO_INSTANCE,
    );
        
    $ctx->bind_class(
        name    => "Location",
        package => "URI",
        properties => {
            hash        => sub { "#" . shift->fragment },
            host        => sub { shift->host_port },
            hostname    => sub { shift->host },
            href        => sub { shift->as_string },
            pathname    => sub { shift->path },
            port        => sub { shift->port },
            protocol    => sub { shift->scheme },
            search      => sub { shift->query }, 
        },
        methods => {
            toString => sub { shift->as_string },
        },
    );

    1;
}

sub new {
    my ($pkg, $source, $attrs) = @_;

    $attrs = {} unless ref $attrs eq "HASH";
    
    my $dom = Serengeti::Backend::Native::DocumentElement->new();
    $dom->parse($source);
    $dom->eof;
    
    my $location = $attrs->{location} || "";
    my $referrer = $attrs->{referrer} || "";
        
    my $self = bless { 
        dom => $dom,
        location => URI->new($location),
        referrer => URI->new($referrer),
        browser => $attrs->{browser},
    }, $pkg;

    $dom->set_owner_document($self);
    
    return $self;
}

sub unregister_dom {
    my $dom = pop;
    delete $document_for_root{refaddr $dom};
}

sub get_title { 
    my $self = shift;
    return to_DOMString($self->dom->findvalue("/html/head/title/text()")); 
}

sub get_referrer {
    my $self = shift;
    return to_DOMString($self->referrer->as_string);
}

sub make_url {
    my ($self, $href) = @_;

    return URI->new($href) if $href =~ m{^(?:file|https?)://};

    # TODO: Check if we have BASE elements
    
    my $new_uri = $self->location->clone;

    if ($href =~ m{/} ) {
        $new_uri->path($href);
    } else {
        my ($base) = $self->location->path =~ m{(.*/)};
        $new_uri->path($base . $href);
    }
    
    return $new_uri;
}

sub get_body {
    my ($self) = @_;

    my @frameset = $self->dom->findnodes("/html/frameset");
    return $frameset[0] if @frameset;
    
    my @body = $self->dom->findnodes("/html/body");
    return $body[0] if @body;
        
    return;
}

sub get_elements_by_tag_name { 
    my ($self, $tag) = @_; 
    $self->find("$tag"); 
}

sub get_element_by_id {
    my ($self, $id) = @_;
    
    my $nodes = $self->find("#${id}");
    return $nodes->get_node(0) if $nodes->size > 0;
    return;
}

sub get_forms {
    my ($self) = @_;
    my @forms = $self->dom->findnodes("//form");
    return Serengeti::Backend::Native::HTMLCollection->new(@forms);
}


sub get_links {
    my ($self) = @_;
    my @links = $self->dom->findnodes('//a[@href] | //area[@href]');
    return Serengeti::Backend::Native::HTMLCollection->new(@links);
}

sub get_anchors {
    my ($self) = @_;
    my @anchors = $self->dom->findnodes('//a[@name] | //area[@name]');
    return Serengeti::Backend::Native::HTMLCollection->new(@anchors);
}

sub get_images {
    my ($self) = @_;
    my @images = $self->dom->findnodes('//img');
    return Serengeti::Backend::Native::HTMLCollection->new(@images);
}

sub get_frames {
    my ($self) = @_;
    my $frameset = $self->get_body;
    
    my @frames = $self->get_body->findnodes(".//frame | .//iframe");
    return Serengeti::Backend::Native::HTMLCollection->new(@frames);    
}

sub DESTROY {
    my $self = shift;
    if ($self->dom) {
        $self->dom->delete;
    }
}

# Move these two to a util class
sub find {
    my ($self, $query) = @_;

    $self = $self->dom if $self->isa(__PACKAGE__);

    # Hm.. as these most likely originates from JS files 
    # which are saved as UTF-8 we downgrade them. But we need a better
    # solution really... like autodetect.
    # Same in find_first
    $query = Encode::decode('UTF-8', $query);

    my $xpath = $query =~ m!^(?:\.?/|id\()! ? $query : "." . HTML::Selector::XPath::Serengeti->new($query)->to_xpath;
    my $nodes = $self->findnodes($xpath);    
                    
    return $nodes;                
}

sub find_first {
    my ($self, $query) = @_;

    $self = $self->dom if $self->isa(__PACKAGE__);
    
    $query = Encode::decode('UTF-8', $query);

    my $xpath = $query =~ m!^(?:\.?/|id\()! ? $query : "." . HTML::Selector::XPath::Serengeti->new($query)->to_xpath;
    my $nodes = $self->findnodes($xpath);    

    if ($nodes->size() > 0) {
        return $nodes->get_node(1);
    }
        
    die "'$query' returned no results";
}

1;
__END__
