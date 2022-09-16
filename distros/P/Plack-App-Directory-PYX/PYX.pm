package Plack::App::Directory::PYX;

use base qw(Plack::App::Directory);
use strict;
use warnings;

use English;
use Error::Pure qw(err);
use PYX::SGML::Tags;
use Plack::Util::Accessor qw(indent);
use Tags::Output::Raw;
use Unicode::UTF8 qw(encode_utf8);

our $VERSION = 0.05;

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

	my $tags = $self->_get_tags;
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

sub _get_tags {
	my $self = shift;

	my $tags;
	if (! defined $self->indent) {
		$tags = Tags::Output::Raw->new;
	} else {
		my $class = $self->indent;
		eval "require $class;";
		if ($EVAL_ERROR) {
			err "Cannot load class '$class'.",
				'Error', $EVAL_ERROR;
		}
		$tags = eval "$class->new";
		if ($EVAL_ERROR) {
			err "Cannot create object for '$class' class.",
				'Error', $EVAL_ERROR;
		}
		if (! $tags->isa('Tags::Output')) {
			err "Bad 'Tags::Output' module to create PYX output.";
		}
	}

	return $tags;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Directory::PYX - Plack PYX directory application.

=head1 SYNOPSIS

 use Plack::App::Directory::PYX;

 my $obj = Plack::App::Directory::PYX->new(%parameters);
 my $psgi_ar = $obj->serve_path($env, $path_to_file_or_dir);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::Directory::PYX->new(%parameters);

Constructor.

Returns instance of object.

=over

=item * C<indent>

Set Tags::Output::* class for output serialization.

Default value is Tags::Output::Raw.

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

=for comment filename=pyx_minimal_psgi.pl

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

=for comment filename=pyx_indent_psgi.pl

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
         'indent' => 'Tags::Output::Indent',
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

L<English>,
L<Error::Pure>,
L<Plack::App::Directory>,
L<Plack::Util::Accessor>,
L<PYX::SGML::Tags>,
L<Tags::Output::Raw>,
L<Unicode::UTF8>,

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Directory-PYX>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2016-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
