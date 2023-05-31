package Plack::App::Login;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

use Plack::Util::Accessor qw(generator login_link login_title title);
use Tags::HTML::Login::Button;

our $VERSION = 0.08;

sub _css {
	my $self = shift;

	$self->{'_login_button'}->process_css;

	return;
}

sub _prepare_app {
	my $self = shift;

	# Defaults which rewrite defaults in module which I am inheriting.
	if (! $self->generator) {
		$self->generator(__PACKAGE__.'; Version: '.$VERSION);
	}

	if (! $self->title) {
		$self->title('Login page');
	}

	# Inherite defaults.
	$self->SUPER::_prepare_app;

	# Defaults from this module.
	if (! $self->login_link) {
		$self->login_link('login');
	}

	if (! $self->login_title) {
		$self->login_title('LOGIN');
	}

	# Tags helper for login button.
	$self->{'_login_button'} = Tags::HTML::Login::Button->new(
		'css' => $self->{'css'},
		'link' => $self->login_link,
		'tags' => $self->{'tags'},
		'title' => $self->login_title,
	);

	return;
}

sub _tags_middle {
	my $self = shift;

	$self->{'_login_button'}->process;

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

=for comment filename=login_psgi.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Plack::App::Login;
 use Plack::Runner;
 use Tags::Output::Indent;
 use Unicode::UTF8 qw(decode_utf8);

 # Run application.
 my $app = Plack::App::Login->new(
         'css' => CSS::Struct::Output::Indent->new,
         'generator' => 'Plack::App::Login',
         'login_title' => decode_utf8('Přihlašovací stránka'),
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
 #     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 #     <meta name="generator" content="Plack::App::Login" />
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
 #     <title>
 #       Login page
 #     </title>
 #     <style type="text/css">
 # * {
 #         box-sizing: border-box;
 #         margin: 0;
 #         padding: 0;
 # }
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
 # </style>
 #   </head>
 #   <body class="outer">
 #     <div class="login">
 #       <a href="login">
 #         Přihlašovací stránka
 #       </a>
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Plack::Component::Tags::HTML>,
L<Plack::Util::Accessor>,
L<Tags::HTML::Login::Button>.

=head1 SEE ALSO

=over

=item L<Plack::App::Login::Password>

Plack login/password application.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Login>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.08

=cut
