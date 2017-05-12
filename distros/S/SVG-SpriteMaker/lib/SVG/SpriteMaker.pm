package SVG::SpriteMaker;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.002';
our @EXPORT = qw/make_sprite/;
our @EXPORT_OK = @EXPORT;

use parent qw/Exporter/;
use re '/s';

use Carp;
use File::Basename;

use SVG -indent => '', -elsep => '';
use SVG::Parser;

sub make_sprite {
	my ($prefix, @images) = @_;
	my $sub = ref $prefix eq 'CODE' ? $prefix : sub {
		my $base = scalar fileparse $_[0], qr/[.].*/;
		"$prefix-$base"
	};
	my $sprite = SVG->new(-inline => 1);
	my $parser = SVG::Parser->new;
	@images = map {[ $sub->($_) => $parser->parse_file($_) ]} @images;
	my ($x, $mh) = (0, 0);
	my %ids = map { $_->[0] => 1 } @images; # start with image names

	for (@images) {
		my ($img, $doc) = @$_;
		my $svg = $doc->getFirstChild;
		my ($w) = $svg->attr('width') =~ /([0-9.]*)/ or carp "Image $img has no width";
		my ($h) = $svg->attr('height') =~ /([0-9.]*)/ or carp "Image $img has no height";
		$mh = $h if $h > $mh;
		$svg->attr(x => $x);
		$svg->attr(version => undef);
		my $view = $sprite->view(id => $img, viewBox => "$x 0 $w $h");
		$x += $w + 5;

		my @all_elems = $svg->getElements;
		my @duplicate_ids;
		for my $elem (@all_elems) {
			my $id = $elem->attr('id');
			next unless $id;
			if ($ids{$id}) {
				push @duplicate_ids, $id;
			} else {
				$ids{$id} = 1;
			}
		}

		warn <<"EOF" if @duplicate_ids && !$ENV{SVG_SPRITEMAKER_NO_DUPLICATE_WARNINGS};
Some IDs (@duplicate_ids) in $img also exist in previous images.
Trying to fix automatically, but this might produce a broken SVG.
Fix IDs manually to avoid incorrect output.
EOF

		for my $oid (@duplicate_ids) {
			my $nid = $oid;
			$nid .= '_' while $ids{$nid};
			$svg->getElementByID($oid)->attr(id => $nid);
			for my $elem (@all_elems) {
				my %attribs = %{$elem->getAttributes};
				for my $key (keys %attribs) {
					if ($attribs{$key} =~ /#$oid\b/) {
						$attribs{$key} =~ s/#$oid\b/#$nid/g;
						$elem->attr($key => $attribs{$key});
					}
				}
				if ($elem->cdata =~ /#$oid\b/) {
					$elem->cdata($elem->cdata =~ s/#$oid\b/#$nid/gr);
				}
			}
		}

		$view->getParent->insertAfter($svg, $view);
	}

	# Keep a reference to the documents to prevent garbage collection
	$sprite->{'--images'} = \@images;
	$sprite->getFirstChild->attr(viewBox => "0 0 $x $mh");
	$sprite
}

1;
__END__

=encoding utf-8

=head1 NAME

SVG::SpriteMaker - Combine several SVG images into a single SVG sprite

=head1 SYNOPSIS

  use File::Slurp qw/write_file/;
  use SVG::SpriteMaker;
  my $sprite = make_sprite img => '1.svg', '2.svg', '3.svg';
  write_file 'sprite.svg', $sprite->xmlify;
  # You can now use <img src="sprite.svg#img-1" alt="...">

  my @images = <dir/*>; # dir/ImageA.svg dir/ImageB.svg
  $sprite = make_sprite sub {
    my ($name) = $_[0] =~ m,/([^/.]*),;
    uc $name
  }, @images; # Sprite will have identifiers #IMAGEA #IMAGEB

=head1 DESCRIPTION

A SVG sprite is a SVG image that contains several smaller images that
can be referred to using fragment identifiers. For example, this HTML
fragment:

  <img src="/img/cat.svg" alt="A cat">
  <img src="/img/dog.svg" alt="A dog">
  <img src="/img/horse.svg" alt="A horse">

Can be replaced with

  <img src="/img/sprite.svg#cat" alt="A cat">
  <img src="/img/sprite.svg#dog" alt="A dog">
  <img src="/img/sprite.svg#horse" alt="A horse">

This module exports a single function:

=head2 B<make_sprite>(I<$prefix>|I<$coderef>, I<@files>)

Takes a list of filenames, combines them and returns the resulting
sprite as a L<SVG> object. Each SVG must have width and height
attributes whose values are in pixels.

If the first argument is a coderef, it will be called with each
filename as a single argument and it should return the desired
fragment identifier.

If the first argument is not a coderef, the following coderef will be
used:

  sub {
    my $base = scalar fileparse $_[0], qr/\..*/s;
    "$prefix-$base"
  };

where I<$prefix> is the value of the first argument.

If an ID is shared between two or more input files, this module will
try to rename each occurence except for the first one. This operation
might have false positives (attributes/cdatas that are mistakenly
identified to contain the ID-to-be-renamed) and false negatives
(attributes/cdatas that actually contain the ID-to-be-renamed but this
is missed by the module), and as such SVG::SpriteMaker will warn if
duplicate IDs are detected. You can suppress this warning by setting
the C<SVG_SPRITEMAKER_NO_DUPLICATE_WARNINGS> environment variable to a
true value.

=head1 SEE ALSO

L<svg-spritemaker>, L<https://css-tricks.com/svg-fragment-identifiers-work/>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
