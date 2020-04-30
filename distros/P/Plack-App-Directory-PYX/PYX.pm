package Plack::App::Directory::PYX;

use base qw(Plack::App::Directory);
use strict;
use warnings;

use PYX::SGML::Tags;
use Plack::Util::Accessor qw(indent);
use Tags::Output::Indent;
use Tags::Output::Raw;
use Unicode::UTF8 qw(encode_utf8);

our $VERSION = 0.02;

sub serve_path {
	my ($self, $env, $path_to_file_or_dir) = @_;

	if (-d $path_to_file_or_dir) {
		return [
			200,
			[
				'Content-Type' => 'text/plain',
			],
			['DIR'],
		];
	}

	my $tags;
	if ($self->indent) {
		$tags = Tags::Output::Indent->new;
	} else {
		$tags = Tags::Output::Raw->new;
	}
	my $pyx = PYX::SGML::Tags->new(
		'tags' => $tags,
	);

	$pyx->parse_file($path_to_file_or_dir);

	return [
		200,
		[
			'Content-Type' => 'text/html',
		],
		[encode_utf8($tags->flush)],
	];
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Directory::PYX - Plack PYX directory application.

=head1 SYNOPSIS

 use Plack::App::Directory::PYX;

 my $obj = Plack::App::File->new(%parameters);
 my $psgi_ar = $obj->serve_path($env, $path_to_file_or_dir);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::File->new(%parameters);

Constructor.

Returns instance of object.

=over

=item * C<indent>

Set indent of SGML output.

=back

=head2 C<serve_path>

 my $psgi_ar = $obj->serve_path($env, $path_to_file_or_dir);

Process file or directory on disk and serve it to application.

Returns reference to array (PSGI structure).

=head2 C<to_app>

 my $app = $obj->to_app;

Creates Plack application.

Returns Plack::Component object.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use File::Temp;
 use IO::Barf;
 use Plack::App::Directory::PYX;
 use Plack::Runner;

 # Temporary file with PYX.
 my $temp_pyx_file = File::Temp->new->filename;

 # PYX file.
 my $pyx = <<'END';
 (html
 (head
 (title
 -Title
 )title
 )head
 (body
 (div
 -Hello world
 )div
 )body
 )html
 END
 barf($temp_pyx_file, $pyx);

 # Run application with one PYX file.
 my $app = Plack::App::Directory::PYX->new('file' => $temp_pyx_file)->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # <html><head><title>Title</title></head><body><div>Hello world</div></body></html>

=head1 EXAMPLE2

 use strict;
 use warnings;

 use File::Temp;
 use IO::Barf;
 use Plack::App::Directory::PYX;
 use Plack::Runner;

 # Temporary file with PYX.
 my $temp_pyx_file = File::Temp->new->filename;

 # PYX file.
 my $pyx = <<'END';
 (html
 (head
 (title
 -Title
 )title
 )head
 (body
 (div
 -Hello world
 )div
 )body
 )html
 END
 barf($temp_pyx_file, $pyx);

 # Run application with one PYX file.
 my $app = Plack::App::Directory::PYX->new(
         'file' => $temp_pyx_file,
         'indent' => 1,
 )->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # <html>
 #   <head>
 #     <title>
 #       Title
 #     </title>
 #   </head>
 #   <body>
 #     <div>
 #       Hello world
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Plack::App::Directory>,
L<PYX::SGML::Tags>,
L<Tags::Output::Raw>,
L<Unicode::UTF8>,

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Directory-PYX>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2016-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
