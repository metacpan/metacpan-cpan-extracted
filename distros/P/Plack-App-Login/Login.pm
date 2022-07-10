package Plack::App::Login;

use base qw(Plack::Component);
use strict;
use warnings;

use CSS::Struct::Output::Raw;
use Plack::Util::Accessor qw(css generator login_link login_title tags title);
use Tags::HTML::Login::Button;
use Tags::HTML::Page::Begin;
use Tags::HTML::Page::End;
use Tags::Output::Raw;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

our $VERSION = 0.04;

sub call {
	my ($self, $env) = @_;

	$self->_tags;
	$self->tags->finalize;
	my $content = encode_utf8($self->tags->flush(1));

	return [
		200,
		[
			'content-type' => 'text/html; charset=utf-8',
		],
		[$content],
	];
}

sub prepare_app {
	my $self = shift;

	if (! $self->css || ! $self->css->isa('CSS::Struct::Output')) {
		$self->css(CSS::Struct::Output::Raw->new);
	}

	if (! $self->tags || ! $self->tags->isa('Tags::Output')) {
		$self->tags(Tags::Output::Raw->new('xml' => 1));
	}

	if (! $self->generator) {
		$self->generator(__PACKAGE__.'; Version: '.$VERSION);
	}

	if (! $self->title) {
		$self->title('Login page');
	}

	if (! $self->login_link) {
		$self->login_link('login');
	}

	if (! $self->login_title) {
		$self->login_title('LOGIN');
	}

	# Tags helper for login button.
	$self->{'_login_button'} = Tags::HTML::Login::Button->new(
		'css' => $self->css,
		'link' => $self->login_link,
		'tags' => $self->tags,
		'title' => $self->login_title,
	);

	return;
}

sub _css {
	my $self = shift;

	$self->{'_login_button'}->process_css;

	return;
}

sub _tags {
	my $self = shift;

	$self->_css;

	Tags::HTML::Page::Begin->new(
		'css' => $self->css,
		'generator' => $self->generator,
		'lang' => {
			'title' => $self->title,
		},
		'tags' => $self->tags,
	)->process;
	$self->{'_login_button'}->process;
	Tags::HTML::Page::End->new(
		'tags' => $self->tags,
	)->process;

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Login - Plack login application.

=head1 SYNOPSIS

 use Plack::App::Login;

 my $obj = Plack::App::Login->new(%parameters);
 my $psgi_ar = $obj->call($env);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::Login->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<css>

Instance of CSS::Struct::Output object.

Default value is CSS::Struct::Output::Raw instance.

=item * C<generator>

HTML generator string.

Default value is 'Plack::App::Login; Version: __VERSION__'.

=item * C<login_link>

Login link.

Default value is 'login'.

=item * C<login_title>

Login title.

Default value is 'LOGIN'.

=item * C<tags>

Instance of Tags::Output object.

Default value is Tags::Output::Raw->new('xml' => 1) instance.

=item * C<title>

Page title.

Default value is 'Login page'.

=back

=head2 C<call>

 my $psgi_ar = $obj->call($env);

Implementation of login page.

Returns reference to array (PSGI structure).

=head2 C<to_app>

 my $app = $obj->to_app;

Creates Plack application.

Returns Plack::Component object.

=head1 EXAMPLE

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Plack::App::Login;
 use Plack::Runner;
 use Tags::Output::Indent;

 # Run application.
 my $app = Plack::App::Login->new(
         'css' => CSS::Struct::Output::Indent->new,
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
 # <html>
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
 #     <meta charset="UTF-8" />
 #     <meta name="generator" content=
 #       "Perl module: Tags::HTML::Page::Begin, Version: 0.08" />
 #     <title>
 #       Login page
 #     </title>
 #     <style type="text/css">
 # .outer {
 #         position: fixed;
 #         top: 50%;
 #         left: 50%;
 #         transform: translate(-50%, -50%);
 # }
 # .login {
 #         text-align: center;
 #         background-color: blue;
 #         padding: 1em;
 # }
 # .login a {
 #         text-decoration: none;
 #         color: white;
 #         font-size: 3em;
 # }
 # </style>
 #   </head>
 #   <body class="outer">
 #     <div class="login">
 #       <a href="login">
 #         LOGIN
 #       </a>
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<CSS::Struct::Output::Raw>,
L<Plack::Util::Accessor>,
L<Tags::HTML::Login::Button>,
L<Tags::HTML::Page::Begin>,
L<Tags::HTML::Page::End>,
L<Tags::Output::Raw>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Login>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
