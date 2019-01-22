package Pod::Tree::PerlLib;
use 5.006;
use strict;
use warnings;
use HTML::Stream;
use Pod::Tree;
use Pod::Tree::HTML;
use Pod::Tree::PerlUtil;

our $VERSION = '1.30';

use base qw(Pod::Tree::PerlUtil);

use constant COLUMN_WIDTH => 30;

sub new {
	my ( $class, $perl_dir, $html_dir, $link_map, %options ) = @_;

	my %defaults = (
		col_width => COLUMN_WIDTH,
		bgcolor   => '#ffffff',
		text      => '#000000'
	);
	my $options = { %defaults, %options, link_map => $link_map };

	my %stop_files = map { $_ => 1 } qw(perllocal.pod);

	my $perl_lib = {
		perl_dir   => $perl_dir,
		html_dir   => $html_dir,
		lib_dir    => 'lib',
		top_page   => 'lib.html',
		stop_files => \%stop_files,
		options    => $options
	};

	bless $perl_lib, $class;
}

sub scan {
	my ( $perl_lib, @dirs ) = @_;
	$perl_lib->report1("scan");

	# Don't try to install PODs for modules on relative paths in @INC
	# (Typically `.')
	@dirs = grep {m(^/)} @dirs;

	$perl_lib->_stop_dirs(@dirs);

	for my $dir (@dirs) {
		$perl_lib->{find_dir} = $dir;
		File::Find::find(
			{
				wanted => sub { $perl_lib->_scan },    # Closures rock!
				no_chdir => 1
			},
			$dir
		);
	}
}

sub _stop_dirs {
	my ( $perl_lib, @dirs ) = @_;

	for my $dir (@dirs) {
		for my $stop_dir (@dirs) {
			$stop_dir =~ /^$dir./
				and $perl_lib->{stop_dir}{$dir}{$stop_dir} = 1;
		}
	}
}

sub _scan {
	my $perl_lib = shift;
	my $source   = $File::Find::name;

	-d $source and $perl_lib->_scan_dir($source);
	-f $source and $perl_lib->_scan_file($source);
}

sub _scan_dir {
	my ( $perl_lib, $dir ) = @_;

	my $find_dir = $perl_lib->{find_dir};

	if ( $perl_lib->{stop_dir}{$find_dir}{$dir} or $dir =~ /pod$/ ) {
		$File::Find::prune = 1;
		return;
	}

	my $html_dir = $perl_lib->{html_dir};
	my $lib_dir  = $perl_lib->{lib_dir};
	$dir =~ s(^$find_dir)($html_dir/$lib_dir);

	$perl_lib->mkdir($dir);
}

sub _scan_file {
	my ( $perl_lib, $source ) = @_;

	$source =~ m(\. (?: pl | pm | pod ) $ )x or return;
	my $file = ( split m(/), $source )[-1];
	$perl_lib->{stop_files}{$file} and return;
	my $module   = $source;
	my $find_dir = $perl_lib->{find_dir};
	$module =~ s(^$find_dir/)();
	$module =~ s( \.\w+$    )()x;    # Foo/Bar

	my $html_dir = $perl_lib->{html_dir};
	my $lib_dir  = $perl_lib->{lib_dir};
	my $dest     = "$html_dir/$lib_dir/$module.html";
	my ( $name, $description ) = $perl_lib->get_name($source);

	$name or return;
	$perl_lib->report2($name);

	my $href = "$module.html";
	my $link = "$lib_dir/$module";

	my $entry = {
		source      => $source,       # .../Foo/Bar.pm
		dest        => $dest,         # .../html/lib/Foo/Bar.html
		href        => $href,         # Foo/Bar.html
		description => $description
	};

	$perl_lib->{index}{$name} = $entry;
	$perl_lib->{options}{link_map}->add_page( $name, $link );
}

sub index {
	my $perl_lib = shift;
	$perl_lib->report1("index");
	my $html_dir = $perl_lib->{html_dir};
	my $top_page = $perl_lib->{top_page};
	my $dest     = "$html_dir/$top_page";

	my $fh = IO::File->new(">$dest");
	defined $fh or die "Pod::Tree::PerlLib::index: Can't open $dest: $!\n";
	my $stream = HTML::Stream->new($fh);

	my $options = $perl_lib->{options};
	my $bgcolor = $options->{bgcolor};
	my $text    = $options->{text};
	my $title   = "Perl Modules";

	$stream->HTML->HEAD;
	$stream->TITLE->text($title)->_TITLE;
	$stream->_HEAD->BODY( BGCOLOR => $bgcolor, TEXT => $text );
	$stream->H1->t($title)->_H1;

	$perl_lib->_emit_entries($stream);

	$stream->_BODY->_HTML;
}

sub get_top_entry {
	my $perl_lib = shift;

	+{
		URL         => $perl_lib->{top_page},
		description => 'Modules'
	};
}

sub _emit_entries {
	my ( $perl_lib, $stream ) = @_;

	my $lib_dir   = $perl_lib->{lib_dir};
	my $index     = $perl_lib->{index};
	my $options   = $perl_lib->{options};
	my $col_width = $options->{col_width};

	$stream->PRE;

	for my $name ( sort keys %$index ) {
		my $entry = $index->{$name};
		my $href  = $entry->{href};
		my $desc  = $entry->{description};
		my $pad   = $col_width - length $name;

		$stream->A( HREF => "$lib_dir/$href" )->t($name)->_A;

		$pad < 1 and do {
			$stream->nl;
			$pad = $col_width;
		};

		$stream->t( ' ' x $pad, $desc )->nl;
	}

	$stream->_PRE;
}

sub translate {
	my $perl_lib = shift;
	$perl_lib->report1("translate");

	my $index   = $perl_lib->{index};
	my $options = $perl_lib->{options};

	for my $name ( sort keys %$index ) {
		$perl_lib->report2($name);
		my @path = split m(::), $name;
		my $depth = @path;    # no -1 because they are all under /lib/
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

Pod::Tree::PerlLib - translate module PODs to HTML

=head1 SYNOPSIS

  $perl_map = Pod::Tree::PerlMap->new;
  $perl_lib = Pod::Tree::PerlLib->new( $perl_dir, $HTML_dir, $perl_map, %opts );

  $perl_lib->scan(@INC);
  $perl_lib->index;
  $perl_lib->translate;

  $top = $perl_lib->get_top_entry;

=head1 DESCRIPTION

C<Pod::Tree::PerlLib> translates module PODs to HTML.
It does a recursive subdirectory search through a list of
directories (typically C<@INC>) to find PODs.

C<Pod::Tree::PerlLib> generates a top-level index of all the PODs
that it finds, and writes it to I<HTML_dir>C</lib.html>.

C<Pod::Tree::PerlLib> generates and uses an index of the PODs
that it finds to construct HTML links.
Other modules can also use this index.

=head1 METHODS

=over 4

=item I<$perl_lib> = C<new> C<Pod::Tree::PerlLib> I<$perl_dir>,
I<$HTML_dir>, I<$perl_map>, I<%options>

Creates and returns a new C<Pod::Tree::PerlLib> object.

I<$HTML_dir> is the directory where HTML files will be written.

I<$perl_map> maps module names to URLs.

I<%options> are passed through to C<Pod::Tree::HTML>.

The I<$perl_dir> argument is included for consistency with the
other C<Pod::Tree::Perl*> modules, but is currently unused.

=item I<$perl_lib>->C<scan>(I<@INC>)

Does a recursive subdirectory search through I<@INC> to locate module PODs.
Each module that is identified is entered into I<$perl_map>.

=item I<$perl_lib>->C<index>

Generates a top-level index of all the modules.
The index is written to I<HTML_dir>C</lib.html>.

=item I<$perl_lib>->C<translate>

Translates each module POD found by C<scan> to HTML.
The HTML pages are written to I<HTML_dir>C</lib/>,
in a subdirectory hierarchy that maps the module names.

=item I<$perl_lib>->C<get_top_entry>

Returns a hash reference of the form

  { URL         => $URL,
    description => $description }

C<Pod::Tree::PerlTop> uses this to build a top-level index of all the Perl PODs.

=back

=head1 LINKING

C<Pod::Tree::PerlLib> expects the second paragraph of the POD to have the form

    Foo::Bar - description

and enters I<Foo::Bar> into I<$perl_map>.
To link to a module POD, write

    L<Foo::Bar>

=head1 REQUIRES

    5.005;
    HTML::Stream;
    Pod::Tree;
    Pod::Tree::HTML;
    Pod::Tree::PerlUtil;

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

L<C<Pod::Tree::HTML>>, L<C<Pod::Tree::PerlMap>>

=head1 AUTHOR

Steven McDougall, swmcd@world.std.com

=head1 COPYRIGHT

Copyright (c) 2000 by Steven McDougall.  This module is free software;
you can redistribute it and/or modify it under the same terms as Perl.
