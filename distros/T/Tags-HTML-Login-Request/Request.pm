package Tags::HTML::Login::Request;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo::utils::CSS 0.06 qw(check_css_unit);
use Mo::utils::Language 0.05 qw(check_language_639_2);
use Readonly;
use Tags::HTML::Messages;

Readonly::Array our @FORM_METHODS => qw(post get);

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_class', 'form_method', 'lang', 'logo_image_url',
		'text', 'width'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS style.
	$self->{'css_class'} = 'form-request';

	# Form method.
	$self->{'form_method'} = 'post';

	# Language.
	$self->{'lang'} = 'eng';

	# Logo.
	$self->{'logo_image_url'} = undef;

	# Language texts.
	$self->{'text'} = {
		'eng' => {
			'login_request' => 'Login request',
			'email_label' => 'Email',
			'submit' => 'Request',
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

	my $email_id = 'email';

	$self->{'tags'}->put(
		['b', 'form'],
		['a', 'class', $self->{'css_class'}],
		['a', 'method', $self->{'form_method'}],

		['b', 'fieldset'],
		['b', 'legend'],
		['d', $self->_text('login_request')],
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
		['a', 'for', $email_id],
		['e', 'label'],
		['d', $self->_text('email_label')],
		['b', 'input'],
		['a', 'type', 'email'],
		['a', 'name', $email_id],
		['a', 'id', $email_id],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'login_request'],
		['a', 'value', 'login_request'],
		['d', $self->_text('submit')],
		['e', 'button'],
		['e', 'p'],

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
		['s', '.'.$self->{'css_class'}],
		['d', 'width', $self->{'width'}],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'box-shadow', '0 0 10px rgba(0, 0, 0, 0.2)'],
		['e'],

		['s', '.'.$self->{'css_class'}.' .logo'],
		['d', 'height', '5em'],
		['d', 'width', '100%'],
		['e'],

		['s', '.'.$self->{'css_class'}.' img'],
		['d', 'margin', 'auto'],
		['d', 'display', 'block'],
		['d', 'max-width', '100%'],
		['d', 'max-height', '5em'],
		['e'],

		['s', '.'.$self->{'css_class'}.' fieldset'],
		['d', 'border', 'none'],
		['d', 'padding', 0],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.'.$self->{'css_class'}.' legend'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.'.$self->{'css_class'}.' p'],
		['d', 'margin', 0],
		['d', 'padding', '10px 0'],
		['e'],

		['s', '.'.$self->{'css_class'}.' label'],
		['d', 'display', 'block'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '5px'],
		['e'],

		['s', '.'.$self->{'css_class'}.' input[type="email"]'],
		['d', 'width', '100%'],
		['d', 'padding', '8px'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '3px'],
		['e'],

		['s', '.'.$self->{'css_class'}.' button[type="submit"]'],
		['d', 'width', '100%'],
		['d', 'padding', '10px'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', '#fff'],
		['d', 'border', 'none'],
		['d', 'border-radius', '3px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', '.'.$self->{'css_class'}.' button[type="submit"]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', '.'.$self->{'css_class'}.' .messages'],
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

Tags::HTML::Login::Request - Tags helper for login request.

=head1 SYNOPSIS

 use Tags::HTML::Login::Request;

 my $obj = Tags::HTML::Login::Request->new(%params);
 $obj->process($message_ar);
 $obj->process_css($message_types_hr);

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Login::Request->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<css_class>

CSS class.

Default value is 'form-request'.

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

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=item * C<text>

Hash reference with keys defined language in ISO 639-2 code and value with hash
reference with texts.

Required keys are 'login_request', 'email_label' and 'submit'.

Default value is:

 {
 	'eng' => {
 		'login_request' => 'Login request',
 		'email_label' => 'Email',
 		'submit' => 'Request',
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
 use Tags::HTML::Login::Request;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Login::Request->new(
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
 # .form-request {
 #         width: 300px;
 #         background-color: #f2f2f2;
 #         padding: 20px;
 #         border-radius: 5px;
 #         box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
 # }
 # .form-request .logo {
 #         height: 5em;
 #         width: 100%;
 # }
 # .form-request img {
 #         margin: auto;
 #         display: block;
 #         max-width: 100%;
 #         max-height: 5em;
 # }
 # .form-request fieldset {
 #         border: none;
 #         padding: 0;
 #         margin-bottom: 20px;
 # }
 # .form-request legend {
 #         font-weight: bold;
 #         margin-bottom: 10px;
 # }
 # .form-request p {
 #         margin: 0;
 #         padding: 10px 0;
 # }
 # .form-request label {
 #         display: block;
 #         font-weight: bold;
 #         margin-bottom: 5px;
 # }
 # .form-request input[type="email"] {
 #         width: 100%;
 #         padding: 8px;
 #         border: 1px solid #ccc;
 #         border-radius: 3px;
 # }
 # .form-request button[type="submit"] {
 #         width: 100%;
 #         padding: 10px;
 #         background-color: #4CAF50;
 #         color: #fff;
 #         border: none;
 #         border-radius: 3px;
 #         cursor: pointer;
 # }
 # .form-request button[type="submit"]:hover {
 #         background-color: #45a049;
 # }
 # .form-request .messages {
 #         text-align: center;
 # }
 # 
 # HTML
 # <form class="form-request" method="post">
 #   <fieldset>
 #     <legend>
 #       Login request
 #     </legend>
 #     <p>
 #       <label for="email">
 #       </label>
 #       Email
 #       <input type="email" name="email" id="email" autofocus="autofocus">
 #       </input>
 #     </p>
 #     <p>
 #       <button type="submit" name="login_request" value="login_request">
 #         Request
 #       </button>
 #     </p>
 #   </fieldset>
 # </form>

=head1 EXAMPLE2

=for comment filename=plack_app_login_request.pl

 use strict;
 use warnings;
 
 use CSS::Struct::Output::Indent;
 use Plack::App::Tags::HTML;
 use Plack::Runner;
 use Tags::HTML::Login::Request;
 use Tags::Output::Indent;
 use Unicode::UTF8 qw(decode_utf8);
 
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
         'preserved' => ['style'],
 );
 my $login_request = Tags::HTML::Login::Request->new(
         'css' => $css,
         'tags' => $tags,
 );
 $login_request->process_css;
 my $app = Plack::App::Tags::HTML->new(
         'component' => 'Tags::HTML::Container',
         'data' => [sub {
                 my $self = shift;
                 $login_request->process;
                 $login_request->process_css;
                 return;
         }],
         'css' => $css,
         'tags' => $tags,
         'title' => 'Login and password',
 )->to_app;
 Plack::Runner->new->run($app);

 # Output screenshot is in images/ directory.

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Login-Request/master/images/plack_app_login_request.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Login-Request/master/images/plack_app_login_request.png" alt="Web app example" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::Util>,
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

L<https://github.com/michal-josef-spacek/Tags-HTML-Login-Request>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
