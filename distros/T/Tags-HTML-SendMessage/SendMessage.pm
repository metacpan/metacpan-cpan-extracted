package Tags::HTML::SendMessage;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Hash my %LANG => (
	'title' => 'Leave us a message',
	'name-and-surname' => 'Name and surname',
	'email' => 'Email',
	'subject' => 'Subject of you question',
	'your-message' => 'Your message',
	'send' => 'Send question',
);

our $VERSION = 0.09;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# 'CSS::Struct' object.
	$self->{'css'} = undef;

	# Languages.
	$self->{'lang'} = \%LANG;

	# 'Tags' object.
	$self->{'tags'} = undef;

	# Process params.
	set_params($self, @params);

	# Check to 'Tags' object.
	if (! $self->{'tags'} || ! $self->{'tags'}->isa('Tags::Output')) {
		err "Parameter 'tags' must be a 'Tags::Output::*' class.";
	}

	# Check to 'CSS::Struct' object.
	if ($self->{'css'} && ! $self->{'css'}->isa('CSS::Struct::Output')) {
		err "Parameter 'css' must be a 'CSS::Struct::Output::*' class.";
	}

	# Object.
	return $self;
}

# Process 'Tags'.
sub process {
	my $self = shift;

	# Begin of page.
	$self->{'tags'}->put(
		['b', 'div'],
		['a', 'id', 'send-message'],

		['b', 'form'],
		['a', 'action', ''],

		['b', 'fieldset'],

		['b', 'legend'],
		['d', $self->{'lang'}->{'title'}],
		['e', 'legend'],
	);
	$self->_tags_form_input('name-and-surname', 1, { 'size' => 30 });
	$self->_tags_form_input('email', 1, { 'size' => 30 });
	$self->_tags_form_input('subject', 1, { 'size' => 72 });
	$self->_tags_form_textarea('your-message', 1, { 'cols' => 75, 'rows' => 10 });
	$self->{'tags'}->put(

		['b', 'input'],
		['a', 'type', 'submit'],
		['a', 'value', $self->{'lang'}->{'send'}],
		['e', 'input'],

		['e', 'fieldset'],
		['e', 'form'],
		['e', 'div'],
	);

	return;
}

sub _tags_form_input {
	my ($self, $id, $br, $input_opts_hr) = @_;

	$self->{'tags'}->put(
		['b', 'label'],
		['a', 'for', $id],
		['d', $self->{'lang'}->{$id}.':'],
		['e', 'label'],

		['b', 'br'],
		['e', 'br'],

		['b', 'input'],
		['a', 'id', $id],
		['a', 'name', $id],
		exists $input_opts_hr->{'size'} ? (
			['a', 'size', $input_opts_hr->{'size'}],
		) : (),
		['e', 'input'],
	);
	if ($br) {
		$self->{'tags'}->put(
			['b', 'br'],
			['e', 'br'],
		);
	}

	return;
}

sub _tags_form_textarea {
	my ($self, $id, $br, $textarea_opts_hr) = @_;

	$self->{'tags'}->put(
		['b', 'label'],
		['a', 'for', $id],
		['d', $self->{'lang'}->{$id}.':'],
		['e', 'label'],

		['b', 'br'],
		['e', 'br'],

		['b', 'textarea'],
		['a', 'id', $id],
		['a', 'name', $id],
		exists $textarea_opts_hr->{'cols'} ? (
			['a', 'cols', $textarea_opts_hr->{'cols'}],
		) : (),
		exists $textarea_opts_hr->{'rows'} ? (
			['a', 'rows', $textarea_opts_hr->{'rows'}],
		) : (),
		['e', 'textarea'],
	);
	if ($br) {
		$self->{'tags'}->put(
			['b', 'br'],
			['e', 'br'],
		);
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::SendMessage - Tags helper for send message form.

=head1 SYNOPSIS

 use Tags::HTML::SendMessage;

 my $obj = Tags::HTML::SendMessage->new(%params);
 $obj->process;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::SendMessage->new(%params);

Constructor.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<lang>

Hash with language information for output.
Keys are: 'title', 'name-and-surname', 'email', 'subject', 'your-message' and 'send'.

Default value is reference to hash with these value:
 'title' => 'Leave us a message',
 'name-and-surname' => 'Name and surname',
 'email' => 'Email',
 'subject' => 'Subject of you question',
 'your-message' => 'Your message',
 'send' => 'Send question',

=item * C<tags>

'Tags::Output' object.

It's required.

Default value is undef.

=back

=head2 C<process>

 $obj->process;

Process Tags structure for output.

Returns undef.

=head1 ERRORS

 new():
         Parameter 'css' must be a 'CSS::Struct::Output::*' class.
         Parameter 'tags' must be a 'Tags::Output::*' class.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Page::Begin;
 use Tags::HTML::Page::End;
 use Tags::HTML::SendMessage;
 use Tags::Output::Indent;

 # Object.
 my $tags = Tags::Output::Indent->new(
         'preserved' => ['style'],
         'xml' => 1,
         'no_simple' => ['textarea'],
 );
 my $begin = Tags::HTML::Page::Begin->new(
         'generator' => 'Tags::HTML::SendMessage EXAMPLE1',
         'tags' => $tags,
 );
 my $send_message = Tags::HTML::SendMessage->new(
         'tags' => $tags,
 );
 my $end = Tags::HTML::Page::End->new(
         'tags' => $tags,
 );

 # Process page
 $begin->process;
 $send_message->process;
 $end->process;

 # Print out.
 print $tags->flush;

 # Output:
 # <!DOCTYPE html>
 # <html>
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
 #     <meta charset="UTF-8" />
 #     <meta name="generator" content="Tags::HTML::SendMessage EXAMPLE1" />
 #     <title>
 #       Page title
 #     </title>
 #   </head>
 #   <body>
 #     <div id="send-message">
 #       <form action="">
 #         <fieldset>
 #           <legend>
 #             Leave us a message
 #           </legend>
 #           <label for="name-and-surname">
 #             Name and surname:
 #           </label>
 #           <br />
 #           <input id="name-and-surname" name="name-and-surname" size="30" />
 #           <br />
 #           <label for="email">
 #             Email:
 #           </label>
 #           <br />
 #           <input id="email" name="email" size="30" />
 #           <br />
 #           <label for="subject">
 #             Subject of you question:
 #           </label>
 #           <br />
 #           <input id="subject" name="subject" size="72" />
 #           <br />
 #           <label for="your-message">
 #             Your message:
 #           </label>
 #           <br />
 #           <textarea id="your-message" name="your-message" cols="75" rows="10">
 #           </textarea>
 #           <br />
 #           <input type="submit" value="Send question" />
 #         </fieldset>
 #       </form>
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-SendMessage>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.09

=cut
