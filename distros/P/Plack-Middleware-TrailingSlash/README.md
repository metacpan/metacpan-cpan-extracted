Plack-Middleware-TrailingSlash
==============================

Redirect to a path containing the trailing slash if the path looks like a directory

The Catalyst Perl MVC framework matches the requested URL to an action both with and without the trailing slash.
For example both /company/contact and /company/contact/ go to the same action and same template.

This module redirects the requests without the trailing slash (ie. /company/contact) to the same URL with the
trailing slash added (ie. /company/contact/).

Advantages:
 * relative links and references work reliably
 * search engines will not see duplicate content

Alternatives:
 * Use <a href="https://developer.mozilla.org/en/docs/HTML/Element/base">&lt;base href&gt;</a> in every
   response.

TODO:
 * Proper usage documentation (perldoc)
 * Publish in CPAN
