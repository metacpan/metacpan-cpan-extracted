package Pod::Tree::PerlMap;
use 5.006;
use strict;
use warnings;

our $VERSION = '1.29';

sub new {
	my ($class) = @_;

	my $perl_map = { prefix => '' };

	bless $perl_map, $class;
}

sub set_depth {
	my ( $perl_map, $depth ) = @_;

	$perl_map->{prefix} = '../' x $depth;
}

sub add_page {
	my ( $perl_map, $page, $file ) = @_;

	$perl_map->{page}{$page} = $file;
}

sub add_func {
	my ( $perl_map, $func, $file ) = @_;

	$perl_map->{func}{$func} = $file;
}

sub force_func {
	my ( $perl_map, $force_func ) = @_;

	$perl_map->{force_func} = $force_func;
}

sub map {
	my ( $perl_map, $base, $page, $section ) = @_;

	# print "map $base, $page, $section ->";

	my $prefix     = $perl_map->{prefix};
	my $force_func = $perl_map->{force_func};
	my $func       = ( split m(\s+), $section )[0];    # e.g.  L<"eval BLOCK">
	my $file       = $perl_map->{func}{$func};

	if ( ( $page eq 'perlfunc' or $page eq '' and $force_func ) and $file ) {
		$page    = $prefix . 'pod/func/' . $file;
		$section = '';
	}
	elsif ( $perl_map->{page}{$page} ) {
		$page = $prefix . $perl_map->{page}{$page};
	}

	# print "$base, $page, $section\n";
	( $base, $page, $section );
}

1

__END__

=head1 NAME

Pod::Tree::PerlMap - map names to URLs

=head1 SYNOPSIS

  $perl_map = new Pod::Tree::PerlMap;
  
  $perl_map->add_page  ($name, $file);
  $perl_map->add_func  ($func, $file);
  $perl_map->force_func(0);
  $perl_map->force_func(1);
  $perl_map->set_depth ($depth);
  
  ($base, $page, $section) = $perl_map->map($base, $page, $section);

=head1 DESCRIPTION

C<Pod::Tree::PerlMap> maps LE<lt>E<gt> markups to URLs.

The C<Pod::Tree::Perl*> translators make entries in the map.
C<Pod::Tree::HTML> uses the map to translate links before it emits
them.

=head1 METHODS

=over 4

=item I<$perl_map>->C<add_page>(I<$name>, I<$file>)

Map I<$name> to I<$file>.
I<$name> is the name of a POD, as used in LE<lt>E<gt> markups.
I<$file> is the path to the HTML file that is the target of the link.

=item I<$perl_map>->C<add_func>(I<$func>, I<$file>)

Maps I<$func> to I<$file>.
I<$func> is the name of a function described in F<perlfunc.pod>.
I<$file> is the name of the HTML file where it is described.

=item I<$perl_map>->C<force_func>(I<$state>)

Controls interpretation of links of the form LE<lt>funcE<gt>.

If I<$state> is true, calls to C<map> will interpret
LE<lt>funcE<gt> as LE<lt>perlfunc/funcE<gt>.

If I<$state> is false, calls to C<map> will interpret 
LE<lt>funcE<gt> normally.

=item I<$perl_map>->C<set_depth>(I<$depth>)

Informs I<$perl_map> of the depth of the referring page in the HTML
directory tree. 
I<$perl_map> needs to know this so that it can construct
relative links.

=item (I<$base>, I<$page>, I<$section>) = 
I<$perl_map>->C<map>(I<$base>, I<$page>, I<$section>)

Remaps a link.

I<$base> is the base URL for the HTML page, if any.
I<$page> is the page given in an LE<lt>E<gt> markup.
I<$section> is the section given in the LE<lt>E<gt> markup, if any.

C<map> returns a new I<$base>, I<$page>, and I<$section>
that can be used to construct a link to the HTML page.

=back

=head1 REQUIRES

Nothing.

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Steven McDougall, swmcd@world.std.com

=head1 COPYRIGHT

Copyright (c) 2000 by Steven McDougall.  This module is free software;
you can redistribute it and/or modify it under the same terms as Perl.

