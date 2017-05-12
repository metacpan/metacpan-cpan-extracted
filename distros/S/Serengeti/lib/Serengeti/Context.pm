package Serengeti::Context;

use strict;
use warnings;

use File::Basename qw();
use File::Spec;
use JavaScript;
use List::Util qw(first);
use Module::Load qw();
use Scalar::Util qw(blessed);
use Regexp::Common qw(URI);

use Serengeti;
use Serengeti::NotificationCenter;
use Serengeti::Notifications;
use Serengeti::Util qw(trim);

use accessors::ro qw(js_ctx search_paths backend callbacks session windows);

{
    my $JSRuntime;
    sub shared_js_runtime {
        return $JSRuntime if $JSRuntime;
        
        $JSRuntime = JavaScript::Runtime->new();

        return $JSRuntime;
    }
}

sub new {
    my ($pkg, $args) = @_;
    
    my $ctx = shared_js_runtime->create_context();
    
    my $backend = $args->{backend} || $Serengeti::DefaultBackend;
    Module::Load::load $backend;
    
    my $self = bless {
        js_ctx          => $ctx,
        search_paths    => ["."],
        backend         => $backend->new,
        callbacks       => {},
        session         => undef,
    }, $pkg;

    $self->_setup_jsapi();
    
    return $self;
}

sub register_callback {
    my ($self, $name, $callback) = @_;
    
    $self->callbacks->{$name} = $callback;
}

sub _setup_jsapi {
    my $self = shift;
    
    my $ctx = $self->js_ctx;
    
    my $common = {
        include => sub {
            my $path = shift;
        
            # We can actually include remote files which contains
            # stuff that the website needs
            if ($path =~ $RE{URI}{HTTP}) {
                my $response = $self->backend->get($path);
                if ($response->is_success) {
                    $ctx->eval($response->decoded_content);
                    if ($@) {
                        warn $@;
                    }
                }
                
                return;
            }

            $self->load($path);
        },
        gimme => sub {
            my $name = pop;
            #     $self->session->log_action("requested data", @_);
            die "Missing data request name" unless defined $name;
            # Calls a registered perl function to retrieve stuff like
            # passwords which might not want to be sent as args
            my $callback = $self->callbacks->{$name};
            die "Missing callback for '${name}'" unless $callback;
            return $callback->(@_);
        },
        get => sub {
            $self->backend->get(@_); 
        },
        post => sub { 
            $self->backend->post(@_); 
        },
        head => sub { 
            $self->backend->get(@_); 
        },
        log    => sub {
            # This should tell the session object to log an entry
            print STDERR join("", @_), "\n";
        },
        match => \&match,
    };
    
    $self->backend->setup_document_jsapi($self->js_ctx);
    $self->backend->setup_window_jsapi($self->js_ctx);
    
    $ctx->bind_object('$Browser' => $common);

    # Listen to when we get new documents
    Serengeti::NotificationCenter->add_observer(
        $self,
        selector    => "document_changed",
        for         => DOCUMENT_CHANGED_NOTIFICATION,
        from        => $self->backend,
    );
    
    Serengeti::NotificationCenter->add_observer(
        $self, 
        selector    => "session_changed",
        for         => NEW_SESSION_NOTIFICATION, 
    );
    
    Serengeti::NotificationCenter->add_observer(
        $self,
        selector    => "log_session_event",
        for         => SESSION_EVENT_NOTIFICATION,
        from        => $self->backend,
    );
    
    1;
}

sub DESTROY {
    my $self = shift;
    Serengeti::NotificationCenter->remove_observer($self);
}

sub load {
    my ($self, $file) = @_;
    
    my $path;
    my @inc = @{$self->search_paths};

    for my $dir (@inc) {
        my $lp = File::Spec->catfile($dir, $file);
        $path = $lp, last if -e $lp;
    }

    die "Can't find file: $file" unless $path;
        
    my $dirname = File::Basename::dirname($path);
    
    # Temporary add the file's basename to the list of directories to search.
    my $inc = $self->search_paths;
    my @new_inc = @$inc;
    push @new_inc, $dirname unless first { $_ eq $dirname } @new_inc;
    local $self->{search_paths} = \@new_inc;
    
    $self->js_ctx->eval_file($path);
    
    die "$@" if $@;
}

sub has_action {
    my ($self, $action) = @_;

    return $self->js_ctx->can($action);
}

sub invoke_action {
    my ($self, $action, $args, $options) = @_;
    
    $args = {} unless ref $args eq "HASH";
    $options = {} unless ref $args eq "HASH";
    
    return $self->js_ctx->call($action, $args, $options);
}

sub eval {
    my ($self, $source, $filename, $lineno) = @_;
    
    return $self->js_ctx->eval($source, $filename, $lineno);
}

sub session_changed {
    my ($self, $sender, $notification, $data) = @_;

    $self->{session} = $data;
}

sub document_changed {
    my ($self) = @_;
    $self->js_ctx->unbind_value("document");
    $self->js_ctx->bind_object(document => $self->backend->current_document);
    1;
}

sub log_session_event {
    my ($self, $sender, $notification, $data) = @_;
    if ($self->session) {
        my ($action, $event_args) = @{$data}{qw(event data)};
        $event_args = [] unless ref $event_args eq "ARRAY";
        $self->session->log_event($action, @$event_args);
    }
}

sub match {
    my $self = shift;
    
    my $content;
    if (ref $_[0] eq "Regexp") {
        # Default to document.body.innerHTML;
        $content = $self->backend->current_document->get_body->as_HTML;
    }
    else {
        $content = shift;
        if (blessed $content && $content->isa("HTML::Element")) {
            $content = $content->as_HTML;
        }
    }

    my $re = shift;
    $re = qr/$re/ unless ref $re eq "Regexp";
    
    my $options = shift;
    $options = {} unless ref $options eq "HASH";
    
    # Perform matching
    my $matches = 0;

    my $session = $self->session;
    my $stash = $session ? $session->stash : undef;
    
    my @set;
    if (defined $options->{set} && $stash) {
        @set = map trim, split /\s*,\s*/, $options->{set};
        
        delete @{$stash}{@set} if $stash;
    }
    
    my %set;
    while (my @matches = ($content =~ $re)) {
        $content =~ s/$re//;
        $matches++;

        for my $key (@set) {
            my $v = shift @matches;
            if (ref $stash->{$key} eq "ARRAY") {
                push @{$stash->{$key}}, $v;
            }
            elsif (exists $stash->{$key}) {
                $stash->{$key} = [delete $stash->{$key}, $v];
            }
            else {
                $stash->{$key} = $v;
            }
        }
    }
    
    if (exists $options->{strict}) {
        my $expect_matches = $options->{strict} || 0;
        if ($matches != $expect_matches) {
            die "Match matches ", $matches, " time(s) instead of required ",
                ${expect_matches}, " time(s)"; 
        }
    }
    
    return $matches;
}

1;
__END__

=head1 NAME

Serengeti::Context - Provides a space where functions and objects are executed

=cut
