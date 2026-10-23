# Data flow

No persistence, queues or outbound calls. Everything is request-scoped and
read from the app's own static files and templates.

## Registration (`register`)

```
plugin WebComponent => {...}
  -> helper name = config.helper // 'component'; return if already registered   (:27-32)
  -> app->defaults(webcomponent.helper => name); app->helper(name => ...)       (:34-36)
  -> build route "<path>/:checksum/*component"; move it first in routes->children (:40-42)
```

## Page render: `component` helper (`_component`)

```
template: %= component 'my-component', {template => ..., requestId => ...}
  -> name gets ".js" appended if missing; croak if not $COMPONENT_NAME    (:164-165)
  -> params = request params + route captures, sorted by name             (:167, :194-201)
  -> opts.template (undef -> 'false') written into params                 (:168-170)
  -> checksum = opts.requestId (croak if it holds "/"; url_escaped), else: (:176-183)
       _content($c, name, params) in eval -> sha1 of the UTF-8 content
       eval failed: warn in the log; no script: checksum = 'unavailable'
  -> path = <base path, trailing "/" dropped, xml_escaped> + route pattern,
            :checksum (requestId is url_escaped) and *component
            replaced, "?<params>" appended                                (:158-189)
  -> returns <script src='path'></script> (Mojo::ByteStream)              (:190-191)
```

The helper renders the template with the page's controller, so each page view
renders each component once here and once more when the script is fetched.

## Script request: route `_serve`

```
GET <path>/:checksum/*component?<params>
  -> component must match $COMPONENT_NAME, else 404                       (:51)
  -> _content($c, component, params from request + captures)              (:53)
       static->file("/<asset_dir>/js/<javascript_path>/<component>"): absent -> undef -> 404
       decode UTF-8 (die if invalid)
       _templateScript: template param: off (false/f/no/0) | named | default
         "<template_path>/<name>" exists (file or DATA, any handler)?
           yes: render_to_string(template, params => \%params)
           no:  "<div>404 - <template> template not found</div>"
         wrap as one to_json string literal in
           `let tmpl = document.createElement('template'); tmpl.innerHTML = "...";`
       copy lines; on the first `let tmpl;` line, replace it with the block;
       on the first `shadowRoot.appendChild(tmpl.content.cloneNode(true))`
       line, emit the block before it
  -> Cache-Control: immutable when :checksum == sha1 of the content, else no-cache (:58-59)
  -> Content-Type application/javascript; charset=UTF-8; render(text => content)   (:62-63)
```

Inputs: the app's static directories, the renderer's templates and handlers,
the request's query params and route captures. Output: the script text as the
response body.
