package Tags::HTML::Login::Access;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use List::Util qw(none);
use Readonly;

Readonly::Array our @FORM_METHODS => qw(post get);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_access', 'form_method', 'lang', 'register_url', 'text', 'width'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS style for access box.
	$self->{'css_access'} = 'form-login';

	# Form method.
	$self->{'form_method'} = 'post';

	# Language.
	$self->{'lang'} = 'eng';

	# Register URL.
	$self->{'register_url'} = undef;

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

	# TODO Check lang.

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

	# Object.
	return $self;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	my $username_id = 'username';
	my $password_id = 'password';

	# Main content.
	$self->{'tags'}->put(
		['b', 'form'],
		['a', 'class', $self->{'css_access'}],
		['a', 'method', $self->{'form_method'}],

		['b', 'fieldset'],
		['b', 'legend'],
		['d', $self->_text('login')],
		['e', 'legend'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', $username_id],
		['e', 'label'],
		['d', $self->_text('username_label')],
		['b', 'input'],
		['a', 'type', 'text'],
		['a', 'name', $username_id],
		['a', 'id', $username_id],
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

		['e', 'fieldset'],

		['e', 'form'],
	);

	return;
}

# Process 'CSS::Struct'.
sub _process_css {
	my $self = shift;

	$self->{'css'}->put(
		['s', '.'.$self->{'css_access'}],
		['d', 'width', $self->{'width'}],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'box-shadow', '0 0 10px rgba(0, 0, 0, 0.2)'],
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
	);

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
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Login::Access->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<css_access>

CSS style for access box.

Default value is 'form-login'.

=item * C<form_method>

Form method.

Possible values are 'post' and 'get'.

Default value is 'post'.

=item * C<lang>

Language in ISO 639-3 code.

Default value is 'eng'.

=item * C<register_url>

URL to registration page.

Default value is undef.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=item * C<text>

Hash reference with keys defined language in ISO 639-3 code and value with hash
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

 $obj->process;

Process Tags structure for login box.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process CSS::Struct structure for login box.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE

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
 #       <input type="text" name="username" id="username">
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

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::Util>,
L<Readonly>,
L<Tags::HTML>.

=head1 SEE ALSO

=over

=item L<Tags::HTML::Login::Button>

Tags helper for login button.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Login-Access>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2021-2023

BSD 2-Clause License

=head1 VERSION

0.01

=cut
