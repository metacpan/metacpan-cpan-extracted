package Padre::Plugin::Perl6::Help;
BEGIN {
  $Padre::Plugin::Perl6::Help::VERSION = '0.71';
}

# ABSTRACT: Perl 6 Help provider for Padre

use strict;
use warnings;

# For Perl 6 documentation support
use Padre::Help ();

our @ISA = 'Padre::Help';

use Class::XSAccessor accessors => {
	_grok => '_grok', # App::Grok -> Perl 6 Documentation Reader
};


#
# Initialize help
#
sub help_init {
	my $self = shift;
	require App::Grok;
	$self->_grok( App::Grok->new );
}

#
# Renders the help topic content using App::Grok into XHTML
#
sub help_render {
	my ( $self, $topic ) = @_;

	my $grok     = $self->_grok;
	my $html     = $grok->render_target( $topic, 'xhtml' );
	my $location = $grok->locate_target($topic);
	return ( $html, $location );
}

#
# Returns the help topic list
#
sub help_list {
	my ($self) = @_;

	# Return Grok's target index
	my @index = $self->_grok->target_index;

	# Return a unique sorted index
	my %seen = ();
	my @unique_sorted_index = sort grep { !$seen{$_}++ } @index;
	return \@unique_sorted_index;
}

1;



=pod

=head1 NAME

Padre::Plugin::Perl6::Help - Perl 6 Help provider for Padre

=head1 VERSION

version 0.71

=head1 DESCRIPTION

Perl 6 Help index is built here and rendered.

=head1 AUTHORS

=over 4

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Gabor Szabo L<http://szabgab.com/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

