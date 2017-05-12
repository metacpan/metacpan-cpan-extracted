# Plack::Middleware::XForwardedFor

Plack middleware handler for X-Forwarded-For headers

Using this module early in the plack stack will cause later modules
to see the REMOTE_ADDR the original source when the plack app is
behind a trusted proxy that supports adding X-Forwarded-For headers

This software is copyright (c) 2010 by Graham Barr <gbarr@pobox.com>.
    
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
