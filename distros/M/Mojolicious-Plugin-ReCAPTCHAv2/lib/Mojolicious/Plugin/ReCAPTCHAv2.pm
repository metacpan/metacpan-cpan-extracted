package Mojolicious::Plugin::ReCAPTCHAv2;
# vim:syntax=perl:tabstop=4:number:noexpandtab:
$Mojolicious::Plugin::ReCAPTCHAv2::VERSION = '0.4';
use Mojo::Base 'Mojolicious::Plugin';

# ABSTRACT: use Googles "No CAPTCHA reCAPCTHA" (reCAPTCHA v2) service in Mojolicious apps

use Mojo::JSON qw();
use Mojo::UserAgent qw();

has conf => sub{ +{} };
has verification_errors => sub{ +[] };

sub register {
	my $plugin = shift;
	my $app    = shift;
	my $conf   = shift || {};

	die ref($plugin), ": need sitekey and secret!\n"
		unless $conf->{'sitekey'} and $conf->{'secret'};

	$conf->{'api_url'}     //= 'https://www.google.com/recaptcha/api/siteverify';
	$conf->{'api_timeout'} //= 10;

	$plugin->conf($conf);

	$app->helper(
		recaptcha_get_html => sub {
			my $c         = shift;
			my $language  = $_[0] ? shift : undef;

			my %data_attr = map { $_ => $plugin->conf->{$_} } grep { index( $_, 'api_' ) != 0 } keys %{ $plugin->conf };

			# Never expose this!
			delete $data_attr{'secret'};

			my $hl = '';
			if ( defined $language and $language ) {
				$hl = $language;
			}
			elsif ( exists $data_attr{'language'} ) {
				$hl = delete $data_attr{'language'};
			}

			my $output = '';
			my $template = q|<script src="https://www.google.com/recaptcha/api.js?hl=<%= $hl %>" async defer></script>
<div class="g-recaptcha"<% foreach my $k ( sort keys %{$attr} ) { %> data-<%= $k %>="<%= $attr->{$k} %>"<% } %>></div>|;

			# Compatibility with Mojolicious < 5.0
			if ( $c->can('render_to_string') ) {
				$output = $c->render_to_string(
					handler => 'ep',
					inline => $template,
					hl     => $hl,
					attr   => \%data_attr,
				);
			}
			else {
				$output = $c->render(
					handler => 'ep',
					inline  => $template,
					hl      => $hl,
					attr    => \%data_attr,
					partial => 1,
				);
			}
			return $output;
		}
	);
	$app->helper(
		recaptcha_verify => sub {
			my $c = shift;

			my %verify_params = (
				remoteip => $c->tx->remote_address,
				response => ( $c->req->param('g-recaptcha-response') || '' ),
				secret   => $plugin->conf->{'secret'},
			);

			my $url     = $plugin->conf->{'api_url'};
			my $timeout = $plugin->conf->{'api_timeout'};

			my $ua = Mojo::UserAgent->new();
			$ua->max_redirects(0)->request_timeout($timeout);

			# reset previous errors, if any
			$plugin->verification_errors([]);

			# XXX async request?

			my $tx = '';
			# Backwards compatibility with older Mojolicious versions
			if ( $ua->can('post_form') ) {
				$tx = $ua->post_form( $url => \%verify_params );
			}
			else {
				$tx = $ua->post( $url => form => \%verify_params );
			}

			if ( my $res = $tx->success ) {
				my $json = '';
				eval {
					$json = Mojo::JSON::decode_json( $res->body );
				};

				# Compatibility with Mojo::JSON as of Mojolicious < 4.82
				if ( defined($@) and index( $@, 'Mojo::JSON::decode_json' ) >= 0 ) {
					eval {
						my $obj = Mojo::JSON->new;
						$json = $obj->decode( $res->body );
					};
				}

				if ($@) {
					$c->app->log->error( 'Decoding JSON response failed: ' . $@ );
					$c->app->log->error( 'Request  was: ' . $tx->req->to_string );
					$c->app->log->error( 'Response was: ' . $tx->res->to_string );
					$plugin->verification_errors( ["x-unparseable-data-received"] );
					return 0;
				}

				my $oo = 0;
				eval {
					my $obj = Mojo::JSON->new;
					$oo = $obj->can('true');
				};
				unless ( $json->{'success'} == ( $oo ? Mojo::JSON->true : Mojo::JSON::true ) ) {
					$plugin->verification_errors( $json->{'error-codes'} // [] );
				}
				return $json->{'success'};

			}
			else {
				my $err = $tx->error;
				my $txt = 'Retrieving captcha verifcation failed';
				$txt   .= ' (HTTP ' . $err->{'code'} . ')' if $err->{'code'};

				$c->app->log->error( $txt . ': ' . $err->{'message'} );
				$c->app->log->error( 'Request  was: ' . $tx->req->to_string );
				$plugin->verification_errors( ["x-http-communication-failed"] );

				return 0;
			}
		}
	);
	$app->helper(
		recaptcha_get_errors => sub {
			return $plugin->verification_errors;
		}
	);

	return;
} ## end sub register

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ReCAPTCHAv2 - use Googles "No CAPTCHA reCAPCTHA" (reCAPTCHA v2) service in Mojolicious apps

=head1 VERSION

version 0.4

=head1 SYNOPSIS

    use Mojolicious::Plugin::ReCAPTCHAv2;

    sub startup {
        my $self = shift;

        $self->plugin('ReCAPTCHAv2', {
            sitekey       => 'site-key-embedded-in-public-html',                 # required
            secret        => 'key-used-in-internal-verification-requests',       # required
            # api_timeout => 10,                                                 # optional
            # api_url     => 'https://www.google.com/recaptcha/api/siteverify',  # optional
            # size        => 'normal',                                           # optional
            # tabindex    => 0,                                                  # optional
            # theme       => 'light',                                            # optional
            # type        => 'image',                                            # optional
        });
    }

    # later

    # assembling website:
    $app->stash( captcha => $app->recaptcha_get_html );
    # now use stashed value in your HTML template, i.e.: <form..>...<% $captcha %>...</form>

    # on incoming request
    if ( $app->recaptcha_verify ) {
        # success: probably human
        ...
    }
    else {
        # fail: probably bot, but may also be a
        # processing error

        if ( my $err = $app->recaptcha_get_errors ) {
            # processing failed, inspect error codes
            foreach my $e ( @{$err} ) {
                ...
            }
        }
        else {
            # bot
            ...
        }
    }

=head1 DESCRIPTION

L<Mojolicious::Plugin::ReCAPTCHAv2> allows you to protect your site against
automated interaction by (potentially malicious) robots.

This is accomplished by injecting a extra javascript widget in your forms
that requires human interaction. The interaction is evaluated on a server
(via AJAX) and a dynamic parameter is injected in your form.
When your users submit your form to your server you receive that parameter
and can verify it by sending it to the captcha servers in the background.
You should then stop further processing of the request you received if the
captcha did not validate.

Please note that this module currently does not support some advanced usage
models for the captcha like explicit rendering and AJAX callbacks.
Therefore a few options listed in the official Google docs are not listed
above.
If you would like to see support for this kind of functionality, please
get in touch with the author / maintainer of this module.

For a general overview of what a Captcha is and how the Google "No Captcha"
reCaptcha (v2) service works, please refer to the
L<official documentation|https://developers.google.com/recaptcha/>.

=head1 OPTIONS

The following params can be provided to the plugin on registration:

=over 4

=item C<sitekey>

=item C<secret>

=item C<api_timeout>

=item C<api_url>

=item C<size>

=item C<tabindex>

=item C<theme>

=item C<type>

=back

C<sitekey> and C<secret> are required parameters, while all others are
optional. The default values for the optional configuration params are shown
in the synopsis.

For the meaning of these please refer to L<https://developers.google.com/recaptcha/docs/display#config>.

=head1 METHODS

L<Mojolicious::Plugin::ReCAPTCHAv2> inherits all methods from L<Mojolicious::Plugin>
and implements no extra ones.

=head1 HELPERS

L<Mojolicious::Plugin::ReCAPTCHAv2> makes the following helpers available:

=head2 recaptcha_get_html

Returns a HTML fragment with the widget code; you will probably want to put
this in the stash, since it has to be inserted in your HTML form element
when processing the template.

=head2 recaptcha_verify

Call this helper when receiving the request from your website after the user
submitted the form. Sends your secret, the response token from the request
your received and the users IP to the reCAPTCHA server to verify the token.

You should call this only once per incoming request.

It will return either a C<true> or C<false> value:

=over 4

=item C<false> (0)

The reCAPTCHA service could not verify that the Captcha was solved by a
human; either because it was a bot or because of some processing error.
You should check for processing errors via C<recaptcha_get_errors>.
You should not continue with processing your users request but probably
re-display the form with an added error message.

=item C<true> (1)

The data is valid and the reCAPTCHA service believes that the challenge
was solved by a human. You may proceed with processing the incoming request.

=back

=head2 recaptcha_get_errors

This helper returns a reference to an array which may contain zero, one
or more error codes.
The array is reset on every call to C<recaptcha_verify>.
The array can contain these official API error codes:

=over 4

=item C<missing-input-secret>

The secret parameter is missing.

This should not happen, since registering the plugin requires a C<secret>
configuration param which is then automatically included in the verification
request.

=item C<invalid-input-secret>

The secret parameter is invalid or malformed.

Please check your registration data and configuration!

=item C<missing-input-response>

The response parameter is missing.

Please check if the HTML code for the widget was included at the correct
position in your template. Please check the request parameters that were
transferred to your server after the user submitted your form.

=item C<invalid-input-response>

The response parameter is invalid or malformed.

Somebody tinkered with the request data somewhere.

=back

Additionally the following error codes may be encountered which are defined
internally by this module. Note: these codes start with "x-" to 
distinguish them from official error codes.

=over 4

=item C<x-http-communication-failed>

Something went wrong while trying to talk to the reCAPTCHA server.

=item C<x-unparseable-data-received>

The http request was completed successfully but Mojo::JSON could not
decode the response received from the reCAPTCHA server.

=back

=head1 SEE ALSO

=over 4

=item L<Mojolicious>

=item L<https://developers.google.com/recaptcha/>

=back

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Heiko Jansen <hjansen@cpan.org>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
