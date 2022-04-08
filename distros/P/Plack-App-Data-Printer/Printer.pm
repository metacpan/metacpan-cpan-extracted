package Plack::App::Data::Printer;

use base qw(Plack::Component);
use strict;
use warnings;

use Data::Printer;
use Error::Pure qw(err);
use Plack::Util::Accessor qw(data);

our $VERSION = 0.03;

sub call {
	my ($self, $env) = @_;

	my $output;
	my $data = $self->data;
	p $data, 'output' => \$output;

	return [
		200,
		['Content-Type' => 'text/plain'],
		[$output],
	];
}

sub prepare_app {
	my $self = shift;

	if (! $self->data) {
		err 'No data.';
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Data::Printer - Plack Data::Printer application.

=head1 SYNOPSIS

 use Plack::App::Data::Printer;

 my $obj = Plack::App::Data::Printer->new(%parameters);
 my $psgi_ar = $obj->call($env);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::Data::Printer->new(%parameters);

Constructor.

Returns instance of object.

=head2 C<call>

 my $psgi_ar = $obj->call($env);

Implementation of Data::Printer in plack.

Returns reference to array (PSGI structure).

=head2 C<to_app>

 my $app = $obj->to_app;

Creates Plack application.

Returns Plack::Component object.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Plack::App::Data::Printer;
 use Plack::Runner;

 # Run application.
 my $app = Plack::App::Data::Printer->new(
         'data' => {
                 'example' => [1, 2, {
                         'foo' => 'bar',
                 }, 5],
         },
 )->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # {
 #     example   [
 #         [0] 1,
 #         [1] 2,
 #         [2] {
 #                 foo   "bar"
 #             },
 #         [3] 5
 #     ]
 # }

=head1 DEPENDENCIES

L<Data::Printer>,
L<Error::Pure>,
L<Plack::Component>,
L<Plack::Util::Accessor>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Data-Printer>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
