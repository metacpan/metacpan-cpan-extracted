[![Actions Status](https://github.com/rshingleton/Mojolicious-Plugin-WebComponent/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/rshingleton/Mojolicious-Plugin-WebComponent/actions?workflow=test)
# NAME

Mojolicious::Plugin::WebComponent - An effort to make creating and using custom web components easier

# SYNOPSIS

Web Components is a suite of different technologies allowing you to create reusable custom elements —
with their functionality encapsulated away from the rest of your code — and utilize them in your web apps.
([https://developer.mozilla.org/en-US/docs/Web/API/Web\_components](https://developer.mozilla.org/en-US/docs/Web/API/Web_components). Mdn Web Docs.)

# DESCRIPTION

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

# Example

The following example is a web component that consists of a JavaScript file and an associated template. This example
also uses alpine.js to provide some responsive updates via a recurring update routine.

#### app

The base application is taking advantage of [Mojolicious::Plugin::WebComponent](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebComponent) and [Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAssetPack)

    sub startup($self) {
        $self->renderer->cache->max_keys(0)
            if $self->mode eq 'development';

        $self->plugin(AssetPack => { pipes => [ qw(Sass Css JavaScript Combine Fetch) ] });
        $self->asset->store->paths($self->static->paths);
        $self->plugin(WebComponent => { path => "$path/component" });

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

#### base layout

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

#### index page

In the index page we reference our custom component &lt;system-hosts>. The updates are done in the
[alpine.js](https://alpinejs.dev/) script using a periodic update timer. This could also be done
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

#### /public/assets/js/components/system-hosts.js

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

#### /templates/components/system-hosts.html.ep

This is the template for our custom &lt;system-hosts> web component. In the plugin we also provide any request
parameters in a params hash so that they can be templated by the Mojolicious templating system if present. In
this example, the <%= $params->{system} %> will print out the system name param if available in the controller.

    <div x-data>
        <div :loading="$store.hosts.data.length===0">
            Loading Host Data...
        </div>
        <div x-show="$store.hosts.data.length>0">
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

# CONFIGURATION

    # full mojo app
    my $wc = $self->plugin(WebComponent, \%conf );

    # or mojo lite
    plugin WebComponent => {};

## path

default: /component

The path setting can be used to set the base url for the controller. This is useful for reverse proxy settings or if you
want to modify the controller path. The controller pattern is:

    $path/:checksum/*component

## javascript\_path

default: &lt;app>/&lt;public-dir>/&lt;assets-dir>/js/components

The template\_path setting allows the user to set the directory within the default Mojolicious public location
where the WebComponent script files are located.

## template\_path

default: &lt;app>/&lt;template-dir>/components

The template\_path setting allows the user to set the directory within the default Mojolicious templates location
where the application can locate and process template fragments associated with the WebComponent.

# HELPERS

## component

This component helper is used in a template to generate a script tag for each request. The script tag is associated with
a matching JavaScript file, by default found in public/assets/js/components

    # app/templates/layouts/default_head.html.ep

    <title>
    <%= title %>
    </title>

    %= asset "app.css"
    %= asset "app.js"

    %= component 'my-web-component'

The generated script tag will include a checksum of the script the url serves, the provided component script name, and
parameters from the original request. The checksum is the SHA-1 of the script after its template has been rendered, so
the url stays the same until the script, its template or a parameter changes, and the browser can cache the script. To
compute it the helper renders the template, so each page view renders every component twice. A template whose output
depends on more than the request parameters (the session, the current route) can render differently for the page than
for the script request; its checksum then never matches and the script is served with `Cache-Control: no-cache`.

    # example tag generation
    <script src='/component/3f786850e387550fdab836ed7e6dc881de23001b/my-web-component.js?controller=default&action=index&pathParam1=testPathParam1&queryParam1=testQueryParam'></script>

### Helper Options

#### template

The only parameter currently supported that can be passed to the helper is "template". By default the html template
file associated with the script will match the component name passed to the helper. In this example, my-web-component
maps to the the script file /public/assets/js/components/my-web-component.js and the html template file
/templates/components/my-web-component.html.ep. If you want to use a different template name for some reason, you can
it as a hash entry to the component helper

    %= component 'my-web-component', { template => 'my-special-template' }

This would map my-web-component.js to my-special-template.html.ep. Passing a undef to the template key will cause the
plugin to skip any template processing and assume that the html content is embedded in the JavaScript file already.

#### requestId

Replaces the checksum in the url with the value given, for example a release number. The script is then served with
`Cache-Control: no-cache`, because the url no longer proves what it contains. The value is percent-encoded in the url (as UTF-8), and it cannot contain a slash, because the route could not match it; the helper dies if it does.

    %= component 'my-web-component', { requestId => 'v2' }

# ROUTES

This plugin creates a route to return the WebComponent script to the application. The default route is
/component/:checksum/\*component. The path configuration setting can be passed during initialization to modify the base
path of the controller.

The route is created when the plugin is registered and is moved ahead of the routes the application has already
declared, so a catch-all route cannot hide it. For the same reason, a route of your own under the same path is never
reached. Component names are file names ending in .js, optionally below sub folders (sub/my-component.js); a segment
may not start with a dot. Any other name gets a 404, and the component helper dies when given one.

## /component/:checksum/\*component

This is generated by the component helper and is a script tag associated with the
custom component url. For example, the helper generates &lt;script src='/component/3f786850e387550fdab836ed7e6dc881de23001b/my-component.js'>&lt;/script>.
Navigating to the url, /component/3f786850e387550fdab836ed7e6dc881de23001b/my-component.js, will return the templated
JavaScript component file.

When the checksum in the url matches the script being served, the response carries
`Cache-Control: public, max-age=31536000, immutable`. Any other checksum, for example from a page that was cached
before the script changed, is still answered with the current script, but with `Cache-Control: no-cache`.

A template that prints data of the current user (the session, for example) matches its own checksum, so its script is
sent as `public` like any other. A shared cache in front of the application could then store it. Keep such data out of
component templates, or have the shared cache bypass `/component/`.

Behind a reverse proxy the path the application was told about (the base path of the request URL) is put in front of
the route, without a trailing slash and escaped for use inside the tag.

# METHODS

## register

    $self->register($app, \%config);

Used to register the plugin in the application. `%config` can contain:

- helper

    Name of the helper to add to the application. Default is "component". It must be a plain word (letters, digits and
    underscore); any other name dies.

# SOURCE

[https://github.com/rshingleton/Mojolicious-Plugin-WebComponent](https://github.com/rshingleton/Mojolicious-Plugin-WebComponent)

# SEE ALSO

[Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAssetPack).

# LICENSE

Copyright (C) R.Shingleton.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Russell Shingleton <reshingleton@gmail.com>
