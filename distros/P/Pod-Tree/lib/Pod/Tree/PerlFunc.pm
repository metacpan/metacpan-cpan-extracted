package Pod::Tree::PerlFunc;
use 5.006;
use strict;
use warnings;
use Pod::Tree;
use Pod::Tree::HTML;
use Pod::Tree::PerlUtil;

our $VERSION = '1.31';

use base qw(Pod::Tree::PerlUtil);

sub new {
	my ( $class, $perl_dir, $html_dir, $link_map, %options ) = @_;

	my %defaults = (
		bgcolor => '#ffffff',
		text    => '#000000'
	);

	my $options = { %defaults, %options, link_map => $link_map };

	my $perl_func = {
		perl_dir => $perl_dir,
		html_dir => $html_dir,
		pod_dir  => 'pod',
		func_dir => 'func',
		page     => 'perlfunc',
		options  => $options
	};

	bless $perl_func, $class;
}

sub scan {
	my $perl_func = shift;
	$perl_func->report1("scan");

	$perl_func->load_tree;
	$perl_func->scan_tree;
}

sub load_tree {
	my $perl_func  = shift;
	my $perl_dir   = $perl_func->{perl_dir};
	my $pod_dir    = $perl_func->{pod_dir};
	my $page       = $perl_func->{page};
	my $source     = "$perl_dir/$pod_dir/$page.pod";
	my $win_source = "$perl_dir/lib/$pod_dir/$page.pod";

	my $tree = Pod::Tree->new;
	$tree->load_file($source)         or    # for building the doc set from a Perl distribution
		$tree->load_file($win_source) or    # for building the doc set from a Windows installation
		die "Pod::Tree::PerlFunc::scan: Can't find $source or $win_source\n";

	my $node  = $tree->pop;
	my $funcs = $node->get_children;

	$perl_func->{tree}  = $tree;
	$perl_func->{funcs} = $funcs;
}

sub scan_tree {
	my $perl_func = shift;
	my $funcs     = $perl_func->{funcs};
	my @funcs     = @$funcs;

	my $link_map = $perl_func->{options}{link_map};

	while (@funcs) {
		my @items = Shift_Items( \@funcs );
		my ( $func0, $file0 ) = Parse_Name( $items[0] );

		for my $item (@items) {
			my ( $func, $file ) = Parse_Name($item);
			$perl_func->report2($func);
			$perl_func->{index}{$func} = $file0;
			$link_map->add_func( $file, $file0 );
		}
	}
}

sub index {
	my $perl_func = shift;
	$perl_func->report1("index");

	$perl_func->add_links;
	$perl_func->add_index;

	my $tree     = $perl_func->{tree};
	my $html_dir = $perl_func->{html_dir};
	my $pod_dir  = $perl_func->{pod_dir};
	my $page     = $perl_func->{page};
	my $options  = $perl_func->{options};

	$perl_func->mkdir("$html_dir/$pod_dir/");
	$options->{link_map}->set_depth(1);

	my $dest = "$html_dir/$pod_dir/$page.html";
	my $html = Pod::Tree::HTML->new( $tree, $dest, %$options );
	$html->translate;
}

sub add_links {
	my $perl_func = shift;
	my $tree      = $perl_func->{tree};

	$tree->walk( sub { $perl_func->_add_links(shift) } );
}

sub _add_links {
	my ( $perl_func, $node ) = @_;

	$node->is_sequence or return 1;
	$node->get_letter eq 'C' or return 1;

	my ($func) = Parse_Name($node);
	my $file = $perl_func->{index}{$func};
	$file or return 1;

	# :TRICKY: *replaces* the node in the tree
	my $page = $perl_func->{page};
	$_[1] = Pod::Tree::Node->link( $node, $page, $file );

	0;
}

sub add_index {
	my $perl_func = shift;

	my %funcs;
	my $index = $perl_func->{index};
	for my $func ( sort keys %$index ) {
		my $file = $index->{$func};
		my $letter = substr( $func, 0, 1 );
		push @{ $funcs{$letter} }, [ $func, $file ];
	}

	my $page = $perl_func->{page};
	my @lines;
	for my $letter ( sort keys %funcs ) {
		my $funcs = $funcs{$letter};
		my @links = map {"L<C<$_->[0]>|$page/$_->[1]>"} @$funcs;
		my $line  = join ", ", @links;
		push @lines, $line;
	}

	my $pod = join "\n\n", @lines;

	my $tree = Pod::Tree->new;
	$tree->load_string($pod);
	my $children = $tree->get_root->get_children;

	$perl_func->{tree}->push(@$children);
}

sub translate {
	my $perl_func = shift;
	$perl_func->report1("translate");

	my $html_dir = $perl_func->{html_dir};
	my $pod_dir  = $perl_func->{pod_dir};
	my $func_dir = $perl_func->{func_dir};
	$perl_func->mkdir("$html_dir/$pod_dir/$func_dir");

	my $perl_dir = $perl_func->{perl_dir};
	my $funcs    = $perl_func->{funcs};
	my $options  = $perl_func->{options};
	my $link_map = $options->{link_map};

	$link_map->set_depth(2);
	$link_map->force_func(1);
	$options->{toc} = 0;

	while (@$funcs) {
		my @items = Shift_Items($funcs);
		my ( $func, $file ) = Parse_Name( $items[0] );
		$perl_func->report2("func/$file");

		my $tree = Pod::Tree->new;
		$tree->load_string("=head1 $func\n\n=over 4\n\n=back");
		my $list = $tree->get_root->get_children->[1];
		$list->set_children( \@items );
		$list->_set_list_type;

		$options->{title} = $func;
		my $dest = "$html_dir/$pod_dir/$func_dir/$file.html";
		my $html = Pod::Tree::HTML->new( $tree, $dest, %$options );
		$html->translate;
	}

	$link_map->force_func(0);
}

sub Shift_Items {
	my $funcs = shift;
	my @items;

	while (@$funcs) {
		my $item = shift @$funcs;
		push @items, $item;

		@$funcs or last;

		my ($func0) = Parse_Name($item);
		my ($func1) = Parse_Name( $funcs->[0] );
		my $sibs0   = $item->get_siblings;
		$func0 eq $func1 or @$sibs0 == 0 or last;
	}

	@items;
}

sub Parse_Name {
	my $item  = shift;
	my $text  = $item->get_deep_text;
	my @words = split m([^\w\-]+), $text;

	my $func = $words[0];
	my $file = $func;
	$file =~ tr(A-Za-z0-9_-)()cd;

	( $func, $file );
}

1

__END__

=head1 NAME

Pod::Tree::PerlFunc - translate F<perlfunc.pod> to HTML

=head1 SYNOPSIS

  $perl_map  = Pod::Tree::PerlMap->new;
  $perl_func = Pod::Tree::PerlFunc->new($perl_dir, $HTML_dir, $perl_map, %opts);

  $perl_func->scan;
  $perl_func->index;
  $perl_func->translate;

=head1 DESCRIPTION

C<Pod::Tree::PerlFunc> translates F<perlfunc.pod> to HTML.
It creates a separate HTML page for each function description in
F<perlfunc.pod>. The pages for the individual descriptions are
named after the function and written to a F<func/> subdirectory.
F<perlfunc.html> is generated as an index to all the pages in 
F<func/>.

C<Pod::Tree::PerlFunc> generates and uses an index of the functions 
that it finds in F<perlfunc.pod> to construct HTML links.
Other modules can also use this index.

=head1 METHODS

=over 4

=item I<$perl_func> = C<new> C<Pod::Tree::PerlFunc> I<$perl_dir>,
I<$HTML_dir>, I<$perl_map>, I<%options>

Creates and returns a new C<Pod::Tree::PerlFunc> object.

I<$perl_dir> is the root of the Perl source tree.

I<$HTML_dir> is the directory where HTML files will be written.

I<$perl_map> maps function names to URLs.

I<%options> are passed through to C<Pod::Tree::HTML>.

=item I<$perl_func>->C<scan>

Reads F<perlfunc.pod> and identifies all the functions in it.
Each function that is identified is entered into I<$perl_map>.

=item I<$perl_func>->C<index>

Generates a top-level index of all the functions. 
The index is written to I<HTML_dir>C</pod/perlfunc.html>.

=item I<$perl_func>->C<translate>

Translates each function found by C<scan> to HTML.
The HTML pages are written to I<HTML_dir>C</pod/func/>.

=back

=head1 LINKING

C<Pod::Tree::PerlFunc> indexes every C<=item> paragraph in 
F<perlfunc.html>. To link, for example, to the C<abs> function, write

    L<func/abs>

=head1 REQUIRES

    5.005;
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
you can redistribute it and/or modify it under the same terms as Perl itself.
