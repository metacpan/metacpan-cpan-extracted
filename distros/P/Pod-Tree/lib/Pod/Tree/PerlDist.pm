package Pod::Tree::PerlDist;
use 5.006;
use strict;
use warnings;
use HTML::Stream;
use Pod::Tree;
use Pod::Tree::HTML;
use Pod::Tree::PerlUtil;

our $VERSION = '1.27';

use base qw(Pod::Tree::PerlUtil);

sub new {
	my ( $class, $perl_dir, $html_dir, $link_map, %options ) = @_;

	my %defaults = (
		bgcolor => '#ffffff',
		text    => '#000000'
	);

	my @stop_base = qw(Configure
		configpm configure
		installhtml installman installperl
		mv-if-diff
		perlsh);

	my $options = { %defaults, %options, link_map => $link_map };

	my $perl_dist = {
		perl_dir  => $perl_dir,
		html_dir  => $html_dir,
		top_page  => 'dist.html',
		stop_ext  => [qw(SH c diff fixer h pl sym y)],
		stop_base => [@stop_base],
		depth     => 0,
		options   => $options
	};

	bless $perl_dist, $class;
}

sub scan {
	my $perl_dist = shift;
	$perl_dist->report1("scan");

	my $perl_dir = $perl_dist->{perl_dir};
	my $html_dir = $perl_dist->{html_dir};
	opendir( DIR, $perl_dir ) or die "Can't opendir $perl_dir: $!\n";

	my $stop_ext = $perl_dist->{stop_ext};
	my %stop_ext = map { $_ => 1 } @$stop_ext;

	my $stop_base = $perl_dist->{stop_base};
	my %stop_base = map { $_ => 1 } @$stop_base;

	for my $file ( readdir(DIR) ) {
		-f "$perl_dir/$file" and -T "$perl_dir/$file" or next;

		my ( $base, $ext ) = split m(\.), $file;
		$stop_ext{$ext}   and next;
		$stop_base{$base} and next;

		$perl_dist->report2($file);
		$perl_dist->scan_file($file);
	}
}

sub scan_file {
	my ( $perl_dist, $file ) = @_;

	my $perl_dir = $perl_dist->{perl_dir};
	my $html_dir = $perl_dist->{html_dir};

	my $source = "$perl_dir/$file";
	my $dest   = "$html_dir/$file.html";

	my $entry = {
		file   => $file,
		source => $source,
		dest   => $dest
	};

	$perl_dist->{index}{$file} = $entry;
	$perl_dist->{options}{link_map}->add_page( $file, $file );

	my ( $base, $ext ) = split m(\.), $file;
	$base eq 'README'
		and $ext
		and $perl_dist->{options}{link_map}->add_page( "perl$ext", $file );
}

sub index {
	my $perl_dist = shift;
	$perl_dist->report1("index");

	my $html_dir = $perl_dist->{html_dir};
	my $top_page = $perl_dist->{top_page};
	my $dest     = "$html_dir/$top_page";

	my $fh = IO::File->new(">$dest");
	defined $fh or die "Pod::Tree::PerlDist::index: Can't open $dest: $!\n";
	my $stream = HTML::Stream->new($fh);

	my $options = $perl_dist->{options};
	my $bgcolor = $options->{bgcolor};
	my $text    = $options->{text};
	my $title   = "Perl Distribution Documents";

	$stream->HTML->HEAD;
	$stream->TITLE->text($title)->_TITLE;
	$stream->_HEAD->BODY( BGCOLOR => $bgcolor, TEXT => $text );
	$stream->H1->t($title)->_H1;

	$perl_dist->_emit_entries($stream);

	$stream->_BODY->_HTML;
}

sub get_top_entry {
	my $perl_dist = shift;

	+{
		URL         => $perl_dist->{top_page},
		description => 'distribution documents'
	};
}

sub _emit_entries {
	my ( $perl_dist, $stream ) = @_;

	my $index   = $perl_dist->{index};
	my $options = $perl_dist->{options};

	$stream->PRE;

	for my $name ( sort keys %$index ) {
		$stream->A( HREF => "$name.html" )->t($name)->_A->nl;
	}

	$stream->_PRE;
}

sub translate {
	my $perl_dist = shift;
	$perl_dist->report1("translate");

	my $depth = $perl_dist->{depth};
	my $index = $perl_dist->{index};

	$perl_dist->{options}{link_map}->set_depth($depth);

	for my $name ( sort keys %$index ) {
		$perl_dist->report2($name);

		my $entry  = $index->{$name};
		my $source = $entry->{source};
		open( my $FILE, '<', $source )
			or die "Pod::Tree::PerlDist::translate: Can't open $source: $!\n";
		my @file = <$FILE>;
		close $FILE;

		my $translate
			= ( grep {/^=\w+/} @file )
			? 'translate_pod'
			: 'translate_text';

		$perl_dist->$translate($entry);
	}
}

sub translate_pod {
	my ( $perl_dist, $entry ) = @_;

	my $source  = $entry->{source};
	my $dest    = $entry->{dest};
	my $options = $perl_dist->{options};
	my $html    = Pod::Tree::HTML->new( $source, $dest, %$options );
	$html->translate;
}

sub translate_text {
	my ( $perl_dist, $entry ) = @_;

	my $source = $entry->{source};
	my $dest   = $entry->{dest};

	my $fh = IO::File->new(">$dest");
	defined $fh
		or die "Pod::Tree::PerlDist::translate_text: Can't open $dest: $!\n";
	my $stream = HTML::Stream->new($fh);

	my $options = $perl_dist->{options};
	my $bgcolor = $options->{bgcolor};
	my $text    = $options->{text};
	my $title   = $entry->{file};

	$stream->HTML->HEAD;
	$stream->TITLE->text($title)->_TITLE;
	$stream->_HEAD->BODY( BGCOLOR => $bgcolor, TEXT => $text );
	$stream->H1->t($title)->_H1;
	$stream->PRE;

	open( my $SOURCE, '<', $source )
		or die "Pod::Tree::PerlDist::translate_text: Can't open $source: $!\n";

	while ( my $line = <$SOURCE> ) {
		$stream->t($line);
	}
	close $SOURCE;

	$stream->_PRE;
	$stream->_BODY->_HTML;
}

1

__END__

=head1 NAME

Pod::Tree::PerlDist - translate Perl distribution documentation to HTML

=head1 SYNOPSIS

  $perl_map  = Pod::Tree::PerlMap->new;
  $perl_dist = Pod::Tree::PerlDist->new( $perl_dir, $HTML_dir, $perl_map, %opts );

  $perl_dist->scan;
  $perl_dist->index;
  $perl_dist->translate;

  $top = $perl_dist->get_top_entry;

=head1 DESCRIPTION

C<Pod::Tree::PerlDist> translates documents in the Perl
distribution to HTML. These include F<Changes>, F<README>, and
assored other files that appear in the top level of the Perl 
source tree.

Files that contain PODs are parsed as PODs;
files that do not contain PODs are converted to HTML
as preformatted text.

C<Pod::Tree::PerlDist> generates and uses an index of the files 
that it finds to construct HTML links.
Other modules can also use this index.

=head1 METHODS

=over 4

=item I<$perl_dist> = C<new> C<Pod::Tree::PerlDist> I<$perl_dir>,
I<$HTML_dir>, I<$perl_map>, I<%options>

Creates and returns a new C<Pod::Tree::PerlDist> object.

I<$perl_dir> is the root of the Perl source tree.

I<$HTML_dir> is the directory where HTML files will be written.

I<$perl_map> maps file names to URLs.

I<%options> are passed through to C<Pod::Tree::HTML>.

=item I<$perl_dist>->C<scan>

Scans the top level of the Perl source tree for documentation files.
Files that do not generally contain user-level documentation,
such as source files, are ignored.
The search does not recurse through subdirectories.

Each file that is located is entered into I<$perl_map>.

=item I<$perl_dist>->C<index>

Generates a top-level index of all the distribution documents, 
and writes it to I<HTML_dir>C</dist.html>.

=item I<$perl_dist>->C<translate>

Translates each distribution document found by C<scan> to HTML.
The HTML pages are written to I<HTML_dir>.

=item I<$perl_dist>->C<get_top_entry>

Returns a hash reference of the form

  { URL         => $URL,
    description => $description }

C<Pod::Tree::PerlTop> uses this to build a top-level index of all the 
Perl PODs.

=back

=head1 LINKING

C<Pod::Tree::PerlDist> indexes files by their name.
To link to a file named F<README.win32>
write

    L<README.win32>

=head1 REQUIRES

    5.005;
    HTML::Stream;
    Pod::Tree;
    Pod::Tree::HTML;
    Pod::Tree::PerlUtil;

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

L<C<Pod::Tree::HTML>>, L<C<Pod::Tree::PerlMap>>, 

=head1 AUTHOR

Steven McDougall, swmcd@world.std.com

=head1 COPYRIGHT

Copyright (c) 2000 by Steven McDougall.  This module is free software;
you can redistribute it and/or modify it under the same terms as Perl.
