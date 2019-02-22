package Pod::Tree::PerlPod;
use 5.006;
use strict;
use warnings;
use File::Find;
use HTML::Stream;
use IO::File;
use Pod::Tree::HTML;
use Pod::Tree::PerlUtil;

our $VERSION = '1.31';

use base qw(Pod::Tree::PerlUtil);

sub new {
	my ( $class, $perl_dir, $html_dir, $link_map, %options ) = @_;

	my %defaults = (
		col_width => 20,
		bgcolor   => '#ffffff',
		text      => '#000000'
	);

	my $options = { %defaults, %options, link_map => $link_map };

	my %special = map { $_ => 1 } qw(pod/perl pod/perlfunc);

	my $perl_pod = {
		perl_dir => $perl_dir,
		html_dir => $html_dir,
		top_page => 'pod.html',
		special  => \%special,
		options  => $options
	};

	bless $perl_pod, $class;
}

sub scan {
	my $perl_pod = shift;
	$perl_pod->report1("scan");
	my $perl_dir = $perl_pod->{perl_dir};

	File::Find::find(
		{
			wanted => sub { $perl_pod->_scan },    # Perl rocks!
			no_chdir => 1
		},
		$perl_dir
	);
}

sub _scan {
	my $perl_pod = shift;
	my $source   = $File::Find::name;
	my $dest     = $source;
	my $perl_dir = $perl_pod->{perl_dir};
	my $html_dir = $perl_pod->{html_dir};
	$dest =~ s(^$perl_dir)($html_dir);

	-d $source and $perl_pod->_scan_dir($dest);
	-f $source and $perl_pod->_scan_file( $source, $dest );
}

sub _scan_dir {
	my ( $perl_pod, $dir ) = @_;

	$dir =~ m(/ext$) and do    # extensions are handled by Pod::Tree::PerlLib
	{
		$File::Find::prune = 1;
		return;
	};

	-d $dir
		or mkdir $dir, 0755
		or die "Pod::Tree::PerlPod::_scan_dir: Can't mkdir $dir: $!\n";
}

sub _scan_file {
	my ( $perl_pod, $source, $dest ) = @_;

	$source =~ m( (\w+)\.pod$ )x or return;

	my $link     = $source;
	my $perl_dir = $perl_pod->{perl_dir};
	$link =~ s(^$perl_dir/)();
	$link =~ s( \.pod$ )()x;
	$perl_pod->report2($link);

	my $name = ( split m(/), $link )[-1];
	my $desc = $perl_pod->get_description($source);

	$dest =~ s( \.\w+$ )(.html)x;

	my $pod = {
		name   => $name,      # perldata
		desc   => $desc,      # Perl data types
		link   => $link,      # pod/perldata
		source => $source,    # .../perl5.5.650/pod/perldata.pod
		dest   => $dest
	};    # .../public_html/perl/pod/perldata.html

	$perl_pod->{pods}{$link} = $pod;
	$perl_pod->{options}{link_map}->add_page( $name, $link );
}

sub index {
	my $perl_pod = shift;
	$perl_pod->report1("index");
	my $html_dir = $perl_pod->{html_dir};
	my $top_page = $perl_pod->{top_page};
	my $dest     = "$html_dir/$top_page";

	my $fh = IO::File->new(">$dest");
	defined $fh or die "Pod::Tree::PerlPod::index: Can't open $dest: $!\n";
	my $stream = HTML::Stream->new($fh);

	my $options = $perl_pod->{options};
	my $bgcolor = $options->{bgcolor};
	my $text    = $options->{text};
	my $title   = "Perl PODs";

	$stream->HTML->HEAD;
	$stream->TITLE->text($title)->_TITLE;
	$stream->_HEAD->BODY( BGCOLOR => $bgcolor, TEXT => $text );
	$stream->H1->t($title)->_H1;

	$perl_pod->_emit_entries($stream);

	$stream->_BODY->_HTML;
}

sub get_top_entry {
	my $perl_dist = shift;

	+{
		URL         => $perl_dist->{top_page},
		description => 'PODs'
	};
}

sub _emit_entries {
	my ( $perl_pod, $stream ) = @_;
	my $pods      = $perl_pod->{pods};
	my $options   = $perl_pod->{options};
	my $col_width = $options->{col_width};

	$stream->PRE;

	$pods = $perl_pod->{pods};
	for my $link ( sort keys %$pods ) {
		my $pad = $col_width - length $link;
		$stream->A( HREF => "$link.html" )->t($link)->_A;

		$pad < 1 and do {
			$stream->nl;
			$pad = $col_width;
		};

		$stream->t( ' ' x $pad, $pods->{$link}{desc} )->nl;
	}

	$stream->_PRE;
}

sub translate {
	my $perl_pod = shift;
	$perl_pod->report1("translate");
	my $pods    = $perl_pod->{pods};
	my $special = $perl_pod->{special};

	for my $link ( sort keys %$pods ) {
		$special->{$link} and next;
		$perl_pod->report2($link);
		$perl_pod->_translate($link);
	}
}

sub _translate {
	my ( $perl_pod, $link ) = @_;

	my $pod     = $perl_pod->{pods}{$link};
	my $source  = $pod->{source};
	my $dest    = $pod->{dest};
	my $options = $perl_pod->{options};

	my @path = split m(\/), $link;
	my $depth = @path - 1;
	$options->{link_map}->set_depth($depth);

	my $html = Pod::Tree::HTML->new( $source, $dest, %$options );
	$html->translate;
}

1

__END__

=head1 NAME

Pod::Tree::PerlPod - translate Perl PODs to HTML

=head1 SYNOPSIS

  $perl_map = Pod::Tree::PerlMap->new;
  $perl_pod = Pod::Tree::PerlPod->new( $perl_dir, $HTML_dir, $perl_map, %opts );

  $perl_pod->scan;
  $perl_pod->index;
  $perl_pod->translate;
  
  $top = $perl_pod->get_top_entry;

=head1 DESCRIPTION

C<Pod::Tree::PerlPod> translates Perl PODs to HTML.
It does a recursive subdirectory search through I<$perl_dir> to find PODs.

C<Pod::Tree::PerlPod> generates a top-level index of all the PODs
that it finds, and writes it to I<HTML_dir>C</pod.html>.

C<Pod::Tree::PerlPod> generates and uses an index of the PODs
that it finds to construct HTML links.
Other modules can also use this index.

=head1 METHODS

=over 4

=item I<$perl_pod> = C<new> C<Pod::Tree::PerlPod> I<$perl_dir>,
I<$HTML_dir>, I<$perl_map>, I<%options>

Creates and returns a new C<Pod::Tree::PerlPod> object.

I<$perl_dir> is the root of the Perl source tree.

I<$HTML_dir> is the directory where HTML files will be written.

I<$perl_map> maps POD names to URLs.

I<%options> are passed through to C<Pod::Tree::HTML>.

=item I<$perl_pod>->C<scan>;

Does a recursive subdirectory search through I<$perl_dir> to 
locate PODs. Each POD that is located is entered into I<$perl_map>.

=item I<$perl_pod>->C<index>

Generates a top-level index of all the PODs. 
The index is written to I<HTML_dir>C</pod.html>.

=item I<$perl_pod>->C<translate>

Translates each POD found by C<scan> to HTML.
The HTML pages are written to I<HTML_dir>,
in a subdirectory hierarchy that mirrors the 
the Perl source distribution.

=item I<$perl_pod>->C<get_top_entry>

Returns a hash reference of the form

  { URL         => $URL,
    description => $description }

C<Pod::Tree::PerlTop> uses this to build a top-level index of all the 
Perl PODs.

=back

=head1 LINKING

C<Pod::Tree::PerlPod> indexes PODs by the base name of the POD file.
To link to F<perlsub.pod>, write

    L<perlsub>

=head1 REQUIRES

    5.005;
    File::Find;
    HTML::Stream;
    IO::File;
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
