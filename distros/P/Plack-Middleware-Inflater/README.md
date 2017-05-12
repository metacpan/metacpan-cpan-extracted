# Plack-Middleware-Inflater

This PSGI middleware inflates incoming gzipped requests before they
hit your PSGI app.  This only happens whenever the request's
`Content-Encoding` header is one of the values specified in the
`content_encoding` attribute, which defaults to `['gzip']`.
