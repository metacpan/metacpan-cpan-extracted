# README

Plack::Middleware::Reproxy emulates X-Reproxy-URL -- namely, when your PSGI
app responds with that header, the middleware fetches the given URL, and then
uses the response from there as the final response to the client.

This module was developed for TESTING. In production environments, use a
real solution like mod_reproxy or nginx.
