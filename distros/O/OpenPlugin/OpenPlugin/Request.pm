package OpenPlugin::Request;

# $Id: Request.pm,v 1.7 2003/04/28 17:43:49 andreychek Exp $

use strict;
use base qw( OpenPlugin::Plugin );

$OpenPlugin::Request::VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

sub OP   { return $_[0]->{_m}{OP} }
sub type { return 'request' }

sub object { };
sub uri    { };


1;

__END__

=pod

=head1 NAME

OpenPlugin::Request - Retrieve values related to the client request

=head1 SYNOPSIS

 my $r = shift;
 $OP = OpenPlugin->new( request => { apache => $r });

 ...

 my $req_obj = $OP->request->object;
 my $uri     = $OP->request->uri;

=head1 DESCRIPTION

The Request plugin offers an interface to retrieve various pieces of
information available regarding the client request.

If you're looking for methods to work with L<params|OpenPlugin::Param>,
L<cookies|OpenPlugin::Cookie>, L<headers|OpenPlugin::HttpHeader>, or
L<uploads|OpenPlugin::Upload>, so those respective plugins.

This plugin acts as somewhat of a superclass of those plugins, and offers you
access to the request object, along with a variety of other methods.

=head1 METHODS

B<object()>

Returns the request object.

B<uri()>

Returns the uri for the last request.

=head1 BUGS

None known.

=head1 TO DO

The interface provided by the Request/Cookie/Httpheader/Param/Upload plugins,
is, as you know, meant to abstract the existing CGI and mod_perl interfaces
(along with any other drivers that may, at one day, be created).  The interface
provided here is certainly not complete.  What other functionality should we
provide here?

Making the developer access the request object breaks the abstraction
OpenPlugin provides.  The more accessor functions we provide, the better, it
would seem.

Another thing we are doing now is allowing, say, the httpheader plugin to use
the CGI driver, and the param plugin the Apache driver.  Is this useful?  Some
things could be made simpler both internally and externally if we eliminate
that possibility, and have httpheader/param/cookie/upload all automatically use
the same driver.

As an alias for get_incoming/set_incoming, we provide get/set.  There are some
who also might like a method called C<incoming>, that acts differently
depending on if parameters were passed in or not.  OTOH, having too many
different interfaces may just confuse the matter.

I'm also considering providing a mechanism for retrieving a tied hash.  Instead
of using the above interface, you would just add or remove items from the tied
hash.  Very similar to Apache::Table.

It would be neat to have more drivers.  How about a L<POE> driver?
L<CGI::Request>, L<CGI::Base>, L<CGI::MiniSvr>, and others would also be neat.

There are Param and HttpHeader drivers for mod_perl 2.x.  The Cookie and Upload
drivers don't exist yet, hopefully they will soon.  Feel free to contribute
them :-)

=head1 SEE ALSO

See the individual driver documentation for settings and parameters specific to
that driver.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
