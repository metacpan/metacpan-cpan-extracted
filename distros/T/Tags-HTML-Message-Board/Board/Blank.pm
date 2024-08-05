package Tags::HTML::Message::Board::Blank;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils 0.06 qw(set_params split_params);
use Data::HTML::Element::Button;
use Data::HTML::Element::Textarea;
use Error::Pure qw(err);
use Mo::utils 0.01 qw(check_required);
use Mo::utils::CSS 0.02 qw(check_css_class);
use Mo::utils::Language 0.05 qw(check_language_639_2);
use Readonly;
use Tags::HTML::Element::Button;
use Tags::HTML::Element::Textarea;

Readonly::Array our @TEXT_KEYS => qw(add_message_board save);
Readonly::Scalar our $CSS_CLASS_ADD_COMMENT => 'add-comment';

our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_class', 'lang', 'text'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS class.
	$self->{'css_class'} = 'message-board-blank';

	# Language.
	$self->{'lang'} = 'eng';

	# Language texts.
	$self->{'text'} = {
		'eng' => {
			'add_message_board' => 'Add message board',
			'save' => 'Save',
		},
	};

	# Process params.
	set_params($self, @{$object_params_ar});

	# Check 'css_class'.
	check_required($self, 'css_class');
	check_css_class($self, 'css_class');

	# Check lang.
	check_language_639_2($self, 'lang');

	# Check text.
	if (! defined $self->{'text'}) {
		err "Parameter 'text' is required.";
	}
	if (ref $self->{'text'} ne 'HASH') {
		err "Parameter 'text' must be a hash with language texts.";
	}
	if (! exists $self->{'text'}->{$self->{'lang'}}) {
		err "Texts for language '$self->{'lang'}' doesn't exist.";
	}
	if (@TEXT_KEYS != keys %{$self->{'text'}->{$self->{'lang'}}}) {
		err "Number of texts isn't same as expected.";
	}
	foreach my $req_text_key (@TEXT_KEYS) {
		if (! exists $self->{'text'}->{$self->{'lang'}}->{$req_text_key}) {
			err "Text for lang '$self->{'lang'}' and key '$req_text_key' doesn't exist.";
		}
	}

	my %c = (
		'css' => $self->{'css'},
		'tags' => $self->{'tags'},
	);
	$self->{'_tags_textarea'} = Tags::HTML::Element::Textarea->new(%c);
	my $data_textarea = Data::HTML::Element::Textarea->new(
		'autofocus' => 1,
		'id' => 'message_board_message',
		'name' => 'message_board_message',
		'rows' => 6,
	);
	$self->{'_tags_textarea'}->init($data_textarea);

	$self->{'_tags_button'} = Tags::HTML::Element::Button->new(%c);
	my $data_button = Data::HTML::Element::Button->new(
		'data' => [
			$self->_text('save'),
		],
		'name' => 'action',
		'type' => 'submit',
		'value' => 'add_message_board',
	);
	$self->{'_tags_button'}->init($data_button);

	# Object.
	return $self;
}

sub _process {
	my $self = shift;

	$self->{'tags'}->put(
		['b', 'div'],
		['a', 'class', $self->{'css_class'}],
		['b', 'div'],
		['a', 'class', 'new-message-board'],
		['b', 'div'],
		['a', 'class', 'title'],
		['d', $self->_text('add_message_board')],
		['e', 'div'],
		['b', 'form'],
		['a', 'method', 'post'],
	);
	$self->{'_tags_textarea'}->process;
	$self->{'_tags_button'}->process;
	$self->{'tags'}->put(
		['e', 'form'],
		['e', 'div'],
		['e', 'div'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	$self->{'_tags_textarea'}->process_css;
	$self->{'_tags_button'}->process_css;
	$self->{'css'}->put(
		['s', '.'.$self->{'css_class'}],
		['d', 'margin', '1em'],
		['e'],

		['s', '.'.$self->{'css_class'}.' .new-message-board'],
		['d', 'font-family', 'Arial, Helvetica, sans-serif'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.'.$self->{'css_class'}.' .title'],
		['d', 'margin-top', '20px'],
		['d', 'font-weight', 'bold'],
		['d', 'font-size', '1.2em'],
		['e'],

		# Rewrite default Tags::HTML::Element::Button CSS.
		['s', 'button'],
		['d', 'margin', 0],
		['e'],
	);

	return;
}

sub _text {
	my ($self, $key) = @_;

	return $self->{'text'}->{$self->{'lang'}}->{$key};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Message::Board::Blank - Tags helper for message board blank page.

=head1 SYNOPSIS

 use Tags::HTML::Message::Board::Blank;

 my $obj = Tags::HTML::Message::Board::Blank->new(%params);
 $obj->cleanup;
 $obj->init;
 $obj->preapre;
 $obj->process;
 $obj->process_css;

=head1 DESCRIPTION

L<Tags> helper to print HTML page of blank message board.

The page contains form to create message board and save button to save.

This helper is created for usage in L<Plack::App::Message::Board> plack
application which is full application for page.

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Message::Board::Blank->new(%params);

Constructor.

=over 8

=item * C<css>

L<CSS::Struct::Output> object for L<process_css> processing.

Default value is undef.

=item * C<css_class>

CSS class for message board.

Default value is 'message-board'.

=item * C<lang>

Language in ISO 639-3 code.

Default value is 'eng'.

=item * C<tags>

L<Tags::Output> object.

Default value is undef.

=item * C<text>

Hash reference with keys defined language in ISO 639-2 code and value with hash
reference with texts.

Required keys are 'add_comment', 'author', 'date' and 'save'.

Default value is:

 {
 	'eng' => {
                'add_message_board' => 'Add message board',
                'save' => 'Save',
 	},
 }

=back

Returns instance of object.

=head2 C<cleanup>

 $obj->cleanup;

Process cleanup after page run.

Do nothing in this class.

Returns undef.

=head2 C<init>

 $obj->init;

Initialize object.

Do nothing in this class.

Returns undef.

=head2 C<prepare>

 $obj->prepare;

Prepare object.

Do nothing in this class.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure for message board.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure for message board.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Mo::utils::Language::check_language_639_2():
                 Parameter 'lang' doesn't contain valid ISO 639-2 code.
                         Codeset: %s
                         Value: %s
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.
         Number of texts isn't same as expected.
         Parameter 'text' is required.
         Parameter 'text' must be a hash with language texts.
         Texts for language '%s' doesn't exist.
         Text for lang '%s' and key '%s' doesn't exist.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE1

=for comment filename=print_message_board_blank_html_and_css.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Message::Board::Blank;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'no_simple' => ['textarea'],
         'preserved' => ['style', 'textarea'],
         'xml' => 1,
 );
 my $obj = Tags::HTML::Message::Board::Blank->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Process message board.
 $obj->process_css;
 $obj->process;

 # Print out.
 print "CSS\n";
 print $css->flush."\n\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # CSS
 # textarea {
 #         width: 100%;
 #         padding: 12px 20px;
 #         margin: 8px 0;
 #         display: inline-block;
 #         border: 1px solid #ccc;
 #         border-radius: 4px;
 #         box-sizing: border-box;
 # }
 # button {
 #         width: 100%;
 #         background-color: #4CAF50;
 #         color: white;
 #         padding: 14px 20px;
 #         margin: 8px 0;
 #         border: none;
 #         border-radius: 4px;
 #         cursor: pointer;
 # }
 # button:hover {
 #         background-color: #45a049;
 # }
 # .message-board-blank {
 #         max-width: 600px;
 #         margin: auto;
 # }
 # .message-board-blank .title {
 #         margin-top: 20px;
 #         font-weight: bold;
 #         font-size: 1.2em;
 # }
 # button {
 #         margin: 0;
 # }
 # 
 # HTML
 # <div class="message-board-blank">
 #   <div class="title">
 #     Add message board
 #   </div>
 #   <form method="post">
 #     <textarea autofocus="autofocus" rows="6"></textarea>    <button type="button">
 #       Save
 #     </button>
 #   </form>
 # </div>

=head1 EXAMPLE2

=for comment filename=plack_app_message_board_blank.pl

 use strict;
 use warnings;
 
 use CSS::Struct::Output::Indent;
 use Plack::App::Tags::HTML;
 use Plack::Runner;
 use Tags::HTML::Message::Board::Blank;
 use Tags::Output::Indent;
 
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'no_simple' => ['textarea'],
         'preserved' => ['style', 'textarea'],
         'xml' => 1,
 );
 my $message_board_blank = Tags::HTML::Message::Board::Blank->new(
         'css' => $css,
         'tags' => $tags,
 );
 $message_board_blank->process_css;
 my $app = Plack::App::Tags::HTML->new(
         'component' => 'Tags::HTML::Container',
         'data' => [sub {
                 my $self = shift;
                 $message_board_blank->process_css;
                 $message_board_blank->process;
                 return;
         }],
         'css' => $css,
         'tags' => $tags,
 )->to_app;
 Plack::Runner->new->run($app);

 # Output screenshot is in images/ directory.

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Message-Board/master/images/plack_app_message_board_blank.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Message-Board/master/images/plack_app_message_board_blank.png" alt="Web app example" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Class::Utils>,
L<Data::HTML::Element::Button>,
L<Data::HTML::Element::Textarea>,
L<Error::Pure>,
L<Mo::utils>,
L<Mo::utils::CSS>,
L<Mo::utils::Language>,
L<Readonly>,
L<Tags::HTML>,
L<Tags::HTML::Element::Button>,
L<Tags::HTML::Element::Textarea>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Message-Board>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
