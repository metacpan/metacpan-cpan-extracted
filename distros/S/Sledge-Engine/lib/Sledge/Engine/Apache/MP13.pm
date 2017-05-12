package Sledge::Engine::Apache::MP13;
use strict;
use base qw(Sledge::Engine);
use Apache::Constants qw(:common);
use UNIVERSAL::require;
use Class::Inspector;

sub handle_request {
    my($self, $r) = @_;
    $r ||= Apache->request;
    my $uri = $r->uri;
    my $location = $r->location;
    $location =~ s{/+$}{};
    $uri =~ s/^$location//;
    my $action = $self->lookup($uri);
    unless ($action) {
        return NOT_FOUND;
    }
    my $class = $action->{class};
    unless (Class::Inspector->loaded($class)) {
        $class->require;
    }
    $class->new->dispatch($action->{page});
    return OK;
}



1;

__END__
