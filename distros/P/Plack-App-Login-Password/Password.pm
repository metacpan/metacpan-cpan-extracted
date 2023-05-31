package Plack::App::Login::Password;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

use Plack::Util::Accessor qw(generator register_link title);
use Tags::HTML::Container;
use Tags::HTML::Login::Access;

our $VERSION = 0.01;

sub _css {
	my $self = shift;

	$self->{'_container'}->process_css;
	$self->{'_login_access'}->process_css;

	return;
}

sub _prepare_app {
	my $self = shift;

	# Defaults which rewrite defaults in module which I am inheriting.
	if (! defined $self->generator) {
		$self->generator(__PACKAGE__.'; Version: '.$VERSION);
	}

	if (! defined $self->title) {
		$self->title('Login page');
	}

	# Inherite defaults.
	$self->SUPER::_prepare_app;

	# Defaults from this module.
	my %p = (
		'css' => $self->css,
		'tags' => $self->tags,
	);

	# Tags helper for login button.
	$self->{'_login_access'} = Tags::HTML::Login::Access->new(
		%p,
		'register_url' => $self->register_link,
	);

	$self->{'_container'} = Tags::HTML::Container->new(
		%p,
	);

	return;
}

sub _tags_middle {
	my $self = shift;

	$self->{'_container'}->process(
		sub {
			$self->{'_login_access'}->process;
		},
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Login::Password - Plack login/password application.

=head1 SYNOPSIS

 use Plack::App::Login::Password;

 my $obj = Plack::App::Login::Password->new(%parameters);
 my $psgi_ar = $obj->call($env);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::Login::Password->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<css>

Instance of CSS::Struct::Output object.

Default value is CSS::Struct::Output::Raw instance.

=item * C<generator>

HTML generator string.

Default value is 'Plack::App::Login; Version: __VERSION__'.

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

=for comment filename=login_password_psgi.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Plack::App::Login::Password;
 use Plack::Runner;
 use Tags::Output::Indent;

 # Run application.
 my $app = Plack::App::Login::Password->new(
         'css' => CSS::Struct::Output::Indent->new,
         'generator' => 'Plack::App::Login::Password',
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
 #     <meta name="generator" content="Plack::App::Login::Password"
 #       />
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
 #     <title>
 #       Login page
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
 # </style>
 #   </head>
 #   <body>
 #     <div class="container">
 #       <div class="inner">
 #         <form class="form-login" method="post">
 #           <fieldset>
 #             <legend>
 #               Login
 #             </legend>
 #             <p>
 #               <label for="username" />
 #               User name
 #               <input type="text" name="username" id="username" />
 #             </p>
 #             <p>
 #               <label for="password">
 #                 Password
 #               </label>
 #               <input type="password" name="password" id="password" />
 #             </p>
 #             <p>
 #               <button type="submit" name="login" value="login">
 #                 Login
 #               </button>
 #             </p>
 #           </fieldset>
 #         </form>
 #       </div>
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Plack::Util::Accessor>,
L<Plack::Component::Tags::HTML>,
L<Tags::HTML::Login::Password>.

=head1 SEE ALSO

=over

=item L<Plack::App::Login>

Plack login application.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Login-Password>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
