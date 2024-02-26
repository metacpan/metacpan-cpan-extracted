package Tags::HTML::ChangePassword;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use List::Util qw(none);
use Readonly;
use Tags::HTML::Messages;

Readonly::Array our @FORM_METHODS => qw(post get);

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_change_password', 'form_method', 'lang', 'link', 'text', 'width'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS style for change password box.
	$self->{'css_change_password'} = 'form-change-password';

	# Form method.
	$self->{'form_method'} = 'post';

	# Language.
	$self->{'lang'} = 'eng';

	# Language texts.
	$self->{'text'} = {
		'eng' => {
			'change_password' => 'Change password',
			'old_password_label' => 'Old password',
			'password1_label' => 'New password',
			'password2_label' => 'Confirm new password',
			'submit' => 'Save Changes',
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

	$self->{'_tags_messages'} = Tags::HTML::Messages->new(
		'css' => $self->{'css'},
		'flag_no_messages' => 0,
		'tags' => $self->{'tags'},
	);

	# Object.
	return $self;
}

sub _cleanup {
	my $self = shift;

	delete $self->{'_messages'};
	delete $self->{'_message_types'};

	return;
}

sub _prepare {
	my ($self, $message_types_hr) = @_;

	if (! defined $message_types_hr) {
		err 'No message types to init.';
	}

	$self->{'_message_types'} = $message_types_hr;

	return;
}

sub _init {
	my ($self, $messages_ar) = @_;

	if (! defined $messages_ar) {
		err 'No messages to init.';
	}

	$self->{'_messages'} = $messages_ar;

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	my $old_password_id = 'old_password';
	my $password1_id = 'password1';
	my $password2_id = 'password2';

	# Main content.
	$self->{'tags'}->put(
		['b', 'form'],
		['a', 'class', $self->{'css_change_password'}],
		['a', 'method', $self->{'form_method'}],

		['b', 'fieldset'],
		['b', 'legend'],
		['d', $self->_text('change_password')],
		['e', 'legend'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', $old_password_id],
		['d', $self->_text('old_password_label')],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', $old_password_id],
		['a', 'id', $old_password_id],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', $password1_id],
		['d', $self->_text('password1_label')],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', $password1_id],
		['a', 'id', $password1_id],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', $password2_id],
		['d', $self->_text('password2_label')],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', $password2_id],
		['a', 'id', $password2_id],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'change_password'],
		['a', 'value', 'change_password'],
		['d', $self->_text('submit')],
		['e', 'button'],
		['e', 'p'],

		['e', 'fieldset'],
	);

	$self->{'_tags_messages'}->process($self->{'_messages'});

	$self->{'tags'}->put(
		['e', 'form'],
	);

	return;
}

# Process 'CSS::Struct'.
sub _process_css {
	my $self = shift;

	$self->{'css'}->put(
		['s', '.'.$self->{'css_change_password'}],
		['d', 'width', $self->{'width'}],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'box-shadow', '0 0 10px rgba(0, 0, 0, 0.2)'],
		['e'],

		['s', '.'.$self->{'css_change_password'}.' fieldset'],
		['d', 'border', 'none'],
		['d', 'padding', 0],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.'.$self->{'css_change_password'}.' legend'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.'.$self->{'css_change_password'}.' p'],
		['d', 'margin', 0],
		['d', 'padding', '10px 0'],
		['e'],

		['s', '.'.$self->{'css_change_password'}.' label'],
		['d', 'display', 'block'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '5px'],
		['e'],

		['s', '.'.$self->{'css_change_password'}.' input[type="text"]'],
		['s', '.'.$self->{'css_change_password'}.' input[type="password"]'],
		['d', 'width', '100%'],
		['d', 'padding', '8px'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '3px'],
		['e'],

		['s', '.'.$self->{'css_change_password'}.' button[type="submit"]'],
		['d', 'width', '100%'],
		['d', 'padding', '10px'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', '#fff'],
		['d', 'border', 'none'],
		['d', 'border-radius', '3px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', '.'.$self->{'css_change_password'}.' button[type="submit"]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', '.'.$self->{'css_change_password'}.' .messages'],
		['d', 'text-align', 'center'],
		['e'],
	);

	$self->{'_tags_messages'}->process_css($self->{'_message_types'});

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

Tags::HTML::ChangePassword - Tags helper for change password.

=head1 SYNOPSIS

 use Tags::HTML::ChangePassword;

 my $obj = Tags::HTML::ChangePassword->new(%params);
 $obj->cleanup;
 $obj->prepare($message_types_hr);
 $obj->init($messages_ar);
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::ChangePassword->new(%params);

Constructor.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<css_change_password>

CSS class for form.

Default value is 'form-change-password'.

=item * C<form_method>

Form method.

Possible values are 'post' and 'get'.

Default value is 'post'.

=item * C<lang>

Language in ISO 639-3 code.

Default value is 'eng'.

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
                'change_password' => 'Change password',
                'old_password_label' => 'Old password',
                'password1_label' => 'New password',
                'password2_label' => 'Confirm new password',
                'submit' => 'Save Changes',
 	},
 }

=back

Returns instance of object.

=head2 C<cleanup>

 $obj->cleanup;

Process cleanup after page run.

Returns undef.

=head2 C<init>

 $obj->init($messages_ar);

Initialize object.
Variable C<$message_ar> is reference to array with L<Data::Message::Simple>
instances.

Returns undef.

=head2 C<prepare>

 $obj->prepare($message_types_hr);

Prepare object.
Variable C<$message_types_hr> is reference to hash with message type keys and
CSS color as value. Message types are defined in L<Data::Message::Simple>.

Returns undef.

=head2 C<process>

 $obj->process;

Process Tags structure for register form.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process CSS::Struct structure for register form.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 init():
         No messages to init.

 prepare():
         No message types to init.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.
         Bad message data object.
         Text for lang '%s' and key '%s' doesn't exist.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.
         Message types must be a hash reference.

=head1 EXAMPLE1

=for comment filename=print_block_html_and_css.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::ChangePassword;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::ChangePassword->new(
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
 # .form-change-password {
 # 	width: 300px;
 # 	background-color: #f2f2f2;
 # 	padding: 20px;
 # 	border-radius: 5px;
 # 	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
 # }
 # .form-change-password fieldset {
 # 	border: none;
 # 	padding: 0;
 # 	margin-bottom: 20px;
 # }
 # .form-change-password legend {
 # 	font-weight: bold;
 # 	margin-bottom: 10px;
 # }
 # .form-change-password p {
 # 	margin: 0;
 # 	padding: 10px 0;
 # }
 # .form-change-password label {
 # 	display: block;
 # 	font-weight: bold;
 # 	margin-bottom: 5px;
 # }
 # .form-change-password input[type="text"], .form-change-password input[type="password"] {
 # 	width: 100%;
 # 	padding: 8px;
 # 	border: 1px solid #ccc;
 # 	border-radius: 3px;
 # }
 # .form-change-password button[type="submit"] {
 # 	width: 100%;
 # 	padding: 10px;
 # 	background-color: #4CAF50;
 # 	color: #fff;
 # 	border: none;
 # 	border-radius: 3px;
 # 	cursor: pointer;
 # }
 # .form-change-password button[type="submit"]:hover {
 # 	background-color: #45a049;
 # }
 # .form-change-password .messages {
 # 	text-align: center;
 # }
 # 
 # HTML
 # <form class="form-change-password" method="post">
 #   <fieldset>
 #     <legend>
 #       Change password
 #     </legend>
 #     <p>
 #       <label for="old_password">
 #       </label>
 #       Old password
 #       <input type="password" name="old_password" id="old_password" autofocus=
 #         "autofocus">
 #       </input>
 #     </p>
 #     <p>
 #       <label for="password1">
 #         New password
 #       </label>
 #       <input type="password" name="password1" id="password1">
 #       </input>
 #     </p>
 #     <p>
 #       <label for="password2">
 #         Confirm new password
 #       </label>
 #       <input type="password" name="password2" id="password2">
 #       </input>
 #     </p>
 #     <p>
 #       <button type="submit" name="change_password" value="change_password">
 #         Save Changes
 #       </button>
 #     </p>
 #   </fieldset>
 # </form>

=head1 EXAMPLE2

=for comment filename=plack_app_change_password.pl

 use strict;
 use warnings;
 
 use CSS::Struct::Output::Indent;
 use Plack::App::Tags::HTML;
 use Plack::Runner;
 use Tags::HTML::ChangePassword;
 use Tags::Output::Indent;
 use Unicode::UTF8 qw(decode_utf8);
 
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
         'preserved' => ['style'],
 );
 my $register = Tags::HTML::ChangePassword->new(
         'css' => $css,
         'tags' => $tags,
 );
 $register->process_css;
 my $app = Plack::App::Tags::HTML->new(
         'component' => 'Tags::HTML::Container',
         'data' => [sub {
                 my $self = shift;
                 $register->process;
                 return;
         }],
         'css' => $css,
         'tags' => $tags,
 )->to_app;
 Plack::Runner->new->run($app);

 # Output screenshot is in images/ directory.

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-ChangePassword/master/images/plack_app_change_password.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-ChangePassword/master/images/plack_app_change_password.png" alt="Web app example" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::Util>,
L<Readonly>,
L<Tags::HTML>,
L<Tags::HTML::Messages>.

=head1 SEE ALSO

=over

=item L<Tags::HTML::Login::Access>

Tags helper for login access.

=item L<Tags::HTML::Login::Button>

Tags helper for login button.

=item L<Tags::HTML::Login::Register>

Tags helper for login register.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-ChangePassword>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
