package Padre::Plugin::PDL::Document;

use 5.008;
use strict;
use warnings;
use Padre::Document::Perl ();

our $VERSION = '0.05';

our @ISA = 'Padre::Document::Perl';

sub get_help_provider {
	require Padre::Plugin::PDL::Help;
	return Padre::Plugin::PDL::Help->new;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::PDL::Document - Padre PDL-enabled Perl document

=cut
