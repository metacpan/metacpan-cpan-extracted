package Padre::Document::HTML;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();
use Padre::Wx ();

our $VERSION = '0.23';
our @ISA     = 'Padre::Document';

sub get_command {
	my $self     = shift;

	my $filename = $self->filename;	
	Wx::LaunchDefaultBrowser($filename);
}

sub comment_lines_str { return [ '<!--', '-->' ] }

1;
