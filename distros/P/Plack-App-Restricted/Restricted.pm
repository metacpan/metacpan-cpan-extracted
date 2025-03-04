package Plack::App::Restricted;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

use Plack::Util::Accessor qw(label);
use Tags::HTML::Container;

our $VERSION = 0.01;

sub _css {
	my ($self, $env) = @_;

	$self->{'_tags_html_container'}->process_css;

	$self->{'css'}->put(
		['s', '.restricted'],
		['d', 'color', 'red'],
		['d', 'font-family', 'sans-serif'],
		['d', 'font-size', '3em'],
		['e'],
	);

	return;
}

sub _prepare_app {
	my $self = shift;

	# Inherite defaults.
	$self->SUPER::_prepare_app;

	if (! defined $self->label) {
		$self->label('Restricted access');
	}

	$self->{'_tags_html_container'} = Tags::HTML::Container->new(
		'css' => $self->css,
		'tags' => $self->tags,
	);

	return;
}

sub _tags_middle {
	my ($self, $env) = @_;

	my $label = $self->label;
	$self->{'_tags_html_container'}->process(
		sub {
			my $self = shift;

			$self->{'tags'}->put(
				['b', 'div'],
				['a', 'class', 'restricted'],
				['d', $label],
				['e', 'div'],
			);

			return;
		},
	);

	return;
}


1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Restricted - Plack application for restricted state.

=head1 SYNOPSIS

 use Plack::App::Restricted;

 my $obj = Plack::App::Restricted->new(%parameters);
 my $psgi_ar = $obj->call($env);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::Restricted->new(%parameters);

Constructor.

=over 8

=item * C<author>

Author string to HTML head.

Default value is undef.

=item * C<content_type>

Content type for output.

Default value is 'text/html; charset=__ENCODING__'.

=item * C<css>

Instance of CSS::Struct::Output object.

Default value is CSS::Struct::Output::Raw instance.

=item * C<css_init>

Reference to array with CSS::Struct structure.

Default value is CSS initialization from Tags::HTML::Page::Begin like

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

Default value is 'Plack::App::Register; Version: __VERSION__'.

=item * C<label>

Restricted label.

Default value is 'Restricted access'.

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

Instance of Tags::Output object.

Default value is

 Tags::Output::Raw->new(
         'xml' => 1,
         'no_simple' => ['script', 'textarea'],
         'preserved' => ['pre', 'style'],
 );

=item * C<title>

Page title.

Default value is 'Register page'.

=back

Returns instance of object.

=head2 C<call>

 my $psgi_ar = $obj->call($env);

Implementation of env dump.

Returns reference to array (PSGI structure).

=head2 C<to_app>

 my $app = $obj->to_app;

Creates Plack application.

Returns Plack::Component object.

=head1 EXAMPLE

=for comment filename=plack_app_restricted.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Plack::App::Restricted;
 use Plack::Runner;
 use Tags::Output::Indent;

 # Run application.
 my $app = Plack::App::Restricted->new(
         'css' => CSS::Struct::Output::Indent->new,
         'tags' => Tags::Output::Indent->new(
                 'preserved' => ['style'],
         ),
 )->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
 #     </meta>
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0">
 #     </meta>
 #     <style type="text/css">
 # .container {
 # 	position: fixed;
 # 	top: 50%;
 # 	left: 50%;
 # 	transform: translate(-50%, -50%);
 # }
 # .inner {
 # 	text-align: center;
 # }
 # .restricted {
 # 	color: red;
 # 	font-family: sans-serif;
 # 	font-size: 3em;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <div class="container">
 #       <div class="inner">
 #         <div class="restricted">
 #           Restricted access
 #         </div>
 #       </div>
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Plack::Component::Tags::HTML>,
L<Plack::Util::Accessor>,
L<Tags::HTML::Container>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Restricted>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
