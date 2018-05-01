package Mojolicious::Plugin::Qooxdoo;

use Mojo::Base 'Mojolicious::Plugin';
use File::Spec::Functions qw(splitdir updir catdir file_name_is_absolute);
use Cwd qw(abs_path);

our $VERSION = '0.908';

sub register {
    my ($self, $app, $conf) = @_;

    # Config
    $conf ||= {};
    my $root = ($conf->{prefix} || '') . '/';
    my $path = $conf->{path} || 'jsonrpc';
    my $r = $app->routes;

    if ($conf->{controller}){
        $r->route($root.$path)->to(
            controller  => $conf->{controller},
            action      => 'dispatch',
            $conf->{namespace} ? ( namespace   => $conf->{namespace}):(),
        );
    }    

    if ($ENV{QX_SRC_MODE}){
        my $qx_app_src = abs_path(
            $ENV{QX_SRC_PATH} && file_name_is_absolute($ENV{QX_SRC_PATH})
            ? $ENV{QX_SRC_PATH} 
            : $app->home->rel_file($ENV{QX_SRC_PATH} || catdir(updir,'frontend','source'))
        );
        $app->log->info("Runnning in QX_SRC_MODE with files from $qx_app_src");
        unshift @{$app->static->paths}, $qx_app_src;
        my %prefixCache;
        my $static = Mojolicious::Static->new();
        my $static_cb = sub {
            my $ctrl = shift;
            my $prefix = $ctrl->param('prefix');    
            if ($ctrl->param('file')){
                $ctrl->req->url->path('/'.$prefix.'/'.$ctrl->param('file'));
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

            unless ($static->dispatch($ctrl)){
                $ctrl->render(text=>$ctrl->req->url->path.' not found', status => 404);
            }
        };

        $r->get('/*prefix/framework/source/*a' => $static_cb );
        $r->get('/*prefix/source/class/*a' => $static_cb );
        $r->get('/*prefix/source/resource/*a' => $static_cb );
        $r->get('/*prefix/source/script/*a' => $static_cb );
        $r->get('/*prefix/downloads/*a/source/*b' => $static_cb );
        $r->get('/source/index.html' => {prefix=>'source'} => $static_cb );
        $r->get('/source/class/*b' => {prefix=>'source'} => $static_cb );
        $r->get('/source/resource/*b' => {prefix=>'source'} => $static_cb );
        $r->get('/source/script/*b' => {prefix=>'source'} => $static_cb );
        $r->get($root.'*file' => {prefix => 'source', file => 'index.html' } => $static_cb);
    }
    else {
        # redirect root to index.html
        $r->any('/' => sub { shift->reply->static('index.html')});
        if ($root ne '/'){
            $app->hook(before_dispatch => sub {
                my $self = shift;
                my $file = $self->req->url->path->to_string;
                if ($file =~ s{^$root/*}{} and -r $app->home->rel_file('public/'.$file)){
                    $self->req->url->path('/'.$file);
                    return $app->static->dispatch($self);
                }
           });
        }
    }
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::Qooxdoo - System for writing Qooxdoo backend code with Mojolicious

=head1 SYNOPSIS

 # lib/your-application.pm

 use Mojo::Base 'Mojolicious';
 use MyJsonRpcController;
 
 sub startup {
    my $self = shift;
       
    $self->plugin('qooxdoo',{
        prefix => '/',
        path => 'jsonrpc',
        controller => 'my_json_rpc_conroller'
    });
 }


=head1 DESCRIPTION

To deal with incoming JSON-RPC requests, write a controller using L<Mojolicious::Plugin::Qooxdoo::JsonRpcController>
as a parent, instead of the normal L<Mojolicious::Controller> class.

See the documentation in L<Mojolicious::Plugin::Qooxdoo::JsonRpcController>
for details on how to write a qooxdoo json rpc controller. 

The plugin understands the following parameters.

=over

=item B<prefix> 

By default the plugin will add its routes starting at the root F</> by setting a prefix
you can move them down the tree.

=item B<controller>

The name of your RpcService controller class. See L<Mojolicious::Plugin::Qooxdoo::JsonRpcController> for details on how
to write a service. If no controller argument is specified, the plugin will only install the routes
necessary to server the qooxdoo javascript files and assets.

=item B<namespace>

If your controller class does not reside in the the application namespace.

=item B<path> (default: jsonrpc)

If your application expects the JSON-RPC service to appear under a different url.

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
C<QX_SRC_PATH> either absolute or relative to the C<MOJO_HOME> directory.

In production mode, the plugin expects to find the result of your
C<generate.py build> run in mojos F<public> directory. 

=head1 AUTHOR

S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>

=head1 COPYRIGHT

Copyright OETIKER+PARTNER AG 2013

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
