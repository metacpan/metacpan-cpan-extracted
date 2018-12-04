package Pod::Tree::PerlTop;
use 5.006;
use strict;
use warnings;

our $VERSION = '1.29';

use Pod::Tree::HTML;
use Pod::Tree::PerlUtil;
use Pod::Tree::HTML::PerlTop;

use base qw(Pod::Tree::PerlUtil);

sub new {
	my ( $class, $perl_dir, $html_dir, $link_map, %options ) = @_;

	my %defaults = (
		bgcolor => '#ffffff',
		text    => '#000000'
	);

	my $options = { %defaults, %options, link_map => $link_map };

	my $pod_src = -d "$perl_dir/pod"
		? 'pod'         # for building the doc set from a Perl distribution
		: 'lib/pod';    # for building the doc set from a Windows installation

	my $perl_top = {
		perl_dir => $perl_dir,
		html_dir => $html_dir,
		index    => 'index.html',
		pod_src  => 'pod',
		pod_dst  => 'pod',
		page     => 'perl',
		options  => $options
	};

	bless $perl_top, $class;
}

sub index {
	my ( $perl_top, @translators ) = @_;
	$perl_top->report1("index");

	my @entries = map { $_->get_top_entry } @translators;

	my $html_dir = $perl_top->{html_dir};
	my $dest     = "$html_dir/index.html";

	my $fh = IO::File->new(">$dest");
	defined $fh or die "Pod::Tree::PerlTop::index: Can't open $dest: $!\n";
	my $stream = HTML::Stream->new($fh);

	my $options = $perl_top->{options};
	my $bgcolor = $options->{bgcolor};
	my $text    = $options->{text};
	my $title   = "Perl Documentation";

	$stream->HTML->HEAD;
	$stream->TITLE->text($title)->_TITLE;
	$stream->_HEAD->BODY( BGCOLOR => $bgcolor, TEXT => $text );
	$stream->H1->t($title)->_H1;

	$perl_top->_emit_entries( $stream, @entries );

	$stream->_BODY->_HTML;
}

sub _emit_entries {
	my ( $perl_top, $stream, @entries ) = @_;

	$stream->UL;

	for my $entry (@entries) {
		$stream->LI->A( HREF => $entry->{URL} )->t( $entry->{description} )->_A->_LI;
	}

	$stream->_UL;
}

sub translate {
	my $perl_top = shift;
	$perl_top->report1("translate");
	my $perl_dir = $perl_top->{perl_dir};
	my $options  = $perl_top->{options};

	$options->{link_map}->set_depth(1);

	my $html_dir = $perl_top->{html_dir};
	my $pod_src  = $perl_top->{pod_src};
	my $pod_dst  = $perl_top->{pod_dst};
	my $page     = $perl_top->{page};
	my $source   = "$perl_dir/$pod_src/$page.pod";
	my $dest     = "$html_dir/$pod_dst/$page.html";
	my $html     = Pod::Tree::HTML::PerlTop->new( $source, $dest, %$options );
	my $links    = $perl_top->_get_links;

	$html->set_links($links);
	$html->translate;
}

sub get_top_entry {
	my $perl_top = shift;

	my $pod_dst = $perl_top->{pod_dst};
	my $page    = $perl_top->{page};

	+{
		URL         => "$pod_dst/$page.html",
		description => 'perl(1)'
	};
}

sub _get_links {
	my $perl_top = shift;

	my $links = {};
	$perl_top->_get_pod_links($links);
	$perl_top->_get_dist_links($links);

	$links;
}

sub _get_pod_links {
	my ( $perl_top, $links ) = @_;

	my $perl_dir = $perl_top->{perl_dir};
	my $pod_src  = $perl_top->{pod_src};

	my $dir = "$perl_dir/$pod_src";
	opendir( DIR, $dir )
		or die "Pod::Tree::PerlTop::get_pod_links: Can't opendir $dir: $!\n";
	my @files = readdir(DIR);
	closedir(DIR);

	my @pods   = grep {m( \.pod$ )x} @files;
	my @others = grep { $_ ne 'perl.pod' } @pods;

	for my $other (@others) {
		$other =~ s( \.pod$ )()x;
		$links->{$other} = $other;
	}
}

sub _get_dist_links {
	my ( $perl_top, $links ) = @_;

	my $dir = $perl_top->{perl_dir};
	opendir( DIR, $dir )
		or die "Pod::Tree::PerlTop::get_dist_links: Can't opendir $dir: $!\n";
	my @files = readdir(DIR);
	closedir(DIR);

	my @README = grep {/^README/} @files;

	for my $file (@README) {
		my ( $base, $ext ) = split m(\.), $file;
		$links->{"perl$ext"} = "../$file";
	}
}

1

__END__

=head1 NAME

Pod::Tree::PerlTop - generate a top-level index for Perl PODs

=head1 SYNOPSIS

  $perl_map = Pod::Tree::PerlMap->new;
  $perl_top = Pod::Tree::PerlTop->new( $perl_dir, $HTML_dir, $perl_map, %opts );
  
  $perl_top->index(@translators);
  $perl_top->translate;
  
  $top = $perl_top->get_top_entry;

=head1 DESCRIPTION

C<Pod::Tree::PerlTop> generates a top-level index for Perl PODs.

It also translates F<perl.pod> to F<perl.html>
The translator is specially hacked to insert links into the big verbatim
paragraph that lists all the other Perl PODs.

=head1 METHODS

=over 4

=item I<$perl_top> = C<new> C<Pod::Tree::PerlTop> I<$perl_dir>,
I<$HTML_dir>, I<$perl_map>, I<%options>

Creates and returns a new C<Pod::Tree::PerlTop> object.

I<$perl_dir> is the root of the Perl source tree.

I<$HTML_dir> is the directory where HTML files will be written.

I<$perl_map> maps POD names to URLs.
C<Pod::Tree::PerlTop> uses it to resolve links in the F<perl.pod> page.

I<%options> are passed through to C<Pod::Tree::HTML>.

=item I<$perl_top>->C<index>(I<@translators>)

Generates a top-level index of all the PODs. 
The index is written to I<HTML_dir>C</index.html>.

I<@translators> is a list of other C<Pod::Tree::Perl*> translator objects.
C<index> makes a C<get_top_entry> call on each of them to obtain
URLs and descriptions of the pages that it links to.

=item I<$perl_top>->C<translate>

Translates the F<perl.pod> file to HTML.
The HTML page is written to I<HTML_dir>C</pod/perl.html>

=item I<$perl_top>->C<get_top_entry>

Returns a hash reference of the form

  { URL         => $URL,
    description => $description }

C<Pod::Tree::PerlTop> uses this to build a top-level index of all the 
Perl PODs.

=back

=head1 REQUIRES

    5.005;
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
