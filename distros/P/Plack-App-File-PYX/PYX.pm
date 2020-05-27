package Plack::App::File::PYX;

use base qw(Plack::App::File);
use strict;
use warnings;

use Encode qw(encode);
use English;
use Error::Pure qw(err);
use HTTP::Date;
use Plack::Util::Accessor qw(indent);
use PYX::SGML::Tags;
use Tags::Output::Raw;
use Unicode::UTF8 qw(encode_utf8);

our $VERSION = 0.01;

sub serve_path {
	my ($self, $env, $file) = @_;

	my $encoding = $self->encoding || 'utf-8';

	my $content_type = $self->content_type || 'text/html';
	if (ref $content_type eq 'CODE') {
		$content_type = $content_type->($file);
	}
	if ($content_type =~ m/^text\//) {
		$content_type .= '; charset='.$encoding;
	}

	my $tags = $self->_get_tags;
	my $pyx = PYX::SGML::Tags->new(
		'tags' => $tags,
	);

	$pyx->parse_file($file);

	my @stat = stat $file;

	my $out;
	if ($encoding eq 'utf-8') {
		$out = encode_utf8($tags->flush);
	} else {
		$out = encode($encoding, $tags->flush);
	}

	return [
		200,
		[
			'Content-Type' => $content_type,
			'Last-Modified' => HTTP::Date::time2str($stat[9]),
		],
		[$out],
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

Plack::App::File::PYX - Plack PYX directory application.

=head1 SYNOPSIS

 use Plack::App::File::PYX;

 my $obj = Plack::App::File::PYX->new(%parameters);
 my $psgi_ar = $obj->serve_path($env, $file);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::File::PYX->new(%parameters);

Constructor.

Returns instance of object.

=over

=item * C<content_type>

Content-Type of serialized output. There is possibility of callback (reference
to code) with $file argument which return content type string.

Default value is 'text/html'.

=item * C<encoding>

Set the file encoding for text files. Defaults to 'utf-8'.

=item * C<file>

The file path to create responses from. Optional.

If it's set the application would ALWAYS create a response out of the file and
there will be no security check etc. (hence fast). If it's not set, the application uses 
"root" to find the matching file.

=item * C<indent>

Set Tags::Output::* class for output serialization.

Default value is Tags::Output::Raw.

=item * C<root>

Document root directory. Defaults to "." (current directory)

=back

=head2 C<serve_path>

 my $psgi_ar = $obj->serve_path($env, $file);

Process file on disk and serve it to application.

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
 use Plack::App::File::PYX;
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
 my $app = Plack::App::File::PYX->new('file' => $temp_pyx_file)->to_app;
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
 use Plack::App::File::PYX;
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
 my $app = Plack::App::File::PYX->new(
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

=head1 EXAMPLE3

 use strict;
 use warnings;

 use File::Temp;
 use IO::Barf;
 use Plack::App::File::PYX;
 use Plack::Runner;

 # Temporary file with PYX.
 my $temp_pyx_file = File::Temp->new->filename;

 # PYX file.
 my $pyx = <<'END';
 ?xml version="1.0"
 (svg
 Axmlns http://www.w3.org/2000/svg
 (rect
 Ax 80
 Ay 60
 Awidth 250
 Aheight 250
 Arx 20
 Astyle fill:#ff0000; stroke:#000000; stroke-width:2px;
 )rect
 (rect
 Ax 140
 Ay 120
 Awidth 250
 Aheight 250
 Arx 40
 Astyle fill:#0000ff; stroke:#000000; stroke-width:2px; fill-opacity:0.7;
 )rect
 )svg
 END
 barf($temp_pyx_file, $pyx);

 # Run application with one PYX file.
 my $app = Plack::App::File::PYX->new(
         'content_type' => 'image/svg+xml',
         'file' => $temp_pyx_file,
         'indent' => 'Tags::Output::Indent',
 )->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # <?xml version="1.0"?>
 # <svg xmlns="http://www.w3.org/2000/svg">
 #   <rect x="80" y="60" width="250" height="250" rx="20" style=
 #     "fill:#ff0000; stroke:#000000; stroke-width:2px;">
 #   </rect>
 #   <rect x="140" y="120" width="250" height="250" rx="40" style=
 #     "fill:#0000ff; stroke:#000000; stroke-width:2px; fill-opacity:0.7;">
 #   </rect>
 # </svg>

=head1 EXAMPLE4

 use strict;
 use warnings;

 use File::Temp;
 use IO::Barf;
 use Plack::App::File::PYX;
 use Plack::Runner;

 # Temporary file with PYX.
 my $temp_pyx_file = File::Temp->new->filename;

 # PYX file in UTF8, prepared for iso-8859-2 output.
 my $pyx = <<'END';
 (html
 (head
 (title
 -žščřďťň
 )title
 (meta
 Acharset iso-8859-2
 )meta
 )head
 (body
 (div
 -Hello in iso-8859-2 encoding - Ahoj světe!
 )div
 )body
 )html
 END
 barf($temp_pyx_file, $pyx);

 # Run application with one PYX file.
 my $app = Plack::App::File::PYX->new(
         'encoding' => 'iso-8859-2',
         'file' => $temp_pyx_file,
         'indent' => 'Tags::Output::Indent',
 )->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # XXX in ISO-8859-2 encoding
 # <html>
 #   <head>
 #     <title>
 #       žščřďťň
 #     </title>
 #     <meta charset="iso-8859-2">
 #     </meta>
 #   </head>
 #   <body>
 #     <div>
 #       Hello in iso-8859-2 encoding - Ahoj světe!
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Encode>,
L<English>,
L<Error::Pure>,
L<HTTP::Date>,
L<Plack::App::File>,
L<Plack::Util::Accessor>,
L<PYX::SGML::Tags>,
L<Tags::Output::Raw>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-File-PYX>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
