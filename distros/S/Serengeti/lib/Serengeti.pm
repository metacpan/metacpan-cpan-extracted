package Serengeti;

use strict;
use warnings;

use Carp qw(croak);
use File::Spec;

use Serengeti::Context;
use Serengeti::NotificationCenter;
use Serengeti::Notifications;
use Serengeti::Session;

our $VERSION = "0.00";

our $DefaultBackend = "Serengeti::Backend::Native";

use accessors::ro qw(context);

sub new {
    my ($pkg, $args) = @_;

    # This is what performs the actual requests and data extracion
    my $backend = $args->{backend} || $DefaultBackend;
    unless ($backend =~ /^Serengeti::Backend::/) {
        $backend = "Serengeti::Backend::${backend}";
    }
    
    my $context = Serengeti::Context->new({
        backend => $backend
    });
    
    my $session_dir = $args->{session_dir} || File::Spec->tmpdir;
    if (-e $session_dir) {
        # Check that it's valid and writeable
    }
    else {
        mkpath($session_dir);
    }
    
    my $self = bless {
        context => $context,
        session_dir => $session_dir,
    }, $pkg;
    
    return $self;
}

sub load {
    my ($self, $file) = @_;
    $self->context->load($file);
}

sub eval {
    my ($self, $source) = @_;
    
    my (undef, $filename, $lineno) = caller;
    $self->context->eval($source, $filename, $lineno);
}

sub perform {
    my ($self, $action, $args) = @_;
    
    unless ($self->context->has_action($action)) {
        croak "Don't know how to perform '$action'";
    }

    return $self->context->invoke_action($action, $args);
}

sub new_session {
    my ($self, $name) = @_;
    
    my $session = Serengeti::Session->new({
        name => $name,
    })
}

sub session {
    my $self = shift;
    return $self->{session} if $self->{session};
    
    $self->{session} = Serengeti::Session->new();
    
    # Notify context we have a new session
    Serengeti::NotificationCenter->post_notification(
        $self,
        NEW_SESSION_NOTIFICATION,
        $self->session,
        $self->context,
    );
    
    return $self->session;
}

sub register_data_request {
    my ($self, $name, $callback) = @_;
    $self->context->register_callback($name => $callback);
}

1;
__END__