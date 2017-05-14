package Padre::Plugin::HTML::Document;
BEGIN {
  $Padre::Plugin::HTML::Document::VERSION = '0.14';
}

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();
use Padre::Wx       ();

our @ISA = 'Padre::Document';

sub get_command {
	my $self = shift;

	my $filename = $self->filename;
	Wx::LaunchDefaultBrowser($filename);
}

sub comment_lines_str { return [ '<!--', '-->' ] }

1;

__END__
=pod

=head1 NAME

Padre::Plugin::HTML::Document

=head1 VERSION

version 0.14

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

