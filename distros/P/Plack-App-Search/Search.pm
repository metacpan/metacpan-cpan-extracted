package Plack::App::Search;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

use Plack::Util::Accessor qw(generator image_height image_link image_radius
	search_method search_placeholder search_title search_url tags_after
	title);
use Tags::HTML::Container;

our $VERSION = 0.05;

sub _prepare_app {
	my $self = shift;

	# Defaults which rewrite defaults in module which I am inheriting.
	if (! $self->generator) {
		$self->generator(__PACKAGE__.'; Version: '.$VERSION);
	}

	if (! $self->title) {
		$self->title('Search page');
	}

	# Inherite defaults.
	$self->SUPER::_prepare_app;

	# Defaults from this module.
	if (! $self->search_method) {
		$self->search_method('get');
	}

	if (! $self->search_url) {
		$self->search_url('https://env.skim.cz');
	}

	$self->{'_container'} = Tags::HTML::Container->new(
		'css' => $self->css,
		'css_inner' => 'search',
		'tags' => $self->tags,
	);

	return;
}

sub _css {
	my $self = shift;

	$self->{'_container'}->process_css;
	if (defined $self->image_link) {
		$self->css->put(
			['s', '.search'],
			['d', 'display', 'flex'],
			['d', 'flex-direction', 'column'],
			['d', 'align-items', 'center'],
			['e'],

			['s', '.search img'],
			['d', 'margin-bottom', '20px'],
			['d', 'margin-left', 'auto'],
			['d', 'margin-right', 'auto'],
			defined $self->image_radius ? (
				['d', 'border-radius', $self->image_radius],
			) : (),
			defined $self->image_height ? (
				['d', 'height', $self->image_height],
			) : (),
			['e'],
		);
	}
	$self->css->put(
		['s', '.search form'],
		['d', 'display', 'flex'],
		['d', 'align-items', 'center'],
		['e'],

		['s', '.search input[type="text"]'],
		['d', 'padding', '10px'],
		['d', 'border-radius', '4px'],
		['d', 'border', '1px solid #ccc'],
		['e'],

		['s', '.search button'],
		['d', 'margin-left', '10px'],
		['d', 'padding', '10px 20px'],
		['d', 'border-radius', '4px'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'border', 'none'],
		['d', 'cursor', 'pointer'],
		! defined $self->search_title ? (
			['d', 'display', 'none'],
		) : (),
		['e'],

		['s', '.search button:hover'],
		['d', 'background-color', '#45a049'],
		['e'],
	);

	return;
}

sub _tags_middle {
	my $self = shift;

	$self->{'_container'}->process(
		sub {
			$self->tags->put(
				$self->image_link ? (
					['b', 'img'],
					['a', 'src', $self->image_link],
					['e', 'img'],
				) : (),
				['b', 'form'],
				['a', 'method', $self->search_method],
				['a', 'action', $self->search_url],
				['b', 'input'],
				['a', 'type', 'text'],
				['a', 'autofocus', 'autofocus'],
				defined $self->search_placeholder ? (
					['a', 'placeholder', $self->search_placeholder],
				) : (),
				['a', 'name', 'search'],
				['e', 'input'],
				['b', 'button'],
				['a', 'type', 'submit'],
				defined $self->search_title ? (
					['d', $self->search_title],
				) : (),
				['e', 'button'],
				['e', 'form'],

				defined $self->tags_after ? (
					@{$self->tags_after},
				) : (),
			);
		},
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Search - Plack search application.

=head1 SYNOPSIS

 use Plack::App::Search;

 my $obj = Plack::App::Search->new(%parameters);
 my $psgi_ar = $obj->call($env);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::Search->new(%parameters);

Constructor.

=over 8

=item * C<css>

Instance of CSS::Struct::Output object.

Default value is CSS::Struct::Output::Raw instance.

=item * C<generator>

HTML generator string.

Default value is 'Plack::App::Search; Version: __VERSION__'

=item * C<image_height>

Image height.

Default value is undef, this mean real height of image.

=item * C<image_link>

URL to image above form. Image is centered.

Default value is undef.

=item * C<image_radius>

CSS radius of image.

Default value is 0.

=item * C<search_method>

Search method.

Default value is 'search'.

=item * C<search_placeholder>

Search placeholder text.

It's optional.

Default value is undef.

=item * C<search_title>

Search title. There will be button with text in this title if is defined.
If not, form is without button.

Default value is undef.

=item * C<search_url>

Search URL.

Default value is 'https://env.skim.cz'.

=item * C<tags>

Instance of Tags::Output object.

Default value is Tags::Output::Raw->new('xml' => 1) instance.

=item * C<tags_after>

Reference to array with L<Tags> code to add after search field.

Default value is undef.

=item * C<title>

Page title.

Default value is 'Login page'.

=back

Returns instance of object.

=head2 C<call>

 my $psgi_ar = $obj->call($env);

Implementation of search page.

Returns reference to array (PSGI structure).

=head2 C<to_app>

 my $app = $obj->to_app;

Creates Plack application.

Returns Plack::Component object.

=head1 EXAMPLE1

=for comment filename=search_app.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Plack::App::Search;
 use Plack::Runner;
 use Tags::Output::Indent;

 # Run application.
 my $app = Plack::App::Search->new(
         'css' => CSS::Struct::Output::Indent->new,
         'generator' => 'Plack::App::Search',
         'tags' => Tags::Output::Indent->new(
                 'preserved' => ['style'],
                 'xml' => 1,
         ),
 )->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 #     <meta name="generator" content="Plack::App::Search" />
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
 #     <title>
 #       Search page
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
 # .search form {
 # 	display: flex;
 # 	align-items: center;
 # }
 # .search input[type="text"] {
 # 	padding: 10px;
 # 	border-radius: 4px;
 # 	border: 1px solid #ccc;
 # }
 # .search button {
 # 	margin-left: 10px;
 # 	padding: 10px 20px;
 # 	border-radius: 4px;
 # 	background-color: #4CAF50;
 # 	color: white;
 # 	border: none;
 # 	cursor: pointer;
 # 	display: none;
 # }
 # .search button:hover {
 # 	background-color: #45a049;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <div class="container">
 #       <div class="search">
 #         <form method="get" action="https://env.skim.cz">
 #           <input type="text" autofocus="autofocus" />
 #           <button type="submit" />
 #         </form>
 #       </div>
 #     </div>
 #   </body>
 # </html>

=head1 EXAMPLE2

=for comment filename=search_app_button.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Plack::App::Search;
 use Plack::Runner;
 use Tags::Output::Indent;

 # Run application.
 my $app = Plack::App::Search->new(
         'css' => CSS::Struct::Output::Indent->new,
         'generator' => 'Plack::App::Search',
         'search_title' => 'Search',
         'tags' => Tags::Output::Indent->new(
                 'preserved' => ['style'],
                 'xml' => 1,
         ),
 )->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 #     <meta name="generator" content="Plack::App::Search" />
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
 #     <title>
 #       Search page
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
 # .search form {
 # 	display: flex;
 # 	align-items: center;
 # }
 # .search input[type="text"] {
 # 	padding: 10px;
 # 	border-radius: 4px;
 # 	border: 1px solid #ccc;
 # }
 # .search button {
 # 	margin-left: 10px;
 # 	padding: 10px 20px;
 # 	border-radius: 4px;
 # 	background-color: #4CAF50;
 # 	color: white;
 # 	border: none;
 # 	cursor: pointer;
 # }
 # .search button:hover {
 # 	background-color: #45a049;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <div class="container">
 #       <div class="search">
 #         <form method="get" action="https://env.skim.cz">
 #           <input type="text" autofocus="autofocus" />
 #           <button type="submit">
 #             Search
 #           </button>
 #         </form>
 #       </div>
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Plack::Component::Tags::HTML>,
L<Plack::Util::Accessor>,
L<Tags::HTML::Container>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Search>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
