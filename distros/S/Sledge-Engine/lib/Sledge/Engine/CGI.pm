package Sledge::Engine::CGI;
use strict;
use base qw(Sledge::Engine);

sub handle_request {
    my $self = shift;
    my $path_info = $ENV{PATH_INFO};
    my $action = $self->lookup($path_info);
    unless ($action) {
        require CGI;
        print "Status: 404 Not Found\r\n";
        print "Cotent-Type: text/html\r\n";
        print "\r\n";
        return;
    }
    my $class = $action->{class};
    $class->require;
    my $pages = $class->new;
    $pages->dispatch($action->{page});
}



1;

__END__
