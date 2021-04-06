package Mojolicious::Plugin::Tables;
use Mojo::Base 'Mojolicious::Plugin';

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

use Mojolicious::Plugin::Tables::Model;

our $VERSION = '1.06';

sub register {
    my ($self, $app, $conf) = @_;

    my $log = $app->log;

    $app->helper(add_stash => sub {
        my ($c, $slot, $val) = @_;
        push @{$c->stash->{$slot} ||= []}, $val;
    });

    $app->helper(add_flash => sub {
        my ($c, $slot, $val) = @_;
        push @{$c->session->{new_flash}{$slot} ||= []}, $val;
    });

    $app->helper(shipped => sub {
        # special stash slot for sending json-able structs to js;
        # get/set logic here cloned from Mojo::Util::_stash.
        my $c = shift;
        my $shipped = $c->stash->{shipped} ||= {};
        return $shipped unless @_;
        return $shipped->{$_[0]} unless @_>1 || ref $_[0];
        my $values = ref $_[0]? $_[0] : {@_};
        @$shipped{keys %$values} = values %$values;
    });

    $app->config(default_theme=>'redmond');
    $app->defaults(layout => $conf->{layout} || 'tables');

    my $model_class = $conf->{model_class} ||= 'Mojolicious::Plugin::Tables::Model';
    eval "require $model_class" or die;

    $model_class->log($log);
    my $schema = $model_class->setup($conf);
    my $model = $schema->model;
    $app->config(model=>$model);

    $app->hook(before_dispatch => sub {
        my $c = shift;
        # Move first part and slash from path to base path when deployed under a path
        if ($c->req->headers->to_string =~ /X-Forwarded/) {
            my $part0 = shift @{$c->req->url->path->leading_slash(0)};
            push @{$c->req->url->base->path->trailing_slash(0)}, $part0;
            $c->shipped(urlbase => $c->req->url->base);
        } else {
            $c->shipped(urlbase => '');
        }
        # capture https into base
        if ($c->req->headers->header('X-Forwarded-HTTPS')
        || ($c->req->headers->header('X-Forwarded-Proto')||'') eq 'https') {
            $c->req->url->base->scheme('https')
        }
    });
 
    my $plugin_resources = catdir dirname(__FILE__), 'Tables', 'resources';
    push @{$app->routes->namespaces}, 'Mojolicious::Plugin::Tables::Controller';
    push @{$app->renderer->paths}, catdir($plugin_resources, 'templates');
    push @{$app->static->paths},   catdir($plugin_resources, 'public');

    # Arrange for custom table-specific template overrides, when present.
    # We do this by wrapping the standard ep-handler with a
    # pre-processor to test for existence of the custom template.
    # Any internal caching by EP renderer is preserved even for overrides.

    my $handlers = $app->renderer->handlers;
    my $base_ep  = $handlers->{ep};
    $handlers->{ep} = sub {
        my ($renderer, $c, $output, $options) = @_;
        {
            my $table           = $c->stash('table') || last;
            my $custom_template = "$table/$options->{template}";
            my $custom_path     = $renderer->template_path ({%$options,
                                             template=>$custom_template}) || last;
            $options->{template} = $custom_template;
            $log->debug("custom 'tables' template at $custom_path") if $ENV{TABLES_DEBUG};
        }
        $base_ep->(@_)
    };

    my $r = $app->routes;
    $r->get('/' => sub{shift->redirect_to('tables')}) unless $conf->{nohome};

    my @crud_gets  = (qw/view edit del nuke navigate/);
    my @crud_posts = (qw/save/);
    my $fmts       = [format=>[qw/html json/]];

    for ($r->under('tables')                          ->to('auth#ok'   )) {
        for ($_->under()                              ->to('tables#ok' )) {
            $_->get                                   ->to('#page'     );
            for ($_->under(':table')                  ->to('#table_ok' )) {
                $_->any('/'=>$fmts)                   ->to('#table', format=>'html' );
                $_->get('add')                        ->to('#add'      );
                $_->post('save')                      ->to('#save'     );
                for ($_->under(':id')                 ->to('#id_ok'    )) {
                    my $r = $_;
                    $r->get( $_=>$fmts)               ->to("#$_", format=>'html') for @crud_gets;
                    $r->post($_=>$fmts)               ->to("#$_", format=>'html') for @crud_posts;
                    $r->get('add_child/:child'=>$fmts)->to('#view', format=>'html'     );
                    $r->any(':children'=>$fmts)       ->to('#children', format=>'html' );
                }
            }
        }
    }

    my @tablist = @{$model->{tablist}};
    $log->info ("'Tables' Framework enabled.");
    $log->debug("Route namespaces are..");
    $log->debug("--> $_") for @{$app->routes->namespaces};
    $log->debug("Renderer paths are..");
    $log->debug("--> $_") for @{$app->renderer->paths};
    $log->debug("Static paths are..");
    $log->debug("--> $_") for @{$app->static->paths};
    $log->info ("/tables routes are in place. ".scalar(@tablist)." tables available");
    $log->debug("--> $_") for @tablist;

    $log->debug($app->dumper($model)) if $ENV{TABLES_DEBUG};

}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Tables -- Quickstart and grow a Tables-Maintenance application

=head1 SYNOPSIS

    # in a new Mojolicious app..
 
    $app->plugin( Tables => {connect_info=>['dbi:Pg:dbname="mydatabase"', 'uid', 'pwd']} );

    # when ready to grow..

    $app->plugin( Tables => {model_class => 'StuffDB'} );

=head1 DESCRIPTION

L<Mojolicious::Plugin::Tables> is a L<Mojolicious> plugin which helps you grow a high-featured web app by
starting with basic table / relationship maintenance and growing by overriding default behaviours.

By supplying 'connect_info' (DBI-standard connect parameters) you get a presentable database maintenance
web app, featuring full server-side support for paged lists of large tables using
'Datatables' (datatables.net), plus ajax handling for browsing 1-many relationships, plus
JQueryUI-styled select lists for editing many-to-1 picklists.

By supplying your own Model Class you can override most of the default behaviours
and build an enterprise-ready rdbms-based web app.

By supplying your own templates for context-specific calls you can start to give your app a truly 
specialised look and feel.

=head1 STATUS

This is an early release.  Guides and more override-hooks coming Real Soon Now.

=head1 GROWTH PATH

=head2 Ground Zero Startup

    tables dbi-connect-params..

The 'tables' script is supplied with this distribution.  Give it standard DBI-compatible parameters on the 
commandline and it will run a minimal web-server at localhost:3000 to allow maintenance on the named database.

=head2 Day One

In your Mojolicious 'startup'..

    $self->plugin(Tables => { connect_info => [ connect-param, connect-param, .. ] };

Add this line to a new Mojolicious app then run it using any Mojo-based server (morbo, prefork, hypnotoad..) to achieve exactly the same functionality as the 'tables' script.

=head2 Day Two

    # templates/:table/{view,edit,dml,page}.html.ep
    # e.g. 
    # templates/artist/view.html.ep
    <h1>Artist: <%= $row %></h1>

For any :table in your database, create override-templates as required.
e.g. The above code will give a very different look-and-feel when viewing a single Artist, but all other
pages are unchanged.  For better examples and to see which stash-variables are available, start by 
copying the distribution templates from ../Plugin/Tables/resources/templates into your own template area.

=head2 Infinity and Beyond

    $self->plugin(Tables => { model_class => 'MyDB' } );

Prepare your own model_class to override the default database settings which "Tables" has determined from the 
database.  This class (and its per-table descendants) can be within or without your Mojolicious application.
C<model_class> implements the specification given in L<Mojolicious::Plugin::Tables::Model>.
This lets you start to customise and grow your web app.

=head1 CONFIGURATION

    $app->plugin(Tables => $conf) 

Where the full list of configuration options is:

=head3 layout

Provide an alternative 'wrapper' layout; typically the one from your own application.  If you prepare one of these you will need
to include most of the layout arrangements in the Day-One layout, i.e. the one at resources/templates/layouts/tables.html.ep.
The easiest approach is to start by copying the packaged version into your own application and then change its look and feel to
suit your requirements.

=head3 nohome

Unless you supply a true value for this, an automatic redirection will be in place from the root of your app to the '/tables' path.
The redirection is there to make day-one functionality easy to find, but once your app grows you will not want this redirection.

=head3 model_class

See 'Customising Model Class'

=head3 connect_info

See 'Day One'

=head3 default_theme

To experiment with completely different colour themes, choose any standard JQueryUI theme name or "roll" your own as described here 
L<http://jqueryui.com/themeroller/>.   Our default is 'Redmond'.

=head1 DEBUGGING

To generate detailed trace info into the server log, export TABLES_DEBUG=1.

=head1 CAVEAT

We use dynamically-generated DBIx::Class classes.  This technique does not scale well for very large numbers
of tables.  Previous (private) incarnations of this Framework used specially prepared high-performance versions of 
Class::DBI::Loader to speed this up.  So that speeding-up at start-time is a TODO for this DBIx::Class-based release.

=head1 SOURCE and ISSUES REPOSITORY

Open-Sourced at Github: L<https://github.com/frank-carnovale/Mojolicious-Plugin-Tables>.  Please use the Issues register there.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, Frank Carnovale <frankc@cpan.org>

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<DBIx::Class::Schema::Loader>, L<Mojolicious::Plugin::Tables::Model>

=cut
