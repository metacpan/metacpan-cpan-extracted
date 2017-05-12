package Pod::TOC;
use strict;

use parent qw( Pod::Simple );
use vars qw( $VERSION );

use warnings;
no warnings;

$VERSION = '1.12';

BEGIN {
	my @Head_levels = 0 .. 4;

	my %flags = map { ( "head$_", $_ ) } @Head_levels;

	foreach my $directive ( keys %flags ) {
		no strict 'refs';

		*{"_start_$directive"} = sub {
			$_[0]->_set_flag( "_start_$directive" );
			print { $_[0]->output_fh } "\t" x ( $_[0]->_get_flag - 1 )
			};

		*{"_end_$directive"}   = sub {
			$_[0]->_set_flag( "_end_$directive" );
			print { $_[0]->output_fh } "\n"
			};
		}

	sub _is_valid_tag { exists $flags{ $_[1] } }
	sub _get_tag      {        $flags{ $_[1] } }
	}

sub _handle_element {
	my( $self, $element, $args ) = @_;

	my $caller_sub = ( caller(1) )[3];
	return unless $caller_sub =~ s/.*_(start|end)$/_${1}_$element/;

	my $sub = $self->can( $caller_sub );

	$sub->( $self, $args ) if $sub;
	}

sub _handle_element_start {
	my $self = shift;
	$self->_handle_element( @_ );
	}

sub _handle_element_end {
	my $self = shift;
	$self->_handle_element( @_ );
	}

sub _handle_text {
	return unless $_[0]->_get_flag;

	print { $_[0]->output_fh } $_[1];
	}


{
my $Flag;

sub _get_flag { $Flag }

sub _set_flag {
	my( $self, $caller ) = @_;

	return unless $caller;

	my $on  = $caller =~ m/^_start_/ ? 1 : 0;
	my $off = $caller =~ m/^_end_/   ? 1 : 0;

	unless( $on or $off ) { return };

	my( $tag ) = $caller =~ m/^_.*?_(.*)/g;

	return unless $self->_is_valid_tag( $tag );

	$Flag = do {
		   if( $on  ) { $self->_get_tag( $tag ) } # set the flag if we're on
		elsif( $off ) { undef }                   # clear if we're off
		};

	}
}

=head1 NAME

Pod::TOC - Extract a table of contents from a Pod file

=head1 SYNOPSIS

This is a C<Pod::Simple> subclass, so it can do the same things.

	use Pod::TOC;

	my $parser = Pod::TOC->new;

	my $toc;
	open my($output_fh), ">", \$toc;

	$parser->output_fh( $output_fh );

	$parser->parse_file( $input_file );

=head1 DESCRIPTION

This is a C<Pod::Simple> subclass to extract a table of contents
from a pod file. It has the same interface as C<Pod::Simple>, and
only changes the internal bits.

=head1 SEE ALSO

L<Pod::Perldoc::ToToc>, L<Pod::Simple>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/pod-perldoc-totoc

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2013, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut


1;
