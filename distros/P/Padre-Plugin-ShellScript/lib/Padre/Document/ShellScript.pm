package Padre::Document::ShellScript;
BEGIN {
  $Padre::Document::ShellScript::VERSION = '0.03';
}

# ABSTRACT: Shell script document support for Padre

use 5.008;
use strict;
use warnings;

our @ISA = 'Padre::Document';
use Padre::Document ();

sub get_command {
	my $self = shift;

	my $arg_ref = shift || {};

	my $debug = exists $arg_ref->{debug} ? $arg_ref->{debug} : 0;
	my $trace = exists $arg_ref->{trace} ? $arg_ref->{trace} : 0;

	# TODO get shebang

	# Check the file name
	my $filename = $self->filename;

	my $dir = File::Basename::dirname($filename);
	chdir $dir;
	return $trace
		? qq{"sh" "-xv" "$filename"}
		: qq{"sh" "$filename"};
}

sub comment_lines_str {
	return '#';
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

__END__
=pod

=head1 NAME

Padre::Document::ShellScript - Shell script document support for Padre

=head1 VERSION

version 0.03

=head1 AUTHORS

=over 4

=item *

Claudio Ramirez <padre.claudio@apt-get.be>

=item *

Zeno Gantner <zenog@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Claudio Ramirez, Zeno Gantner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

