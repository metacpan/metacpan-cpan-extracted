package Plack::App::Login::Request;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

use Plack::Request;
use Plack::Response;
use Plack::Session;
use Plack::Util::Accessor qw(generator lang login_request_cb logo_image_url
	message_cb redirect_login redirect_error text title);
use Tags::HTML::Container;
use Tags::HTML::Login::Request;

our $VERSION = 0.03;

sub _css {
	my $self = shift;

	$self->{'_tags_container'}->process_css;
	$self->{'_tags_login_request'}->process_css({
		'error' => 'red',
		'info' => 'blue',
	});

	return;
}

sub _login_check {
	my ($self, $env, $body_parameters_hr) = @_;

	if (! exists $body_parameters_hr->{'login_request'}
		|| $body_parameters_hr->{'login_request'} ne 'login_request') {

		$self->_message($env, 'error', 'There is no login request POST.');
		return 0;
	}
	if (! defined $body_parameters_hr->{'email'} || ! $body_parameters_hr->{'email'}) {
		$self->_message($env, 'error', "Missing email.");
		return 0;
	}

	return 1;
}

sub _message {
	my ($self, $env, $message_type, $message) = @_;

	if (defined $self->message_cb) {
		$self->message_cb->($env, $message_type, $message);
	}

	return;
}

sub _prepare_app {
	my $self = shift;

	# Defaults which rewrite defaults in module which I am inheriting.
	if (! $self->generator) {
		$self->generator(__PACKAGE__.'; Version: '.$VERSION);
	}

	if (! $self->title) {
		$self->title('Login request page');
	}

	# Inherite defaults.
	$self->SUPER::_prepare_app;

	# Defaults from this module.
	my %p = (
		'css' => $self->css,
		'tags' => $self->tags,
	);

	# Tags helper for login button.
	$self->{'_tags_login_request'} = Tags::HTML::Login::Request->new(
		%p,
		defined $self->lang ? (
			'lang' => $self->lang,
		) : (),
		'logo_image_url' => $self->logo_image_url,
		defined $self->text ? (
			'text' => $self->text,
		) : (),
	);
	$self->{'_tags_container'} = Tags::HTML::Container->new(%p);

	return;
}

sub _process_actions {
	my ($self, $env) = @_;

	if (defined $self->login_request_cb && $env->{'REQUEST_METHOD'} eq 'POST') {
		my $req = Plack::Request->new($env);
		my $body_params_hr = $req->body_parameters;
		my ($status, $messages_ar) = $self->_login_check($env, $body_params_hr);
		my $res = Plack::Response->new;
		if ($status) {
			if ($self->login_request_cb->($env, $body_params_hr->{'email'})) {
				$self->_message($env, 'info',
					"Login information for email '$body_params_hr->{'email'}' was sent.");
				$res->redirect($self->redirect_login);
			} else {
				$self->_message($env, 'error', 'Bad login email.');
				$res->redirect($self->redirect_error);
			}
		} else {
			$res->redirect($self->redirect_error);
		}
		$self->psgi_app($res->finalize);
	}

	return;
}

sub _tags_middle {
	my ($self, $env) = @_;

	my $messages_ar = [];
	if (exists $env->{'psgix.session'}) {
		my $session = Plack::Session->new($env);
		$messages_ar = $session->get('messages');
		$session->set('messages', []);
	}
	$self->{'_tags_container'}->process(
		sub {
			$self->{'_tags_login_request'}->process($messages_ar);
		},
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Login::Request - Plack application for request of login information.

=head1 SYNOPSIS

 use Plack::App::Login::Request;

 my $obj = Plack::App::Login::Request->new(%parameters);
 my $psgi_ar = $obj->call($env);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::Login::Request->new(%parameters);

Constructor.

=over 8

=item * C<author>

Author string to HTML head.

Default value is undef.

=item * C<content_type>

Content type for output.

Default value is 'text/html; charset=__ENCODING__'.

=item * C<css>

Instance of L<CSS::Struct::Output> object.

Default value is L<CSS::Struct::Output::Raw> instance.

=item * C<css_init>

Reference to array with L<CSS::Struct> structure.

Default value is CSS initialization from L<Tags::HTML::Page::Begin> like

 * {
	box-sizing: border-box;
	margin: 0;
	padding: 0;
 }

=item * C<encoding>

Set encoding for output.

Default value is 'utf-8'.

=item * C<favicon>

Link to favicon.

Default value is undef.

=item * C<flag_begin>

Flag that means begin of html writing via L<Tags::HTML::Page::Begin>.

Default value is 1.

=item * C<flag_end>

Flag that means end of html writing via L<Tags::HTML::Page::End>.

Default value is 1.

=item * C<generator>

HTML generator string.

Default value is 'Plack::App::Login; Version: __VERSION__'.

=item * C<lang>

Language in ISO 639-2 code.

Default value is undef.

=item * C<psgi_app>

PSGI application to run instead of normal process.
Intent of this is change application in C<_process_actions> method.

Default value is undef.

=item * C<script_js>

Reference to array with Javascript code strings.

Default value is [].

=item * C<script_js_src>

Reference to array with Javascript URLs.

Default value is [].

=item * C<status_code>

HTTP status code.

Default value is 200.

=item * C<tags>

Instance of L<Tags::Output> object.

Default value is

 Tags::Output::Raw->new(
         'xml' => 1,
         'no_simple' => ['script', 'textarea'],
         'preserved' => ['pre', 'style'],
 );

=item * C<text>

Hash reference with keys defined language in ISO 639-2 code and value with hash reference with texts.

Required keys are 'login_request', 'email_label' and 'submit'.

See more in L<Tags::HTML::Login::Request>.

Default value is undef.

=item * C<title>

Page title.

Default value is 'Login page'.

=back

Returns instance of object.

=head2 C<call>

 my $psgi_ar = $obj->call($env);

Implementation of login request page.

Returns reference to array (PSGI structure).

=head2 C<to_app>

 my $app = $obj->to_app;

Creates Plack application.

Returns Plack::Component object.

=head1 EXAMPLE

=for comment filename=plack_app_login_request.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Plack::App::Login::Request;
 use Data::Message::Simple;
 use Plack::Builder;
 use Plack::Runner;
 use Plack::Session;
 use Tags::Output::Indent;
 use Unicode::UTF8 qw(decode_utf8);

 my $message_cb = sub {
         my ($env, $message_type, $message) = @_;
         my $session = Plack::Session->new($env);
         my $m = Data::Message::Simple->new(
                 'text' => $message,
                 'type' => $message_type,
         );
         my $messages_ar = $session->get('messages');
         if (defined $messages_ar) {
                 push @{$messages_ar}, $m;
         } else {
                 $session->set('messages', [$m]);
         }
         return;
 };

 # Run application.
 my $app = Plack::App::Login::Request->new(
         'css' => CSS::Struct::Output::Indent->new,
         'generator' => 'Plack::App::Login::Request',
         'login_request_cb' => sub {
                 my ($env, $email) = @_;
                 if ($email eq 'skim@skim.cz') {
                         return 1;
                 } else {
                         return 0;
                 }
         },
         'message_cb' => $message_cb,
         'redirect_login' => '/',
         'redirect_error' => '/',
         'tags' => Tags::Output::Indent->new(
                 'preserved' => ['style'],
                 'xml' => 1,
         ),
 )->to_app;
 my $builder = Plack::Builder->new;
 $builder->add_middleware('Session');
 my $app_with_session = $builder->wrap($app);
 Plack::Runner->new->run($app_with_session);

 # Workflows:
 # 1) Blank request.
 # 2) Fill skim@skim.cz email and request.
 # 3) Fill another email and request.

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 #     <meta name="generator" content="Plack::App::Login::Request" />
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
 #     <title>
 #       Login request page
 #     </title>
 #     <style type="text/css">
 # * {
 # 	box-sizing: border-box;
 # 	margin: 0;
 # 	padding: 0;
 # }
 # .container {
 # 	display: flex;
 # 	align-items: center;
 # 	justify-content: center;
 # 	height: 100vh;
 # }
 # .form-request {
 # 	width: 300px;
 # 	background-color: #f2f2f2;
 # 	padding: 20px;
 # 	border-radius: 5px;
 # 	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
 # }
 # .form-request .logo {
 # 	height: 5em;
 # 	width: 100%;
 # }
 # .form-request img {
 # 	margin: auto;
 # 	display: block;
 # 	max-width: 100%;
 # 	max-height: 5em;
 # }
 # .form-request fieldset {
 # 	border: none;
 # 	padding: 0;
 # 	margin-bottom: 20px;
 # }
 # .form-request legend {
 # 	font-weight: bold;
 # 	margin-bottom: 10px;
 # }
 # .form-request p {
 # 	margin: 0;
 # 	padding: 10px 0;
 # }
 # .form-request label {
 # 	display: block;
 # 	font-weight: bold;
 # 	margin-bottom: 5px;
 # }
 # .form-request input[type="email"] {
 # 	width: 100%;
 # 	padding: 8px;
 # 	border: 1px solid #ccc;
 # 	border-radius: 3px;
 # }
 # .form-request button[type="submit"] {
 # 	width: 100%;
 # 	padding: 10px;
 # 	background-color: #4CAF50;
 # 	color: #fff;
 # 	border: none;
 # 	border-radius: 3px;
 # 	cursor: pointer;
 # }
 # .form-request button[type="submit"]:hover {
 # 	background-color: #45a049;
 # }
 # .form-request .messages {
 # 	text-align: center;
 # }
 # .error {
 # 	color: red;
 # }
 # .info {
 # 	color: blue;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <div class="container">
 #       <div class="inner">
 #         <form class="form-request" method="post">
 #           <fieldset>
 #             <legend>
 #               Login request
 #             </legend>
 #             <p>
 #               <label for="email" />
 #               Email
 #               <input type="email" name="email" id="email" autofocus="autofocus"
 #                 />
 #             </p>
 #             <p>
 #               <button type="submit" name="login_request" value="login_request">
 #                 Request
 #               </button>
 #             </p>
 #           </fieldset>
 #         </form>
 #       </div>
 #     </div>
 #   </body>
 # </html>

 # Output screenshot is in images/ directory.

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Plack-App-Login-Request/master/images/plack_app_login_request.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Plack-App-Login-Request/master/images/plack_app_login_request.png" alt="Web app example" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Plack::Component::Tags::HTM>,
L<Plack::Request>,
L<Plack::Response>,
L<Plack::Session>,
L<Plack::Util::Accessor>,
L<Tags::HTML::Container>,
L<Tags::HTML::Login::Request>.

=head1 SEE ALSO

=over

=item L<Plack::App::Login>

Plack login application.

=item L<Plack::App::Login::Password>

Plack login/password application.

=item L<Plack::App::Register>

Plack register application.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Login-Request>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
