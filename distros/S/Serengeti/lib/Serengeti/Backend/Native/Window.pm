package Serengeti::Backend::Native::Window;

use strict;
use warnings;

use Scalar::Util qw(weaken);
use JavaScript;

use accessors::ro qw(backend);

sub setup_jsapi {
    my ($self, $browser, $ctx) = @_;
    
    $ctx->bind_class(
        name => "Window",
        package => __PACKAGE__,
        methods => {
        },
        properties => {
            closed => \&is_closed,
            location => \&get_location,
            frames => \&get_frames,
        },
        flags => JS_CLASS_NO_INSTANCE,
    );

    my $window = $self->new($browser);
    
    $ctx->bind_object(window => $window);

    1;
}

sub new {
    my ($pkg, $backend) = @_;
    
    my $self = bless { backend => $backend, }, $pkg;

    return $self;
}

sub is_closed {
    0;
}

sub get_location {
    my $self = shift;
        
    if ($self->backend->current_document) {
        return $self->backend->current_document->location;
    }
    
    # We should actually throw an error here because our browser
    # should start with a blank document and not an undef document
    return URI->new("about:blank");
}

sub get_frames {
    my $self = shift;

    if ($self->backend->current_document) {
        return $self->backend->current_document->get_frames;
    }
    
    return Serengeti::Backend::Native::HTMLCollection->new();
    
}
1;
__END__