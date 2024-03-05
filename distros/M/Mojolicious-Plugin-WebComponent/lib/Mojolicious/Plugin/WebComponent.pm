package Mojolicious::Plugin::WebComponent;
use v5.20;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Carp;
use Data::Dumper;

our $VERSION = "0.06";

sub register($self, $app, $conf) {

    my $assetDir = $app->static->asset_dir;
    my $javascriptPath = "/$assetDir/js/components";
    my $templatePath = "components";
    my $path = "/component/:req/*component";

    if (defined($conf)) {
        # remove trailing slashes
        $conf->{javascript_path} = $1 if (defined($conf->{javascript_path}) && $conf->{javascript_path} =~ /(.*)\/$/);
        $conf->{template_path} = $1 if (defined($conf->{template_path}) && $conf->{template_path} =~ /(.*)\/$/);
        $conf->{path} = $1 if (defined($conf->{path}) && $conf->{path} =~ /(.*)\/$/);
        $javascriptPath = $conf->{javascript_path} if $conf->{javascript_path};
        $templatePath = $conf->{template_path} if $conf->{template_path};
        $path = "$conf->{path}/:req/*component" if $conf->{path};
    }

    $app->helper(component => sub {_component($self, $path, @_)});
    $app->routes->get($path)->to(cb => sub {
        my $c = shift;
        my $component = $c->param('component');
        my $params = $self->_getAllParams($c)->to_hash;

        my $templateFile;
        my $skipTemplate;
        if (exists($params->{template})) {
            my $template = $params->{template};
            if ($template =~ m/(false|f|no|0)/i || !defined($template)) {
                $skipTemplate = 1;
            }
            else {
                $templateFile = $template;
            }
        }

        my $tmpl;
        if (!defined($skipTemplate)) {
            my $tmplHtml;
            # if the template file is not set,
            $templateFile //= $component =~ s/\.js//gr;
            my $template = "$templatePath/$templateFile";
            if ($app->renderer->{templates}->{"$template.html"}) {
                $tmplHtml = $c->render_to_string($template, params => $params);
            }

            # If the template file was not found, show it
            $tmplHtml //= "<div>404 -  $template template not found</div>";

            $tmpl = qq{
                    let tmpl = document.createElement('template');
                    tmpl.innerHTML = `$tmplHtml`
            };
        }

        # my $publicPath = $app->static->{paths}->[0];
        my $js = "$javascriptPath/$component";
        my $asset = $app->static->file($js);

        my $content;
        my $fh = $asset->handle;
        my $tmplInit = 0;
        while (<$fh>) {
            if ($tmpl && !$tmplInit) {
                if ($_ =~ m/let tmpl;/) {
                    $content .= $tmpl;
                    $tmplInit = 1;
                    next;
                }
                if ($_ =~ m/shadowRoot.appendChild\(tmpl.content.cloneNode\(true\)\)/) {
                    $content .= $tmpl;
                    $tmplInit = 1;
                }
            }

            $content .= $_;
        }

        $c->render(text => $content);
    });
}

sub _component {
    my $self = shift;
    my $path = shift;
    my $c = shift;
    my $name = shift;
    my $opts = shift;

    if (exists($opts->{template})) {
        my $template = defined($opts->{template}) ? $opts->{template} : 'false';
        $c->req->params->merge(template => $template);
    }

    my $params = $self->_getAllParams($c);
    my $paramString = $params->to_string;
    my $reqId = $opts->{requestId} || $c->req->request_id;

    $name .= ".js" if $name !~ m/\.js$/;

    # :req/:component
    $path =~ s/:req/$reqId/;
    $path =~ s/\*component/$name/;
    $path .= "?$paramString" if length($paramString);
    my $ref = "<script src='$path'></script>";

    return Mojo::ByteStream->new($ref)
}

sub _getAllParams($self, $c) {
    my $rp = $c->req->params->to_hash;
    %{$rp} = (%{$rp}, %{$c->stash->{'mojo.captures'}}) if $c->stash->{'mojo.captures'};
    my $params = Mojo::Parameters->new(%{$rp});
    delete $params->{cb}; # remove the callback routine
    return $params;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::WebComponent - An effort to make creating and using custom web components easier

=head1 SYNOPSIS

Web Components is a suite of different technologies allowing you to create reusable custom elements —
with their functionality encapsulated away from the rest of your code — and utilize them in your web apps.
(L<https://developer.mozilla.org/en-US/docs/Web/API/Web_components>. Mdn Web Docs.)

=head1 DESCRIPTION

Web Components can be useful in building small, reusable components in a web application. This plugin is an effort to
make developing web components in Mojolicious a little easier. It facilitates the development of scripts and
Mojolicious html templates to provide custom components that can also be templated using Mojolicious templating
features. In doing this we can combine some server side rendering and dynamic rendering.

This plugin provides an easier way to inject Mojolicious templates into custom web component scripts. By using the
component helper, the scripts and templates are tied together in the WebComponent controller before being sent to the
rendered web page.


In a Mojo App

    my $wc = $self->plugin(WebComponent, {});

In a Mojo Lite App

    plugin WebComponent => {};

In the HTML head

    # in the html header
    %= component 'my-component'

Minimal component script implementation, /assets/js/components/my-component.js

    class MyComponent extends HTMLElement {
      constructor() {
        super();
      }
      // let tmpl can be defined here inline or provided in an HTML template
      // of the same name as the script file
      let tmpl;
    }
    customElements.define("my-component", MyComponent);

HTML template association, /templates/components/my-component.html.ep

    <div>
        <div>This is a custom web component</div>
        <div id="message"></div>
    </div>


=head1 Example

The following example is a web component that consists of a JavaScript file and an associated template. This example
also uses alpine.js to provide some responsive updates via a recurring update routine.

=head4 app

The base application is taking advantage of L<Mojolicious::Plugin::WebComponent> and L<Mojolicious::Plugin::AssetPack>

    sub startup($self) {
        $self->renderer->cache->max_keys(0)
            if $self->mode eq 'development';

        $self->plugin(AssetPack => { pipes => [ qw(Sass Css JavaScript Combine Fetch) ] });
        $self->asset->store->paths($self->static->paths);
        $self->plugin(WebCojsDeferredmponent => { path => "$path/component" });

        my @css =(
            "https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap.min.css",
            "assets/scss/main.scss"
        );
        my @js =(
            "https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/js/bootstrap.min.js",
            "assets/js/main.js"
        );
         my @jsDeferred =(
            "https://cdnjs.cloudflare.com/ajax/libs/alpinejs/3.13.5/cdn.min.js"
        );

        $self->asset->process("app.css" => @css);
        $self->asset->process("deferred.js" => @jsDeferred);
        $self->asset->process("app.js" => @js);

        # Router
        my $r = $self->routes;

        # default route to controller
        $r->any('/')->to('default#index')->name('index');

    }

=head4 base layout

    <!DOCTYPE html>
    <html lang="">
        <head>
            <title>
                <%= title %>
            </title>

            %= asset "app.css"
            %= asset "deferred.js", defer => undef
            %= asset "app.js"

            %= component 'system-hosts'
        </head>
        <body>
            <div class="h-100">
                <main>
                    <div class="flex flex-column flex-fill">
                        <div class="container-fluid">
                            <!--CONTENT-->
                        <%= content %>
                        </div>
                    </div>
                </main>
            </div>
        </body>
    </html>


=head4 index page

In the index page we reference our custom component <system-hosts>. The updates are done in the
L<alpine.js|https://alpinejs.dev/> script using a periodic update timer. This could also be done
with websockets, long polling using axios, or other ajax methods with periodic interval updates.

    % layout 'default';
    % title 'Welcome';

    <div id="dashboard">
        <system-hosts></system-hosts>
    </div>

    <script>
        document.addEventListener('alpine:init', () => {
            Alpine.store('hosts', {
                data: [],
                init() {
                   setInterval(() => {
                        let statuses = [
                            {Status: 'up', Color: 'green', Message: 'ok'},
                            {Status: 'down', Color: 'red', Message: 'something is wrong'},
                            {Status: 'unknown', Color: 'gray', Message: 'unknown'},
                        ];
                        let hosts = [
                            'host1',
                            'host2',
                            'host3',
                        ]
                        let update = {data: []};
                        hosts.forEach(h => {
                            let rnd = Math.floor(Math.random() * statuses.length);
                            let status = structuredClone(statuses[rnd]);
                            status.HostName = h;
                            update.data.push(status)
                        })
                        Alpine.store('hosts', update);
                    }, 10000);
                }
            });
        })
    </script>

=head4 /public/assets/js/components/system-hosts.js

Templates processing is handled in the WebComponents controller. By default, the associated
html template will be processed by Mojolicious and then injected into the JavaScript replacing
the "let tmpl;" with the processed html template structure.

    // Extend generic HTMLElement interface
    class SystemHosts extends HTMLElement {
        constructor() {
            super();
            const shadowRoot = this.attachShadow({mode: 'open'});
            // tmpl variable is generated server side if not provided as a local variable
            // the tmpl variable will be replaced server side by the Mojolicious WebComponent
            // plugin
            let tmpl;
            shadowRoot.appendChild(tmpl.content.cloneNode(true));
        }

        connectedCallback() {
            const {shadowRoot} = this;
            // here we attach alpine to the component dom
            document.addEventListener("alpine:initialized",()=>{
                Alpine.initTree(this.shadowRoot)
            })
        }
    }

    // the define call is where our component gets exported so we can use a <system-hosts /> element
    customElements.define('system-hosts', SystemHosts);

=head4 /templates/components/system-hosts.html.ep

This is the template for our custom <system-hosts> web component. In the plugin we also provide any request
parameters in a params hash so that they can be templated by the Mojolicious templating system if present. In
this example, the <%= $params->{system} %> will print out the system name param if available in the controller.

    <div x-data>
        <div :loading="$store.hosts.data.length===0">
            Loading Host Data...
        </ldiv>
        <div x-show="$store.systems.data.length>0">
        <%= $params->{system} %> HOSTS: <span x-text="$store.hosts.data.length"></span>
            <table class="table table-borderless table-sm m-2">
                <tbody>
                <template x-for="item in $store.hosts.data">
                    <tr>
                        <td x-text="item.Status" :title="item.Message"></td>
                        <td x-text="item.HostName"></td>
                    </tr>
                </template>
                </tbody>
            </table>
        </div>
    </div>


=head1 CONFIGURATION

    # full mojo app
    my $wc = $self->plugin(WebComponent, \%conf );

    # or mojo lite
    plugin WebComponent => {};

=head2 path

default: /component

The path setting can be used to set the base url for the controller. This is useful for reverse proxy settings or if you
want to modify the controller path. The controller pattern is:

    $path/:req/*component

=head2 javascript_path

default: <app>/<public-dir>/<assets-dir>/js/components

The template_path setting allows the user to set the directory within the default Mojolicious public location
where the WebComponent script files are located.

=head2 template_path

default: <app>/<template-dir>/components

The template_path setting allows the user to set the directory within the default Mojolicious templates location
where the application can locate and process template fragments associated with the WebComponent.

=head1 HELPERS

=head2 component

This component helper is used in a template to generate a script tag for each request. The script tag is associated with
a matching JavaScript file, by default found in public/assets/js/components

    # app/templates/layouts/default_head.html.ep

    <title>
    <%= title %>
    </title>

    %= asset "app.css"
    %= asset "app.js"

    %= component 'my-web-component'

The generated script tag will include a reference to the original request ID, the provided component script name, and
parameters from the original request.


    # example tag generation
    <script src='/component/a8YekaIml2CJ/my-web-component.js?controller=default&action=index&pathParam1=testPathParam1&queryParam1=testQueryParam'></script>

=head3 Helper Options

=head4 template

The only parameter currently supported that can be passed to the helper is "template". By default the html template
file associated with the script will match the component name passed to the helper. In this example, my-web-component
maps to the the script file /public/assets/js/components/my-web-component.js and the html template file
/templates/components/my-web-component.html.ep. If you want to use a different template name for some reason, you can
it as a hash entry to the component helper

    %= component 'my-web-component', { template => 'my-special-template' }

This would map my-web-component.js to my-special-template.html.ep. Passing a undef to the template key will cause the
plugin to skip any template processing and assume that the html content is embedded in the JavaScript file already.

=head1 ROUTES

This plugin creates a route to return the WebComponent script to the application. The default route is
/component/:reqId/*component. The path configuration setting can be passed during initialization to modify the base
path of the controller.

=head2 /component/:reqId/*component

This is generated by the component helper and is a script tag associated with the
custom component url. For example, the helper generates <script src='/component/kbB7s76PmaY9/my-component.js'></script>.
Navigating to the url, /component/kbB7s76PmaY9/my-component.js, will return the templated JavaScript component file.

=head1 METHODS

=head2 register

  $self->register($app, \%config);

Used to register the plugin in the application. C<%config> can contain:

=over 2

=item * helper

Name of the helper to add to the application. Default is "component".

=back

=head1 SOURCE

L<https://github.com/rshingleton/Mojolicious-Plugin-WebComponent>

=head1 SEE ALSO

L<Mojolicious::Plugin::AssetPack>.


=head1 LICENSE

Copyright (C) R.Shingleton.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Russell Shingleton E<lt>reshingleton@gmail.comE<gt>

=cut

