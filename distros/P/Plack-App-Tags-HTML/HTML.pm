package Plack::App::Tags::HTML;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

use English;
use Error::Pure qw(err);
use Plack::Util::Accessor qw(component constructor_args data data_css data_init);
use Symbol::Get;

our $VERSION = 0.11;

sub _css {
	my $self = shift;

	if ($self->{'_component'}->can('process_css')) {
		my @data_css;
		if (defined $self->data_css) {
			push @data_css, @{$self->data_css};
		}

		$self->{'_component'}->process_css(@data_css);
	}

	return;
}

sub _loaded_component {
	my ($self, $component) = @_;

	my @names = eval {
		Symbol::Get::get_names($component);
	};
	if ($EVAL_ERROR) {
		return 0;
	}

	return 1;
}

sub _prepare_app {
	my $self = shift;

	my %p = (
		'css' => $self->css,
		'tags' => $self->tags,
	);

	my $component = $self->component;
	if (! $self->_loaded_component($component)) {
		eval "require $component;";
		if ($EVAL_ERROR) {
			err "Cannot load component '$component'.",
				'Error', $EVAL_ERROR;
		}
	}
	$self->{'_component'} = $component->new(
		%p,
		defined $self->constructor_args ? (
			%{$self->constructor_args},
		) : (),
	);
	if (! $self->{'_component'}->isa('Tags::HTML')) {
		err "Component must be a instance of 'Tags::HTML' class.";
	}

	return;
}

sub _process_actions {
	my $self = shift;

	if ($self->{'_component'}->can('init')) {
		my @data = ();
		if (defined $self->data_init) {
			push @data, @{$self->data_init};
		}
		$self->{'_component'}->init(@data);
	}

	return;
}

sub _tags_middle {
	my $self = shift;

	my @data;
	if (defined $self->data) {
		push @data, @{$self->data};
	}
	$self->{'_component'}->process(@data);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Tags::HTML - Plack application for running Tags::HTML objects.

=head1 SYNOPSIS

 use Plack::App::Tags::HTML;

 my $obj = Plack::App::Tags::HTML->new(%parameters);
 my $app = $obj->to_app;

=head1 METHODS

Class inherites Plack::Component::Tags::HTML.

=head2 C<new>

 my $obj = Plack::App::Tags::HTML->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<component>

Tags::HTML component.

Option is required.

=item * C<constructor_args>

Tags::HTML component constructor arguments.

Default value is undef.

=item * C<data>

Array data structure as input argument of Tags::HTML::process().

Default value is undef.

=item * C<data_css>

Reference to array with structure for input argument of C<Tags::HTML::process_css()>.

Default value is undef.

=item * C<data_init>

Reference to array with structure for input argument of C<Tags::HTML::init()>.

Default value is undef.

=back

=head2 C<to_app>

 my $app = $obj->to_app;

Get code of plack application.

Returns code of app.

=head1 ERRORS

 prepare_app():
         Cannot load component '%s'.
                 Error: %s
         Component must be a instance of 'Tags::HTML' class.

=head1 EXAMPLE1

=for comment filename=web_app_with_stars.pl

 use strict;
 use warnings;

 use Plack::App::Tags::HTML;
 use Plack::Runner;

 # Run application.
 my $app = Plack::App::Tags::HTML->new(
         'component' => 'Tags::HTML::Stars',
         'data' => [{
                 1 => 'full',
                 2 => 'half',
                 3 => 'nothing',
         }],
 )->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # <!DOCTYPE html>
 # <html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><style type="text/css">
 # *{box-sizing:border-box;margin:0;padding:0;}
 # </style></head><body><div><img src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0iI2ZkZmYwMCIgc3Ryb2tlPSIjNjA1YTAwIiBzdHJva2Utd2lkdGg9IjE1IiBwb2ludHM9IjE1MCwyNSAxNzksMTExIDI2OSwxMTEgMTk3LDE2NSAyMjMsMjUxIDE1MCwyMDAgNzcsMjUxIDEwMywxNjUgMzEsMTExIDEyMSwxMTEiIC8+Cjwvc3ZnPgo=" /><img src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPGNsaXBQYXRoIGlkPSJlbXB0eSI+PHJlY3QgeD0iMTUwIiB5PSIwIiB3aWR0aD0iMTUwIiBoZWlnaHQ9IjI3NSIgLz48L2NsaXBQYXRoPgogIDxjbGlwUGF0aCBpZD0iZmlsbGVkIj48cmVjdCB4PSIwIiB5PSIwIiB3aWR0aD0iMTUwIiBoZWlnaHQ9IjI3NSIgLz48L2NsaXBQYXRoPgogIDxwb2x5Z29uIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzgwODA4MCIgc3Ryb2tlLXdpZHRoPSIxNSIgc3Ryb2tlLW9wYWNpdHk9IjAuMzc2NDcwNjAiIHBvaW50cz0iMTUwLDI1IDE3OSwxMTEgMjY5LDExMSAxOTcsMTY1IDIyMywyNTEgMTUwLDIwMCA3NywyNTEgMTAzLDE2NSAzMSwxMTEgMTIxLDExMSIgY2xpcC1wYXRoPSJ1cmwoI2VtcHR5KSIgLz4KICA8cG9seWdvbiBmaWxsPSIjZmRmZjAwIiBzdHJva2U9IiM2MDVhMDAiIHN0cm9rZS13aWR0aD0iMTUiIHBvaW50cz0iMTUwLDI1IDE3OSwxMTEgMjY5LDExMSAxOTcsMTY1IDIyMywyNTEgMTUwLDIwMCA3NywyNTEgMTAzLDE2NSAzMSwxMTEgMTIxLDExMSIgY2xpcC1wYXRoPSJ1cmwoI2ZpbGxlZCkiIC8+Cjwvc3ZnPgo=" /><img src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0ibm9uZSIgc3Ryb2tlPSIjODA4MDgwIiBzdHJva2Utd2lkdGg9IjE1IiBzdHJva2Utb3BhY2l0eT0iMC4zNzY0NzA2MCIgcG9pbnRzPSIxNTAsMjUgMTc5LDExMSAyNjksMTExIDE5NywxNjUgMjIzLDI1MSAxNTAsMjAwIDc3LDI1MSAxMDMsMTY1IDMxLDExMSAxMjEsMTExIiAvPgo8L3N2Zz4K" /></div></body></html>

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Plack-App-Tags-HTML/master/images/ex1.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Plack-App-Tags-HTML/master/images/ex1.png" alt="Example #1 web application" width="300px" height="300px" />
</a>

=end html

=head1 EXAMPLE2

=for comment filename=web_app_with_div.pl

 use strict;
 use warnings;

 package App;

 use base qw(Tags::HTML);

 sub _process {
         my ($self, $value_hr) = @_;

         $self->{'tags'}->put(
                 ['b', 'div'],
                 ['a', 'class', 'my-class'],
                 ['d', join ',', @{$value_hr->{'foo'}}],
                 ['e', 'div'],
         );

         return;
 }

 sub _process_css {
         my $self = shift;

         $self->{'css'}->put(
                 ['s', '.my-class'],
                 ['d', 'border', '1px solid black'],
                 ['e'],
         );

         return;
 }

 package main;

 use Plack::App::Tags::HTML;
 use Plack::Runner;

 # Run application.
 my $app = Plack::App::Tags::HTML->new(
         'component' => 'App',
         'data' => [{
                 'foo' => [1, 2],
         }],
 )->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # <!DOCTYPE html>
 # <html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><style type="text/css">
 # *{box-sizing:border-box;margin:0;padding:0;}.my-class{border:1px solid black;}
 # </style></head><body><div class="my-class">1,2</div></body></html>

=head1 DEPENDENCIES

L<English>,
L<Error::Pure>,
L<Plack::Component::Tags::HTML>,
L<Plack::Util::Accessor>,
L<Symbol::Get>.

=head1 SEE ALSO

=over

=item L<Tags::HTML>

Tags helper abstract class.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Tags-HTML>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.11

=cut
