package Perl::Squish;

=pod

=head1 NAME

Perl::Squish - Reduce Perl code to a few characters as possible

=head1 DESCRIPTION

Perl source code can often be quite large, with copious amounts of
comments, inline POD documentation, and inline tests and other padding.

The actual code can represent as little as 10-20% of the content of
well-written modules.

In situations where the Perl files need to be included, but do not need
to be readable, this module will "squish" them. That is, it will strip
out as many characters as it can from the source, while leaving the
function of the code identical to the original.

=head1 METHODS

C<Perl::Squish> is a fully L<PPI::Transform>-compatible class. See that
module's documentation for more information.

=cut

use 5.006;
use strict;
use Params::Util   0.14 '_INSTANCE';
use PPI::Transform 1.200 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.06';
	@ISA     = 'PPI::Transform';
}





#####################################################################
# Main Methods

sub document {
	my $self     = shift;
	my $document = _INSTANCE(shift, 'PPI::Document') or return undef;

	# Remove the easy things
	$document->prune('Statement::End');
	$document->prune('Token::Comment');
	$document->prune('Token::Pod');

	# Remove redundant braces from ->method()
	$document->prune( sub {
		my $braces = $_[1];
		$braces->isa('PPI::Structure::List')      or return '';
		$braces->children == 0                    or return '';
		my $method = $braces->sprevious_sibling   or return '';
		$method->isa('PPI::Token::Word')          or return '';
		$method->content !~ /:/                   or return '';
		my $operator = $method->sprevious_sibling or return '';
		$operator->isa('PPI::Token::Operator')    or return '';
		$operator->content eq '->'                or return '';
		return 1;
	} );


	# Lets also do some whitespace cleanup
	$document->index_locations or return undef;
	my $whitespace = $document->find('Token::Whitespace');
	foreach ( @$whitespace ) {
		if ( $_->location->[1] == 1 and $_->{content} =~ /\n\z/s ) {
			$_->delete;
		} else {
			$_->{content} = $_->{content} =~ /\n/ ? "\n" : " ";
		}
	}
	$document->flush_locations;

	# Remove whitespace in qw//
	$document->find( sub {
		my $qw = $_[1];
		$qw->isa('PPI::Token::QuoteLike::Words') or return '';
		
		# FIXME this breaks encapsulation. I'd like to
		# just make a new qw object and replace this one,
		# but I just can't figure out how from the PPI docs.
		# --Steffen
		my $section = $qw->{sections}[0];
		my $type    = $section->{type};
		my $d_left  = substr($type, 0, 1);
		my $d_right = substr($type, 1, 2);
		
		my $content = $qw->content();
		$content =~ s/^\s*qw\s*\Q$d_left\E\s*/qw$d_left/;
		$content =~ s/\s*\Q$d_right\E\s*$/$d_right/;
		$content =~ s/\s+/ /g;
		
		$qw->set_content($content);
		
		$section->{position} = length("qw$d_left");
		$section->{size} = length($content) - $section->{position} - 1;
		
		return '';
	} );

	die $document->errstr if $document->errstr;

	$document->flush_locations;

	$document;
}

1;

=pod

=head1 TO DO

To keep things simple for the talk, I really don't get into some of the
more in depth stuff that could make things even smaller.

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Squish>

For general comments, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<PPI>

=head1 COPYRIGHT

Copyright 2005 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
