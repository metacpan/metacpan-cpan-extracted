package Tags::HTML::Login::Access;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo::utils 0.06 qw(check_array);
use Mo::utils::CSS 0.06 qw(check_css_unit);
use Mo::utils::Language 0.05 qw(check_language_639_2);
use Readonly;
use Tags::HTML::Messages;

Readonly::Array our @FORM_METHODS => qw(post get);

our $VERSION = 0.11;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_access', 'form_method', 'lang', 'logo_image_url', 'register_url',
		'tags_after', 'text', 'width'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS style for access box.
	$self->{'css_access'} = 'form-login';

	# Form method.
	$self->{'form_method'} = 'post';

	# Language.
	$self->{'lang'} = 'eng';

	# Logo.
	$self->{'logo_image_url'} = undef;

	# Register URL.
	$self->{'register_url'} = undef;

	# Tags code after form.
	$self->{'tags_after'} = [];

	# Language texts.
	$self->{'text'} = {
		'eng' => {
			'login' => 'Login',
			'password_label' => 'Password',
			'username_label' => 'User name',
			'submit' => 'Login',
			'register' => 'Register',
		},
	};

	# Login box width.
	$self->{'width'} = '300px';

	# Process params.
	set_params($self, @{$object_params_ar});

	# Check form method.
	if (none { $self->{'form_method'} eq $_ } @FORM_METHODS) {
		err "Parameter 'form_method' has bad value.";
	}

	# Check lang.
	check_language_639_2($self, 'lang');

	# Check text for lang
	if (! defined $self->{'text'}) {
		err "Parameter 'text' is required.";
	}
	if (ref $self->{'text'} ne 'HASH') {
		err "Parameter 'text' must be a hash with language texts.";
	}
	if (! exists $self->{'text'}->{$self->{'lang'}}) {
		err "Texts for language '$self->{'lang'}' doesn't exist.";
	}

	check_array($self, 'tags_after');

	check_css_unit($self, 'width');

	$self->{'_tags_messages'} = Tags::HTML::Messages->new(
		'css' => $self->{'css'},
		'flag_no_messages' => 0,
		'tags' => $self->{'tags'},
	);

	# Object.
	return $self;
}

# Process 'Tags'.
sub _process {
	my ($self, $messages_ar) = @_;

	my $username_id = 'username';
	my $password_id = 'password';

	$self->{'tags'}->put(
		['b', 'form'],
		['a', 'class', $self->{'css_access'}],
		['a', 'method', $self->{'form_method'}],

		['b', 'fieldset'],
		['b', 'legend'],
		['d', $self->_text('login')],
		['e', 'legend'],
	);

	if (defined $self->{'logo_image_url'}) {
		$self->{'tags'}->put(
			['b', 'div'],
			['a', 'class', 'logo'],
			['b', 'img'],
			['a', 'src', $self->{'logo_image_url'}],
			['a', 'alt', 'logo'],
			['e', 'img'],
			['e', 'div'],
		);
	}

	$self->{'tags'}->put(

		['b', 'p'],
		['b', 'label'],
		['a', 'for', $username_id],
		['e', 'label'],
		['d', $self->_text('username_label')],
		['b', 'input'],
		['a', 'type', 'text'],
		['a', 'name', $username_id],
		['a', 'id', $username_id],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', $password_id],
		['d', $self->_text('password_label')],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', $password_id],
		['a', 'id', $password_id],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'login'],
		['a', 'value', 'login'],
		['d', $self->_text('submit')],
		['e', 'button'],
		['e', 'p'],

		defined $self->{'register_url'} ? (
			['b', 'a'],
			['a', 'href', $self->{'register_url'}],
			['d', $self->_text('register')],
			['e', 'a'],
		) : (),

		@{$self->{'tags_after'}},

		['e', 'fieldset'],
	);

	$self->{'_tags_messages'}->process($messages_ar);

	$self->{'tags'}->put(
		['e', 'form'],
	);

	return;
}

# Process 'CSS::Struct'.
sub _process_css {
	my ($self, $message_types_hr) = @_;

	$self->{'css'}->put(
		['s', '.'.$self->{'css_access'}],
		['d', 'width', $self->{'width'}],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'box-shadow', '0 0 10px rgba(0, 0, 0, 0.2)'],
		['e'],

		['s', '.'.$self->{'css_access'}.' .logo'],
		['d', 'height', '5em'],
		['d', 'width', '100%'],
		['e'],

		['s', '.'.$self->{'css_access'}.' img'],
		['d', 'margin', 'auto'],
		['d', 'display', 'block'],
		['d', 'max-width', '100%'],
		['d', 'max-height', '5em'],
		['e'],

		['s', '.'.$self->{'css_access'}.' fieldset'],
		['d', 'border', 'none'],
		['d', 'padding', 0],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.'.$self->{'css_access'}.' legend'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.'.$self->{'css_access'}.' p'],
		['d', 'margin', 0],
		['d', 'padding', '10px 0'],
		['e'],

		['s', '.'.$self->{'css_access'}.' label'],
		['d', 'display', 'block'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '5px'],
		['e'],

		['s', '.'.$self->{'css_access'}.' input[type="text"]'],
		['s', '.'.$self->{'css_access'}.' input[type="password"]'],
		['d', 'width', '100%'],
		['d', 'padding', '8px'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '3px'],
		['e'],

		['s', '.'.$self->{'css_access'}.' button[type="submit"]'],
		['d', 'width', '100%'],
		['d', 'padding', '10px'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', '#fff'],
		['d', 'border', 'none'],
		['d', 'border-radius', '3px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', '.'.$self->{'css_access'}.' button[type="submit"]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', '.'.$self->{'css_access'}.' .messages'],
		['d', 'text-align', 'center'],
		['e'],
	);

	$self->{'_tags_messages'}->process_css($message_types_hr);

	return;
}

sub _text {
	my ($self, $key) = @_;

	if (! exists $self->{'text'}->{$self->{'lang'}}->{$key}) {
		err "Text for lang '$self->{'lang'}' and key '$key' doesn't exist.";
	}

	return $self->{'text'}->{$self->{'lang'}}->{$key};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Login::Access - Tags helper for login access.

=head1 SYNOPSIS

 use Tags::HTML::Login::Access;

 my $obj = Tags::HTML::Login::Access->new(%params);
 $obj->process($message_ar);
 $obj->process_css($message_types_hr);

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Login::Access->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<css>

L<CSS::Struct::Output> object for L<process_css> processing.

Default value is undef.

=item * C<css_access>

CSS class for access box.

Default value is 'form-login'.

=item * C<form_method>

Form method.

Possible values are 'post' and 'get'.

Default value is 'post'.

=item * C<lang>

Language in ISO 639-2 code.

Default value is 'eng'.

=item * C<logo_image_url>

URL to logo image.

Default value is undef.

=item * C<register_url>

URL to registration page.

Default value is undef.

=item * C<tags>

L<Tags::Output> object.

Default value is undef.

=item * C<tags_after>

Reference to array with L<Tags> code which will be placed after form.

Default value is [].

=item * C<text>

Hash reference with keys defined language in ISO 639-2 code and value with hash
reference with texts.

Required keys are 'login', 'password_label', 'username_label' and 'submit'.

Default value is:

 {
 	'eng' => {
 		'login' => 'Login',
 		'password_label' => 'Password',
 		'username_label' => 'User name',
 		'submit' => 'Login',
 	},
 }

=back

=head2 C<process>

 $obj->process($message_ar);

Process Tags structure for login box.

Reference to array with message objects C<$message_ar> must be a instance of
L<Data::Message::Simple> object.

Returns undef.

=head2 C<process_css>

 $obj->process_css($message_types_hr);

Process CSS::Struct structure for login box.

Variable C<$message_type_hr> is reference to hash with keys for message type and value for color in CSS style.
Possible message types are info and error now. Types are defined in L<Data::Message::Simple>.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Mo::utils::check_array():
                 Parameter 'tags_after' must be a array.
                         Value: %s
                         Reference: %s
         From Mo::utils::CSS::check_css_unit():
                 Parameter 'width' doesn't contain number.
                         Value: %s
                 Parameter 'width' doesn't contain unit.
                         Value: %s
                 Parameter 'width' contain bad unit.
                         Unit: %s
                         Value: %s
         From Mo::utils::Language::check_language_639_2():
                 Parameter 'lang' doesn't contain valid ISO 639-2 code.
                         Codeset: %s
                         Value: %s
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE1

=for comment filename=print_block_html_and_css.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Login::Access;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Login::Access->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Process login button.
 $obj->process_css;
 $obj->process;

 # Print out.
 print "CSS\n";
 print $css->flush."\n\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # CSS
 # .form-login {
 # 	width: 300px;
 # 	background-color: #f2f2f2;
 # 	padding: 20px;
 # 	border-radius: 5px;
 # 	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
 # }
 # .form-login fieldset {
 # 	border: none;
 # 	padding: 0;
 # 	margin-bottom: 20px;
 # }
 # .form-login legend {
 # 	font-weight: bold;
 # 	margin-bottom: 10px;
 # }
 # .form-login p {
 # 	margin: 0;
 # 	padding: 10px 0;
 # }
 # .form-login label {
 # 	display: block;
 # 	font-weight: bold;
 # 	margin-bottom: 5px;
 # }
 # .form-login input[type="text"], .form-login input[type="password"] {
 # 	width: 100%;
 # 	padding: 8px;
 # 	border: 1px solid #ccc;
 # 	border-radius: 3px;
 # }
 # .form-login button[type="submit"] {
 # 	width: 100%;
 # 	padding: 10px;
 # 	background-color: #4CAF50;
 # 	color: #fff;
 # 	border: none;
 # 	border-radius: 3px;
 # 	cursor: pointer;
 # }
 # .form-login button[type="submit"]:hover {
 # 	background-color: #45a049;
 # }
 # 
 # HTML
 # <form class="form-login" method="post">
 #   <fieldset>
 #     <legend>
 #       Login
 #     </legend>
 #     <p>
 #       <label for="username">
 #       </label>
 #       User name
 #       <input type="text" name="username" id="username" autofocus="autofocus">
 #       </input>
 #     </p>
 #     <p>
 #       <label for="password">
 #         Password
 #       </label>
 #       <input type="password" name="password" id="password">
 #       </input>
 #     </p>
 #     <p>
 #       <button type="submit" name="login" value="login">
 #         Login
 #       </button>
 #     </p>
 #   </fieldset>
 # </form>

=head1 EXAMPLE2

=for comment filename=plack_app_login_access.pl

 use strict;
 use warnings;
 
 use CSS::Struct::Output::Indent;
 use Plack::App::Tags::HTML;
 use Plack::Runner;
 use Tags::HTML::Login::Access;
 use Tags::Output::Indent;
 use Unicode::UTF8 qw(decode_utf8);
 
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
         'preserved' => ['style'],
 );
 my $login = Tags::HTML::Login::Access->new(
         'css' => $css,
         'tags' => $tags,
         'register_url' => '/register',
 );
 my $app = Plack::App::Tags::HTML->new(
         'component' => 'Tags::HTML::Container',
         'data' => [sub {
                 $login->process_css;
                 $login->process;
         }],
         'data_prepare' => [sub {
                 $login->process_css;
         }],
         'css' => $css,
         'tags' => $tags,
         'title' => 'Login and password',
 )->to_app;
 Plack::Runner->new->run($app);

 # Output screenshot is in images/ directory.

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Login-Access/master/images/plack_app_login_access.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Login-Access/master/images/plack_app_login_access.png" alt="Web app example" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::Util>,
L<Mo::utils>,
L<Mo::utils::CSS>,
L<Mo::utils::Language>,
L<Readonly>,
L<Tags::HTML>,
L<Tags::HTML::Messages>.

=head1 SEE ALSO

=over

=item L<Tags::HTML::Login::Button>

Tags helper for login button.

=item L<Tags::HTML::Login::Register>

Tags helper for login register.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Login-Access>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.11

=cut
