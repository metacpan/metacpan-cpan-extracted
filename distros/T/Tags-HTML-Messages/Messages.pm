package Tags::HTML::Messages;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.09;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_messages', 'flag_no_messages'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS class.
	$self->{'css_messages'} = 'messages';

	# Flag for no messages.
	$self->{'flag_no_messages'} = 1;

	# Process params.
	set_params($self, @{$object_params_ar});

	# Object.
	return $self;
}

sub _check_messages {
	my ($self, $message_ar) = @_;

	if (ref $message_ar ne 'ARRAY') {
		err "Bad list of messages.";
	}
	foreach my $message (@{$message_ar}) {
		if (! blessed($message) || ! $message->isa('Data::Message::Simple')) {

			err 'Bad message data object.';
		}
	}

	return;
}

# Process 'Tags'.
sub _process {
	my ($self, $message_ar) = @_;

	if (! defined $message_ar) {
		return;
	}

	$self->_check_messages($message_ar);

	# No messages.
	if (! $self->{'flag_no_messages'} && ! @{$message_ar}) {
		return;
	}

	my $num = 0;
	$self->{'tags'}->put(
		['b', 'div'],
		['a', 'class', $self->{'css_messages'}],
	);
	if (@{$message_ar}) {
		foreach my $message (@{$message_ar}) {
			if ($num) {
				$self->{'tags'}->put(
					['b', 'br'],
					['e', 'br'],
				);
			}
			$self->{'tags'}->put(
				['b', 'span'],
				['a', 'class', $message->type],
				defined $message->lang
					? (['a', 'lang', $message->lang])
					: (),
				['d', $message->text],
				['e', 'span'],
			);
			$num++;
		}
	} else {
		$self->{'tags'}->put(
			['d', 'No messages'],
		);
	}
	$self->{'tags'}->put(
		['e', 'div'],
	);

	return;
}

# Process 'CSS::Struct'.
sub _process_css {
	my ($self, $message_types_hr) = @_;

	if (! defined $message_types_hr) {
		return;
	}
	if (ref $message_types_hr ne 'HASH') {
		err 'Message types must be a hash reference.';
	}

	foreach my $message_type (sort keys %{$message_types_hr}) {
		$self->{'css'}->put(
			['s', '.'.$message_type],
			['d', 'color', $message_types_hr->{$message_type}],
			['e'],
		);
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Messages - Tags helper for HTML messages.

=head1 SYNOPSIS

 use Tags::HTML::Messages;

 my $obj = Tags::HTML::Messages->new(%params);
 $obj->process($message_ar);
 $obj->process_css($type, $color);

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Messages->new(%params);

Constructor.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<css_messages>

CSS class for main messages div block.

Default value is 'messages'.

=item * C<flag_no_messages>

Flag for no messages printing.

Possible values:

 0 - Print nothing
 1 - Print message box with 'No messages.' text.

Default value is 1.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=back

=head2 C<process>

 $obj->process($message_ar);

Process Tags structure for output.

Reference to array with message objects C<$message_ar> must be a instance of
L<Data::Message::Simple> object.

Returns undef.

=head2 C<process_css>

 $obj->process_css($message_types_hr);

Process CSS::Struct structure for output.

Variable C<$message_type_hr> is reference to hash with keys for message type and value for color in CSS style.
Possible message types are info and error now. Types are defined in L<Data::Message::Simple>.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'css' must be a 'CSS::Struct::Output::*' class.
         Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         Bad list of messages.
         Bad message data object.

 process_css():
         Message types must be a hash reference.

=head1 EXAMPLE1

=for comment filename=html_page_with_messages.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::Message::Simple;
 use Tags::HTML::Page::Begin;
 use Tags::HTML::Page::End;
 use Tags::HTML::Messages;
 use Tags::Output::Indent;

 # Object.
 my $tags = Tags::Output::Indent->new(
         'preserved' => ['style'],
         'xml' => 1,
 );
 my $css = CSS::Struct::Output::Indent->new;
 my $begin = Tags::HTML::Page::Begin->new(
         'css' => $css,
         'lang' => {
                 'title' => 'Tags::HTML::Messages example',
         },
         'generator' => 'Tags::HTML::Messages',
         'tags' => $tags,
 );
 my $end = Tags::HTML::Page::End->new(
         'tags' => $tags,
 );
 my $messages = Tags::HTML::Messages->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Error structure.
 my $message_ar = [
         Data::Message::Simple->new(
                 'text' => 'Error #1',
                 'type' => 'error',
         ),
         Data::Message::Simple->new(
                 'text' => 'Error #2',
                 'type' => 'error',
         ),
         Data::Message::Simple->new(
                 'lang' => 'en',
                 'text' => 'Ok #1',
         ),
         Data::Message::Simple->new(
                 'text' => 'Ok #2',
         ),
 ];

 # Process page.
 $messages->process_css({
         'error' => 'red',
         'info' => 'green',
 });
 $begin->process;
 $messages->process($message_ar);
 $end->process;

 # Print out.
 print $tags->flush;

 # Output:
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
 #     <meta name="generator" content="Tags::HTML::Messages" />
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
 #     <title>
 #       Tags::HTML::Messages example
 #     </title>
 #     <style type="text/css">
 # .error {
 #         color: red;
 # }
 # .info {
 #         color: green;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <div class="messages">
 #       <span class="error">
 #         Error #1
 #       </span>
 #       <br />
 #       <span class="error">
 #         Error #2
 #       </span>
 #       <br />
 #       <span class="info" lang="en">
 #         Ok #1
 #       </span>
 #       <br />
 #       <span class="info">
 #         Ok #2
 #       </span>
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Scalar::Util>,
L<Tags::HTML>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Messages>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020-2023

BSD 2-Clause License

=head1 VERSION

0.09

=cut
