package Mojolicious::Plugin::QooxdooJsonrpc;

use Mojo::Base 'Mojolicious::Plugin';
use File::Spec::Functions qw(splitdir updir catdir file_name_is_absolute);
use Cwd qw(abs_path);

BEGIN {
    warn "Mojolicious::Plugin::QooxdooJsonrpc is DEPRECATED. Please switch to using Mojolicious::Plugin::Qooxdoo.\n" unless $ENV{DISABLE_DEPRECATION_WARNING_MPQ};
}

our $VERSION = '0.96';
# the dispatcher module gets autoloaded, we list it here to
# make sure it is available and compiles at startup time and not
# only on demand.
use MojoX::Dispatcher::Qooxdoo::Jsonrpc;

sub register {
    my ($self, $app, $conf) = @_;

    # Config
    $conf ||= {};
    my $root = ($conf->{prefix} || '') . '/';
    my $services = $conf->{services};
    my $path = $conf->{path} || 'jsonrpc';
    my $r = $app->routes;

    $r->route($root.$path)->to(
        controller  => 'Jsonrpc',
        action      => 'dispatch',
        namespace   => 'MojoX::Dispatcher::Qooxdoo',        
        # our own properties
        services    => $services
    );

    if ($ENV{QX_SRC_MODE}){
        my $qx_app_src = abs_path(
            $ENV{QX_SRC_PATH} && file_name_is_absolute($ENV{QX_SRC_PATH})
            ? $ENV{QX_SRC_PATH} 
            : $app->home->rel_dir($ENV{QX_SRC_PATH} || catdir(updir,'frontend','source'))
        );
        $app->log->info("Runnning in QX_SRC_MODE with files from $qx_app_src");
        $app->static->paths([$qx_app_src]);
        my %prefixCache;
        my $static = Mojolicious::Static->new();
        my $static_cb = sub {
            my $self = shift;
            my $prefix = $self->param('prefix');    
            if ($self->param('file')){
                $self->req->url->path('/'.$prefix.'/'.$self->param('file'));
            }
            if (not defined $prefixCache{$prefix}){
                my $prefix_local = catdir(split /\//, $prefix);
                my $path = $qx_app_src;
                my $last_path = '';
                while ($path ne $last_path and not -d catdir($path,$prefix_local)){
                    $last_path = $path;
                    $path = abs_path(catdir($last_path,updir));
                }
                $app->log->info("Auto register static path mapping from '$prefix' to '$path'");
                $prefixCache{$prefix} = $path;
            } 
            $static->paths([$prefixCache{$prefix}]);

            unless ($static->dispatch($self)){
                $self->render(text=>$self->req->url->path.' not found', status => 404);
            }
        };

        $r->get('/(*prefix)/framework/source/(*a)' => $static_cb );
        $r->get('/(*prefix)/source/class/(*a)' => $static_cb );
        $r->get('/(*prefix)/source/resource/(*a)' => $static_cb );
        $r->get('/(*prefix)/source/script/(*a)' => $static_cb );
        $r->get('/(*prefix)/downloads/(*a)/source/(*b)' => $static_cb );
        $r->get('/source/index.html' => {prefix=>'source'} => $static_cb );
        $r->get('/source/class/(*b)' => {prefix=>'source'} => $static_cb );
        $r->get('/source/resource/(*b)' => {prefix=>'source'} => $static_cb );
        $r->get('/source/script/(*b)' => {prefix=>'source'} => $static_cb );
        $r->get($root.'(*file)' => {prefix => 'source', file => 'index.html' } => $static_cb);
    }
    else {
        $r->get($root.'(*file)' => {file => 'index.html' } => sub {
             my $self = shift;
             my $file = $self->param('file');
             $self->req->url->path('/'.$file);
             return $app->static->dispatch($self);
        });
     }
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::QooxdooJsonrpc - handle qooxdoo Jsonrpc requests

=head1 SYNOPSIS

THIS MODULE IS DEPRECATED. USE L<Mojolicious::Plugin::Qooxdoo> INSTEAD.

 # lib/your-application.pm

 use base 'Mojolicious';
 use RpcService;
 
 sub startup {
    my $self = shift;
       
    $self->plugin('qooxdoo_json_rpc',{
        prefix => '/',
        path => 'jsonrpc',
        services => {
            Test => RpcService->new(),
        },
    });
 }


=head1 DESCRIPTION

This plugin installs the L<MojoX::Dispatcher::Qooxdoo::Jsonrpc> dispatcher
into your application. The result of your build run is expected in the
F<public/> directory of your mojo app.

See the documentation on L<MojoX::Dispatcher::Qooxdoo::Jsonrpc>
for details on how to write your service. 

The plugin understands the following parameters.

=over

=item B<prefix> 

By default the plugin will add its routes starting at the root F</> by setting a prefix
you can move them down the tree.

=item B<services> (mandatory)

A pointer to a hash of service instances. See L<MojoX::Dispatcher::Qooxdoo::Jsonrpc> for details on how
to write a service.

=item B<path> (default: jsonrpc)

If your application expects the JsonRPC service to appear under a different url.

=back

=head2 Source Mode

While developing your qooxdoo application it is handy to run its souce
version. Normally this is done directly from the file system, but in that
mode your application will not be able to call back to the server with POST requests.

This module provides a qooxdoo B<source> mode where it will serve the source
version of your application. Set the C<QX_SRC_MODE> environment variable to
"1" to activate the source mode. By default, the module expects to find the
source of your application in F<MOJO_HOME/../frontend/source> if you keep
the source somewhere else you can set the alternate location via
C<QX_SRC_PATH> either absolute or relative to the MOJO_HOME directory.



In production mode, the plugin expects to find the result of your
C<generate.py build> run in mojos F<public> directory. 



=head1 AUTHOR

S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>

=head1 COPYRIGHT

Copyright OETIKER+PARTNER AG 2010

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
