package Term::Fabulous::Screenshot::PodSync;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Carp qw(croak);
use Encode qw(decode encode);
use Exporter qw(import);

our @EXPORT_OK = qw(sync_code_blocks referenced_screenshots foreign_images screenshots_at_tag read_text write_text);

# A code block in POD that shows a file of the distribution is marked
#
#     =for code-from examples/cookbook/login-form.pl
#
# and followed by the verbatim paragraphs that show the file. The file
# is the original: sync_code_blocks replaces the paragraphs after every
# marker with the file's current content.

use constant MARKER => qr/\A=for code-from (\S+)\s*\z/;

# Screenshots are shown with HTML blocks whose images are the raw files
# of the screenshots directory on GitHub, at the tag of a release:
# MetaCPAN shows images in the POD only with absolute URLs.
use constant IMAGE_URL_BASE => 'https://raw.githubusercontent.com/davenonymous/perl-term-fabulous';
use constant IMAGE_SOURCE   => qr{src="\Q${\ IMAGE_URL_BASE}\E/([^"/]+)/screenshots/([a-z0-9]+(?:-[a-z0-9]+)*)\.svg"};

sub read_text ($file) {
	open my $handle, '<:raw', $file or croak "Term::Fabulous::Screenshot::PodSync: cannot read $file: $!";
	my $bytes = do { local $/; <$handle> };
	close $handle;
	return decode( 'UTF-8', $bytes, Encode::FB_CROAK );
}

sub write_text ( $file, $text ) {
	open my $handle, '>:raw', $file or croak "Term::Fabulous::Screenshot::PodSync: cannot write $file: $!";
	print {$handle} encode( 'UTF-8', $text );
	close $handle or croak "Term::Fabulous::Screenshot::PodSync: cannot write $file: $!";
	return;
}

# The POD text with every marked code block replaced by its file, and the
# files whose blocks changed. $read_file returns a file's text.
sub sync_code_blocks ( $pod, $read_file ) {
	my @lines = split /^/m, $pod;
	my ( @output, @changed );
	while (@lines) {
		my $line = shift @lines;
		push @output, $line;
		next unless $line =~ /\A=for code-from\b/;
		my ($file) = $line =~ MARKER or croak "Term::Fabulous::Screenshot::PodSync: malformed marker '" . ( $line =~ s/\s+\z//r ) . "' (expected '=for code-from PATH')";

		my @old_block;
		push @old_block, shift @lines while @lines && ( $lines[0] =~ /\A\s*\z/ || $lines[0] =~ /\A[ \t]/ );
		my @new_block = ( "\n", _verbatim( $read_file->($file), $file ), "\n" );
		push @output,  @new_block;
		push @changed, $file if join( '', @old_block ) ne join( '', @new_block );
	}
	return ( join( '', @output ), @changed );
}

# A file as a verbatim block: without its #! line, every line indented by
# a tab, blank lines empty.
sub _verbatim ( $code, $file ) {
	$code =~ s/\A#![^\n]*\n//;
	$code =~ s/\A(?:[ \t]*\n)+//;
	$code =~ s/\s+\z//;
	croak "Term::Fabulous::Screenshot::PodSync: $file is empty" unless length $code;
	return map { /\A\s*\z/ ? "\n" : "\t$_\n" } split /\n/, $code, -1;
}

# The names of the screenshots a POD text shows.
sub referenced_screenshots ($pod) {
	my ( %seen, @names );
	push @names, $2 while $pod =~ /${\ IMAGE_SOURCE}/g;
	return grep { !$seen{$_}++ } @names;
}

# The <img> tags of a POD text that do not show a screenshot.
sub foreign_images ($pod) {
	return grep { !/\A<img ${\ IMAGE_SOURCE}/ } $pod =~ /(<img\b[^>]*>)/g;
}

# The POD text with every screenshot shown at the tag $tag.
sub screenshots_at_tag ( $pod, $tag ) {
	return $pod =~ s{${\ IMAGE_SOURCE}}{src="${\ IMAGE_URL_BASE}/$tag/screenshots/$2.svg"}gr;
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::PodSync - Keep code blocks in POD equal to
the files they show

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::PodSync qw(sync_code_blocks referenced_screenshots read_text write_text);

	my ( $pod, @changed ) = sync_code_blocks( read_text($file), \&read_text );
	write_text( $file, $pod ) if @changed;

	my @names = referenced_screenshots($pod);    # screenshots/NAME.svg
	$pod = screenshots_at_tag( $pod, 'v0.01' );

=head1 DESCRIPTION

Maintainer tool, not installed. The documentation shows the programs
of the F<examples> and F<examples/cookbook> directories. To keep the
POD and the programs from drifting apart, the files are the originals
and the POD copies them. A copy is marked with a paragraph

	=for code-from examples/cookbook/login-form.pl

that POD formatters ignore. The verbatim paragraphs that follow it are
the copy: the file without its C<#!> line, each line indented by a tab.

=head1 FUNCTIONS

=head2 sync_code_blocks

	my ( $new_pod, @changed_files ) = sync_code_blocks( $pod, $read_file );

Replaces the verbatim paragraphs after every marker with the file's
content, or inserts them when the marker has none. C<$read_file> is
called with each path and returns the file's text. Also returns the
paths whose copies changed. Dies on a C<=for code-from> line that is not
followed by exactly one path.

Every verbatim paragraph directly after a marker belongs to the copy:
to show other code after it, put a text paragraph in between.

=head2 referenced_screenshots

	my @names = referenced_screenshots($pod);

The names of the screenshots the POD shows: every
C<src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/TAG/screenshots/NAME.svg">
in it, each name once, in order. MetaCPAN shows images in the POD only
with absolute URLs, so the POD points to the raw files on GitHub at the
tag of a release.

=head2 foreign_images

	my @tags = foreign_images($pod);

The C<< <img> >> tags of the POD whose C<src> is not the first attribute
or not the URL of a screenshot as above.

=head2 screenshots_at_tag

	my $new_pod = screenshots_at_tag( $pod, 'v0.01' );

The POD with the URL of every screenshot pointing to the tag C<$tag>.

=head2 read_text, write_text

Read and write a UTF-8 file as a character string.

=cut
