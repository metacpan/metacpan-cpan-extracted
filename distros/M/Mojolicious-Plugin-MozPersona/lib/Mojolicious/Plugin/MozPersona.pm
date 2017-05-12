
package Mojolicious::Plugin::MozPersona;
$Mojolicious::Plugin::MozPersona::VERSION = '0.05';
# ABSTRACT: Minimalistic integration of Mozillas "Persona" authentication system in Mojolicious apps

use strict;
use warnings;


use Mojo::Base 'Mojolicious::Plugin';

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

use Mojolicious::Plugin::MozPersona::Controller;


my %defaults = (
	audience      => '',
	siteName      => '',
	service       => 'https://verifier.login.persona.org/verify',
	namespace     => 'Mojolicious::Plugin::MozPersona::Controller',
	signinId      => 'personaSignin',
	signinPath    => '/_persona/signin',
	signoutId     => 'personaSignout',
	signoutPath   => '/_persona/signout',
	autoHook      => { css => 0, jquery => 'bundled', persona => 1, local => 1, uid => 1 },
	localJsPath   => '/_persona/localjs',
	localJsTpl    => '_persona/local_js.txt.ep',
	personaJsPath => 'https://login.persona.org/include.js',
);


sub register {
	my ( $self, $app ) = @_;

	my $defaultHooks = delete $defaults{'autoHook'};
	my (%conf) = ( %defaults, %{ $_[2] || {} } );

	$conf{'autoHook'} = {} unless exists $conf{'autoHook'};
	foreach my $h ( keys %{$defaultHooks} ) {
		if ( ref $conf{'autoHook'} && !exists $conf{'autoHook'}->{$h} ) {
			$conf{'autoHook'}->{$h} = $defaultHooks->{$h};
		}
	}

	$conf{'siteName'} =~ tr/"'//d;
	$conf{'signinPath'} =~ tr/"'//d;
	$conf{'signoutPath'} =~ tr/"'//d;
	$conf{'signinId'} =~ tr/"'#//d;
	$conf{'signoutId'} =~ tr/"'#//d;

	die "Missing required configuration parameter: 'audience'!" unless $conf{'audience'};
	die "Missing required configuration parameter: 'siteName'!" unless $conf{'siteName'};

	# Append "templates" and "public" directories
	my $base = catdir( dirname(__FILE__), 'MozPersona' );
	push @{ $app->renderer->paths }, catdir( $base, 'templates' );
	push @{ $app->static->paths },   catdir( $base, 'public' );

	push @{ $app->renderer->classes }, __PACKAGE__;
	push @{ $app->static->classes },   __PACKAGE__;

	$app->routes->route( $conf{signinPath} )->via('POST')->to(
		namespace         => $conf{namespace},
		action            => 'signin',
		_persona_audience => $conf{audience},
		_persona_service  => $conf{service},
	);
	$app->routes->route( $conf{signoutPath} )->via('POST')->to(
		namespace         => $conf{namespace},
		action            => 'signout',
		_persona_audience => $conf{audience},
		_persona_service  => $conf{service},
	);
	$app->routes->route( $conf{localJsPath} )->via('GET')
		->to( namespace => $conf{namespace}, action => 'js', _persona_conf => \%conf, );

	if ( $conf{'autoHook'} ) {

		my $head_block = '';
		if ( $conf{'autoHook'}->{'css'} ) {
			$head_block
				.= '<link href="/_persona/persona-buttons.css" media="screen" rel="stylesheet" type="text/css" />';
		}
		if ( my $jq = $conf{'autoHook'}->{'jquery'} ) {
			if ( $jq eq 'cdn' ) {
				$head_block
					.= '<script src="http://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>';
			}
			elsif ( $jq eq 'bundled' or $jq ) {
				$head_block
					.= '<script src="/mojo/jquery/jquery.js" type="text/javascript"></script>';
			}
		}

		my $end_block = '';
		if ( $conf{'autoHook'}->{'persona'} ) {
			$end_block .= qq|<script type="text/javascript" src="$conf{'personaJsPath'}"></script>|;
		}
		if ( $conf{'autoHook'}->{'local'} ) {
			$end_block .= qq|<script type="text/javascript" src="$conf{'localJsPath'}"></script>|;
		}

		$app->hook(
			after_dispatch => sub {
				my ($c) = @_;
				return unless index( $c->res->headers->content_type, 'html' ) >= 0;

				my $body = $c->res->body;

				if ( $conf{'autoHook'}->{'uid'} ) {
					if ( defined( $c->session('_persona') )
						&& $c->session('_persona')->{'status'} eq 'okay' )
					{
						my $email = $c->session('_persona')->{'email'};
						$body
							=~ s!<head>!<head><script type="text/javascript">var personaCurrentUser = "$email";</script>$head_block!o;
					}
					else {
						$body
							=~ s!<head>!<head><script type="text/javascript">var personaCurrentUser = null;</script>$head_block!o;
					}
				}
				elsif ($head_block) {
					$body =~ s!<head>!<head>$head_block!o;
				}

				if ($end_block) {
					$body =~ s!</body>!$end_block</body>!o;
				}
				$c->res->body($body);
			}
		);
	} ## end if ( $conf{'autoHook'})

	return;
} ## end sub register


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::MozPersona - Minimalistic integration of Mozillas "Persona" authentication system in Mojolicious apps

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'MozPersona' => {
      audience => 'http://127.0.0.1:3000/',
      siteName => 'My spectacular new site!',
      autoHook => { css => 1 },
  };

  # Mojolicious
  # $self->plugin( moz_persona => { 
  #     audience => 'https://example.org:8443/',
  #     siteName => 'My shiny new site!'
  # });

  get '/' => sub {
      my $self = shift;
      $self->render('index');
  };

  app->start;

  __DATA__

  @@ index.html.ep
  <!DOCTYPE html>
  <html>
    <head><title>Mozilla Persona Test</title></head>
    <body>
  % if ( defined(session '_persona') && (session '_persona')->{'status'} eq 'okay' ) {
  %     my $email = (session '_persona')->{'email'};
      <a href="#" class="persona-button" id="personaSignout"><span><%= $email %> abmelden</span></a>
  % } else {
      <a href="#" class="persona-button" id="personaSignin"><span>Anmelden mit Ihrer Email</span></a>
  % }
      <p>Some dummy content.</p>
    </body>
  </html>:confirm b6

=head1 DESCRIPTION

L<Mojolicious::Plugin::MozPersona> is a L<Mojolicious> plugin.
It provides a minimalistic integration of Mozillas "Persona" authentication
system in Mojolicious apps. 

This modules adds a few routes (at C<signinPath>, C<signoutPath> and C<localJsPath>,
see below) to your app which refer to the code that is responsible for handling
the local, application-specific server side part of the B<Persona> authentication model.

It also by default registers a C<after_dispatch> hook that automatically inserts
some C<script> and C<link> elements to pull in the JavaScript code Persona needs
and some CSS that provides common styling rules for the signin/signout elements
(cf. C<autoHook> below).

Please note that you´re advised to read the
L<Persona documentation|https://developer.mozilla.org/en-US/docs/Persona> before 
using this plugin.

=head1 NAME

Mojolicious::Plugin::MozPersona - Minimalistic integration of Mozillas 
"Persona" authentication system in Mojolicious apps.

B<BEWARE: THIS IS AN EARLY RELEASE!> - It is quite possible that there will
be incompatible changes before the API and the functionality of this 
plugin are declared stable. Use at your own risk.
On the other hand that also means that now is the right time to tell me
what should be changed to make this module more usable and useful!

=head1 CONFIGURATION

You may pass a hash ref on plugin registration. The following keys are currently 
recognized: 

=over 4

=item audience

The protocol, domain name, and port of your site. E.g. C<https://example.org:8443>.
This param is mandatory.

=item siteName

The human readable name of your site (the running Mojolicious app).
Will be shown to the user when he or she signs in with the identity 
provider. This param is mandatory.

=item service

The URL of the API of the identity provider you selected.
Default is C<https://verifier.login.persona.org/verify>.

=item namespace

The name of a Mojolicious::Controller module.
This controller provides the server-side functionality necessary to verify
a user login.
Default is L<Mojolicious::Plugin::MozPersona::Controller>.

=item signinId

The id of the HTML element which provides the "onClick" handler to start
the signin process. Default is C<personaSignin>.

=item signinPath

The URL path on your server that get´s called with the assertion of the
identity provider after the user signed in with the identity provider.
The handler code for this URL is responsible to verify the users identity
assertion and update the mojolicious session accordingly. 
Default is C</_persona/signin>.

=item signoutId

The id of the HTML element which provides the "onClick" handler to start
the signout process. Default is C<personaSignout>.

=item signoutPath

The URL path on your server that get´s called when user logs out.
The handler code for this URL is responsible for removing the authentication
information from the Mojolicious session. Default is C</_persona/signout'>.

=item autoHook

Hashref that tells the plugin wether to automatically add html elements to
include necessary JavaScript and CSS components.
Known values are:

=over 4

=item css

Include the style rules for CSS "Buttons" as provided by Mozilla by inserting
a C<E<lt>link rel="stylesheet" href="/_persona/persona-buttons.css"E<gt>> element.
Note that the CSS file is part of this distribution and not loaded from a 
Mozilla server.
Cf. L<https://developer.mozilla.org/en-US/docs/persona/branding>.
This option is deactivated (set to C<0>) by default.

=item jquery

Include the jQuery JavaScript library. The exact effect of activating this option
depends on the value provided:

=over 4

=item C<bundled>

If the option is set to C<bundled>, the jQuery file that is part of the Mojolicious 
distribution is used by inserting a C<E<lt>script src="/mojo/jquery/jquery.js"E<gt>> 
element.

<B>Beware:<B> Since the jQuery library bundled with Mojolicious is intended for internal
use only, this is not a recommended practice: consider using your own independent copy 
or use the CDN.

=item C<cdn>

Include the latest version of the jQuery JavaScript library by
utilizing the official content delivery network; inserts 
C<E<lt>script src="http://code.jquery.com/jquery-latest.min.js"E<gt>>.

As of now, the latest version from the 1.x line of development is available at that
URL. To minimize the risk of future incompatibilities please consider using your own 
independent copy (and set this option to C<false>).

=back

Prior to release 0.05 this option only took a boolean value and if that was C<true> the
bundled jQuery file was used. That is the reason why in release 0.05 any C<true> value 
besides C<bundled> and C<cdn> still has the same effect as if C<bundled> was passed in.

A future release will change this option to be off by default and will consider any value
besides the two shown above as C<false>. 

=item persona

Include the Persona JavaScript code by inserting the appropriate 
C<E<lt>script src="$config{'personaJsPath'}"E<gt>> element. See config param C<personaJs> below.

=item local

Include the local JavaScript code that triggers the start of the login and
logout processes and connects the persona authentication to the session of
the local application by inserting the appropriate C<E<lt>script src="$config{'localJsPath'}"E<gt>>

=item uid

Make the email address of the persona user available to the local JavaScript
code by setting a JavaScript variable.

=back

All hooks except for the C<css> hook are active by default.

Please note that these options are interconnected. E.g. the default local 
JavaScript code B<needs> jQuery so if you keep C<local> active and disable
C<jquery> you must include jQuery yourself! Similarly the default local JS 
code expects a JS variable with a specific name set to either "null" or the
email address of the currenly logged-in user.

=item localJsPath

The URL to use for retrieving the JavaScript code that registers the C<onClick>
handler and callback functions which are necessary for performing the signin
and signout process. Default is C</_persona/localjs>.

=item localJsTpl

The name of the template which provides the locally defined JavaScript "glue"
between your app and the Persona IdP. Default is C<_persona/local_js.txt.ep>.
The given value is automatically split to determine which format and handler
to use for rendering.
Unless specified via the given value C<format =E<gt> text> and C<handler =E<gt> ep>
are used as defaults.

=item personaJsPath

The URL or path to the Persona JavaScript code. 
Default is L<https://login.persona.org/include.js>.

=back

All configuration params the have a default value listed above are optional.

Besides C<siteName> the L<"navigator.id.request" function|https://developer.mozilla.org/en-US/docs/DOM/navigator.id.request>
additionally supports the following params: C<siteLogo>, C<termsOfService>, 
C<privacyPolicy>, C<oncancel>, and C<returnTo>.
You may provide string values for all of these when registering the plugin.
The default local JavaScript code, however, ignores C<oncancel> and C<returnTo>
and only passes the other three params to the Persona IdP.

=head1 METHODS

L<Mojolicious::Plugin::MozPersona> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones:

=head2 C<register>

  $plugin->register(Mojolicious->new);

You usually don´t call that method yourself directly. Instead, Mojolicious 
calls this function when you register the plugin, e.g. via 
C<plugin 'MozPersona' ...>.
See DESCRIPTION above for an explanation of what happens here.

=head1 HELPERS

None.

=head1 EXTRA FILES

The following files are part of this distribution and are available via
these URL paths:

  /_persona/email_sign_in_black.png
  /_persona/email_sign_in_blue.png
  /_persona/email_sign_in_red.png
  /_persona/persona-buttons.css
  /_persona/persona_sign_in_black.png
  /_persona/persona_sign_in_blue.png
  /_persona/persona_sign_in_red.png
  /_persona/plain_sign_in_black.png
  /_persona/plain_sign_in_blue.png
  /_persona/plain_sign_in_red.png

The images were created by members of the Mozilla Developer Network and are
available at L<Mozilla Persona Branding resources|https://developer.mozilla.org/en-US/docs/persona/branding>.
(c) 2012 by Mozilla Developer Network and / or the individual contributors.

The CSS was created by Sawyer Hollenshead and is also available at
L<Mozilla Persona Branding resources|https://developer.mozilla.org/en-US/docs/persona/branding>.
(c) 2012 by Sawyer Hollenshead.

The following template is part of this distribution:

  _persona/local_js.txt.ep

=head1 SEE ALSO

L<Mojolicious::Plugin::MozPersona::Controller>,
L<https://developer.mozilla.org/en-US/docs/Persona>,
L<Mojolicious>,
L<Mozilla::Persona>.

=head1 AUTHORS

=over 4

=item *

Heiko Jansen <hjansen@cpan.org>

=item *

Moritz Lenz <moritz@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
