package Tags::HTML::Login::Button;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['link', 'title'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Login button link.
	$self->{'link'} = 'login';

	# Login button title.
	$self->{'title'} = 'LOGIN';

	# Process params.
	set_params($self, @{$object_params_ar});

	# Object.
	return $self;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	# Main content.
	$self->{'tags'}->put(
		['a', 'class', 'outer'],

		['b', 'div'],
		['a', 'class', 'login'],
		['b', 'a'],
		['a', 'href', $self->{'link'}],
		['d', $self->{'title'}],
		['e', 'a'],
		['e', 'div'],
	);

	return;
}

# Process 'CSS::Struct'.
sub _process_css {
	my $self = shift;

	$self->{'css'}->put(
		['s', '.outer'],
		['d', 'position', 'fixed'],
		['d', 'top', '50%'],
		['d', 'left', '50%'],
		['d', 'transform', 'translate(-50%, -50%)'],
		['e'],

		['s', '.login'],
		['d', 'text-align', 'center'],
		['e'],

		['s', '.login a'],
		['d', 'text-decoration', 'none'],
		['d', 'background-image', 'linear-gradient(to bottom,#fff 0,#e0e0e0 100%)'],
		['d', 'background-repeat', 'repeat-x'],
		['d', 'border', '1px solid #adadad'],
		['d', 'border-radius', '4px'],
		['d', 'color', 'black'],
		['d', 'font-family', 'sans-serif!important'],
		['d', 'padding', '15px 40px'],
		['e'],

		['s', '.login a:hover'],
		['d', 'background-color', '#e0e0e0'],
		['d', 'background-image', 'none'],
		['e'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Login::Button - Tags helper for login button.

=head1 SYNOPSIS

 use Tags::HTML::Login::Button;

 my $obj = Tags::HTML::Login::Button->new(%params);
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Login::Button->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<link>

Login button link.

Default value is 'login'.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=item * C<title>

Login button title.

Default value is 'LOGIN'.

=back

=head2 C<process>

 $obj->process($percent_value);

Process Tags structure for gradient.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process CSS::Struct structure for output.

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

=for comment filename=button_html_css.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Login::Button;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Login::Button->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Process login button.
 $obj->process_css;
 $tags->put(['b', 'body']);
 $obj->process;
 $tags->put(['e', 'body']);

 # Print out.
 print "CSS\n";
 print $css->flush."\n\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # CSS
 # .outer {
 #         position: fixed;
 #         top: 50%;
 #         left: 50%;
 #         transform: translate(-50%, -50%);
 # }
 # .login {
 #         text-align: center;
 # }
 # .login a {
 #         text-decoration: none;
 #         background-image: linear-gradient(to bottom,#fff 0,#e0e0e0 100%);
 #         background-repeat: repeat-x;
 #         border: 1px solid #adadad;
 #         border-radius: 4px;
 #         color: black;
 #         font-family: sans-serif!important;
 #         padding: 15px 40px;
 # }
 # .login a:hover {
 #         background-color: #e0e0e0;
 #         background-image: none;
 # }
 #
 # HTML
 # <body class="outer">
 #   <div class="login">
 #     <a href="login">
 #       LOGIN
 #     </a>
 #   </div>
 # </body>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Tags::HTML>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Login-Button>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
