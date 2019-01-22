package Pod::Tree::PerlBin;
use 5.006;
use strict;
use warnings;
use File::Find;
use HTML::Stream;
use Pod::Tree;
use Pod::Tree::HTML;
use Pod::Tree::PerlUtil;

our $VERSION = '1.30';

use base qw(Pod::Tree::PerlUtil);

sub new {
	my ( $class, $perl_dir, $html_dir, $link_map, %options ) = @_;

	my %defaults = (
		col_width => 25,
		bgcolor   => '#ffffff',
		text      => '#000000'
	);
	my $options = { %defaults, %options, link_map => $link_map };

	my $perl_bin = {
		perl_dir => $perl_dir,
		html_dir => $html_dir,
		bin_dir  => 'bin',
		top_page => 'bin.html',
		depth    => 1,
		options  => $options
	};

	bless $perl_bin, $class;
}

sub scan {
	my ( $perl_bin, @dirs ) = @_;
	$perl_bin->report1("scan");

	for my $dir (@dirs) {
		opendir( DIR, $dir ) or next;    # Windows apps sometimes leave non-existant dirs on $PATH
		for my $file ( readdir(DIR) ) {
			my $path = "$dir/$file";
			-f $path and -x $path and -T $path or next;
			$perl_bin->scan_file( $dir, $file );
		}
	}

	$perl_bin->scan_xsubpp;
}

# A Very Special search for a Very Special executable
sub scan_xsubpp {
	my $perl_bin = shift;

	my @inc = grep {m(^/)} @INC;    # Don't ask.
	File::Find::find( sub { $perl_bin->_scan_xsubpp }, @inc ) if @inc;
}

sub _scan_xsubpp {
	my $perl_bin = shift;

	/^xsubpp$/
		and $perl_bin->scan_file( $File::Find::dir, $_ );
}

sub scan_file {
	my ( $perl_bin, $dir, $file ) = @_;

	my $source   = "$dir/$file";
	my $html_dir = $perl_bin->{html_dir};
	my $bin_dir  = $perl_bin->{bin_dir};
	my $link     = "$bin_dir/$file";
	my $dest     = "$html_dir/$link.html";

	my ( $name, $description ) = $perl_bin->get_name($source);
	$name or return;

	# Translate the first copy found in $PATH
	$perl_bin->{index}{$name} and return;

	$perl_bin->report2($source);

	my $entry = {
		source      => $source,
		dest        => $dest,
		file        => $file,
		description => $description
	};

	$perl_bin->{index}{$name} = $entry;
	$perl_bin->{options}{link_map}->add_page( $file, $link );
	$perl_bin->{options}{link_map}->add_page( $name, $link );
}

sub index {
	my $perl_bin = shift;
	$perl_bin->report1("index");

	my $html_dir = $perl_bin->{html_dir};
	my $bin_dir  = $perl_bin->{bin_dir};
	my $top_page = $perl_bin->{top_page};
	my $dest     = "$html_dir/$top_page";

	$perl_bin->mkdir("$html_dir/$bin_dir");

	my $fh = IO::File->new(">$dest");
	defined $fh or die "Pod::Tree::PerlBin::index: Can't open $dest: $!\n";
	my $stream = HTML::Stream->new($fh);

	my $options = $perl_bin->{options};
	my $bgcolor = $options->{bgcolor};
	my $text    = $options->{text};
	my $title   = "Perl Executables";

	$stream->HTML->HEAD;
	$stream->TITLE->text($title)->_TITLE;
	$stream->_HEAD->BODY( BGCOLOR => $bgcolor, TEXT => $text );
	$stream->H1->t($title)->_H1;

	$perl_bin->_emit_entries($stream);

	$stream->_BODY->_HTML;
}

sub get_top_entry {
	my $perl_bin = shift;

	+{
		URL         => $perl_bin->{top_page},
		description => 'Executables'
	};
}

sub _emit_entries {
	my ( $perl_bin, $stream ) = @_;

	my $bin_dir   = $perl_bin->{bin_dir};
	my $index     = $perl_bin->{index};
	my $options   = $perl_bin->{options};
	my $col_width = $options->{col_width};

	$stream->PRE;

	for my $name ( sort keys %$index ) {
		my $entry = $index->{$name};
		my $file  = $entry->{file};
		my $desc  = $entry->{description};
		my $pad   = $col_width - length $name;

		$stream->A( HREF => "$bin_dir/$file.html" )->t($name)->_A;

		$pad < 1 and do {
			$stream->nl;
			$pad = $col_width;
		};

		$stream->t( ' ' x $pad, $desc )->nl;
	}

	$stream->_PRE;
}

sub translate {
	my $perl_bin = shift;
	$perl_bin->report1("translate");

	my $index   = $perl_bin->{index};
	my $options = $perl_bin->{options};

	for my $name ( sort keys %$index ) {
		$perl_bin->report2($name);
		my $depth = $perl_bin->{depth};
		$options->{link_map}->set_depth($depth);

		my $entry  = $index->{$name};
		my $source = $entry->{source};
		my $dest   = $entry->{dest};
		my $html   = Pod::Tree::HTML->new( $source, $dest, %$options );
		$html->translate;
	}
}

1

__END__

=head1 NAME

Pod::Tree::PerlBin - translate program PODs to HTML

=head1 SYNOPSIS

  $perl_map = Pod::Tree::PerlMap->new;
  $perl_bin = Pod::Tree::PerlBin->new($perl_dir, $HTML_dir, $perl_map, %opts);

  $perl_bin->scan(@path);
  $perl_bin->index;
  $perl_bin->translate;

  $top = $perl_bin->get_top_entry;

=head1 DESCRIPTION

C<Pod::Tree::PerlBin> translates program PODs to HTML.

It searches for programs in a list of directories
(typically a PATH), and searches for PODs within the programs.
Only text (-T) files are considered.

C<Pod::Tree::PerlBin> generates a top-level index of all the program PODs, 
and writes it to I<HTML_dir>C</bin.html>.

C<Pod::Tree::PerlBin> generates and uses an index of the PODs 
that it finds to construct HTML links.
Other modules can also use this index.

=head1 METHODS

=over 4

=item I<$perl_bin> = C<new> C<Pod::Tree::PerlBin> I<$perl_dir>,
I<$HTML_dir>, I<$perl_map>, I<%options>

Creates and returns a new C<Pod::Tree::PerlBin> object.

I<$HTML_dir> is the directory where HTML files will be written.

I<$perl_map> maps program names to URLs.

I<%options> are passed through to C<Pod::Tree::HTML>.

The I<$perl_dir> argument is included for consistency with the
other C<Pod::Tree::Perl*> modules, but is currently unused.

=item I<$perl_bin>->C<scan>(I<@path>)

Scans all the directories in I<@path> for program PODs.
Only text (-T) files are considered.
The search does not recurse through subdirectories.

Each POD that is located is entered into I<$perl_map>.

=item I<$perl_bin>->C<index>

Generates a top-level index of all the program PODs, 
and writes it to I<HTML_dir>C</bin.html>.

=item I<$perl_bin>->C<translate>

Translates each program POD found by C<scan> to HTML.
The HTML pages are written to I<HTML_dir>.

=item I<$perl_bin>->C<get_top_entry>

Returns a hash reference of the form

  { URL         => $URL,
    description => $description }

C<Pod::Tree::PerlTop> uses this to build a top-level index of all the 
Perl PODs.

=back

=head1 LINKING

C<Pod::Tree::PerlBin> expects the second paragraph of the POD to 
have the form

    name - description

and enters I<name> into I<$perl_map>.
To link to a program POD from another POD,
write

    L<name>

=head1 REQUIRES

    5.005
    File::Find
    HTML::Stream
    Pod::Tree
    Pod::Tree::HTML
    Pod::Tree::PerlUtil

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

L<C<Pod::Tree::HTML>>, L<C<Pod::Tree::PerlMap>>, 

=head1 AUTHOR

Steven McDougall, swmcd@world.std.com

=head1 COPYRIGHT

Copyright (c) 2000 by Steven McDougall.  This module is free software;
you can redistribute it and/or modify it under the same terms as Perl.
