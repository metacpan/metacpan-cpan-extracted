package Plack::Middleware::Pod;
use strict;
use Pod::POM;
use parent qw( Plack::Middleware );
use vars qw($VERSION);
$VERSION = '0.05';

use Plack::Util::Accessor qw(
    path
    root
    pass_through
    pod_view
);

=head1 NAME

Plack::Middleware::Pod - render POD files as HTML

=head1 SYNOPSIS

  enable "Plack::Middleware::Pod",
      path => qr{^/pod/},
      root => './',
      pod_view => 'Pod::POM::View::HTML', # the default
      ;

=cut

sub call {
    my $self = shift;
    my $env  = shift;
    
    my $res = $self->_handle_pod($env);
    if ($res && not ($self->pass_through and $res->[0] == 404)) {
        return $res;
    }

    return $self->app->($env);
}

sub _handle_pod {
    my($self, $env) = @_;
    
    my $path_match = $self->path;

    $path_match or return;
    my $path = $env->{PATH_INFO};

    # We don't allow relative names, just to be sure
    $path =~ s!^(\.\./)+!!g;
    1 while $path =~ s!([^/]+/\.\./)!/!;
    
    # Sorry if you want to use whitespace in pod filenames
    $path =~ m!^[-_./\w\d]+$!
        or return;

    #warn "[$path]";
    #warn "Checking against $path_match";

    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($_, $env) : $_ =~ $path_match;
        return unless $matched;
    }

    my $r = $self->root || './';
    #warn "Stripping '$path_match' from $path, replacing by '$r'";
    $path =~ s!$path_match!$r!;
    #warn "Rendering [$path]";

    if( -f $path) {
        # Render the Pod to HTML
        my $v = $self->pod_view || 'Pod::POM::View::HTML';
        my $pod_viewer = $v;
        # Load the viewer class
        $pod_viewer =~ s!::!/!g;
        require "$pod_viewer.pm"; # will crash if not found
        
        my $pom = Pod::POM->new->parse_file($path);
        
        return [
            200, ["Content-Type" => "text/html"], [$v->print($pom)]
        ];
    } else {
        #warn "[$path] not found";
        return
    }
}

1;

=head1 SECURITY CONSIDERATIONS

This middleware tries to be conservative regarding access to directories outside
of the C<root> directory, but you are advised to not enable this middleware
in a webserver accessible to a wider public. This middleware might allow
leaking data from outside the directory.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/plack-middleware-pod>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Plack-Middleware-Pod>
or via mail to L<plack-middleware-pod-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut