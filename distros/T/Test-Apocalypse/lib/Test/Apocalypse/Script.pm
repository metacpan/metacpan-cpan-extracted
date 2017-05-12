#
# This file is part of Test-Apocalypse
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Test::Apocalypse::Script;
$Test::Apocalypse::Script::VERSION = '1.006';
BEGIN {
  $Test::Apocalypse::Script::AUTHORITY = 'cpan:APOCAL';
}

# ABSTRACT: Plugin for Test::Script

use Test::More;
use Test::Script 1.07;
use File::Find::Rule 0.32;

# TODO we need to search more locations/extensions/etc?
my @files;
sub _is_disabled {
	# TODO Stupid FFR complains if the dir doesn't exist?!?
	my @dirs;
	foreach my $d ( qw( examples bin scripts ) ) {
		push @dirs, $d if -d $d;
	}
	@files = File::Find::Rule->file->name( qr/\.pl$/ )->in( @dirs );

	# Skip if no scripts
	if ( ! scalar @files ) {
		return 'No script files found in the distribution';
	}
}

sub do_test {
	plan tests => scalar @files;
	foreach my $f ( @files ) {
		script_compiles( $f );
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse Niebur Ryan

=for Pod::Coverage do_test

=head1 NAME

Test::Apocalypse::Script - Plugin for Test::Script

=head1 VERSION

  This document describes v1.006 of Test::Apocalypse::Script - released October 25, 2014 as part of Test-Apocalypse.

=head1 DESCRIPTION

Encapsulates L<Test::Script> functionality.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Test::Apocalypse|Test::Apocalypse>

=back

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
