=head1 NAME

OpenFrame::WebApp - OpenFrame tools for web applications.

=head1 SYNOPSIS

  use OpenFrame::WebApp;

  # read rest of documentation

=cut

package OpenFrame::WebApp;

use strict;
use warnings::register;

use base qw ( OpenFrame::Object );

our $VERSION = 0.04;

# load basic objects
use OpenFrame::WebApp::User;
use OpenFrame::WebApp::User::Factory;

use OpenFrame::WebApp::Session;
use OpenFrame::WebApp::Session::Factory;

use OpenFrame::WebApp::Template;
use OpenFrame::WebApp::Template::Factory;

# load basic segments
use OpenFrame::WebApp::Segment::User::Loader;
use OpenFrame::WebApp::Segment::User::EnvLoader;
use OpenFrame::WebApp::Segment::User::RequestLoader;
use OpenFrame::WebApp::Segment::User::SaveInSession;

use OpenFrame::WebApp::Segment::Session::Loader;
use OpenFrame::WebApp::Segment::Session::CookieLoader;

use OpenFrame::WebApp::Segment::Template::Loader;

# load decliner segments
use OpenFrame::WebApp::Segment::Decline::UserInStore;
use OpenFrame::WebApp::Segment::Decline::UserInSession;

use OpenFrame::WebApp::Segment::Decline::SessionInStore;

use OpenFrame::WebApp::Segment::Decline::TemplateInStore;


1;

__END__

=head1 DESCRIPTION

C<OpenFrame::WebApp> is a Web Application toolkit for OpenFrame.  It is
based on the idea of C<OpenFrame::AppKit>, but was designed to be more
comprehensive.

The overall goals of the project is give you re-usable tools, but not tie you
into doing things in only one way.  So the tools are generic and extensible,
and their inter-dependencies are minimal.  Which means you can pick and choose
which parts of the toolkit you want to use.

=head1 OBJECTS AND SEGMENTS

WebApp classes are broken down into 2 categories - I<regular objects> and
I<pipeline segments>.  If you're writing an MVC style application, the objects
would be part of the Model, and the segments would be part of the controller.
In WebApp, each set of objects usually has an associated set of segments.

=head2 Sessions

If you want to use sessions, you have to decide 2 things: how you want to
I<store> them locally, and how you want I<present them to the user>.  WebApp
has abstract Session and Session::Loader classes to cover this.  Here's an
example of how you might use session files & cookies in your app:

  use Pipeline;
  use OpenFrame::WebApp::Session::Factory;
  use OpenFrame::WebApp::Segment::Session::CookieLoader;

  my $pipe  = new Pipeline;
  my $sfact = new OpenFrame::WebApp::Session::Factory()->type( 'file_cache' );
  $pipe->store->set( $sfact );
  $pipe->add_segment( new OpenFrame::WebApp::Segment::Session::CookieLoader );

  ... add some segments that use the Session object ...

  $pipe->dispatch();

  # session is automatically saved at cleanup

=head2 Templates

If you want to use templates, you have to decide what template processing
system to use:  Template::Toolkit, HTML::Template, Petal, Embperl,
XML::Template, Text::Template, ...  There's plenty to choose from.  WebApp can
be extended to support them all, though out-of-the box it only supports a few.
Here's an example of how your application might use TT2 templates:

  use Pipeline;
  use OpenFrame::WebApp::Template::Factory;
  use OpenFrame::WebApp::Segment::Session::CookieLoader;

  my $pipe  = new Pipeline;
  my $tfact = new OpenFrame::WebApp::Template::Factory()->type( 'tt2' );
  $pipe->store->set( $tfact );
  $pipe->add_segment( new OpenFrame::WebApp::Segment::TemplateLoader );

  ... add some segments that use $tfact to generate templates ...

  $pipe->dispatch();

=head2 Users

Most applications have different requirements for their users, so we've made
sure C<OpenFrame::WebApp::User> is as generic as it gets - because we expect
you to sub-class it to suit your needs.  And you're bound to need to write your
own user loader segments too.  But here's an example of how you might load
Users from the REMOTE_USER environment variable (set by Apache):

  use Pipeline;
  use OpenFrame::WebApp::User;
  use OpenFrame::WebApp::User::Factory;
  use OpenFrame::WebApp::Segment::User::EnvLoader;

  my $pipe  = new Pipeline;
  my $ufact = new OpenFrame::WebApp::User::Factory()->type( 'webapp' );
  $pipe->store->set( $ufact );
  $pipe->add_segment( new OpenFrame::WebApp::Segment::User::EnvLoader );

  ... add some segments that use the User object ...

  $pipe->dispatch();

=head2 Errors

WebApp combines the C<Error> module's exception model and the idea of I<error
flags> in L<OpenFrame::WebApp::Error>.  You can either keep using this model,
or replace it with something else if you like.

=head2 Localization

No localization hooks in place yet.

=head2 Configuration

No configuration hooks in place yet (but see L<Pipeline::Config>).

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame>, L<OpenFrame::AppKit>

=cut
