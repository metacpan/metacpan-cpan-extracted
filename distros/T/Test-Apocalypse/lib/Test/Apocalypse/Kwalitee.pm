#
# This file is part of Test-Apocalypse
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Test::Apocalypse::Kwalitee;
$Test::Apocalypse::Kwalitee::VERSION = '1.006';
BEGIN {
  $Test::Apocalypse::Kwalitee::AUTHORITY = 'cpan:APOCAL';
}

# ABSTRACT: Plugin for Test::Kwalitee

use Test::More;
use Module::CPANTS::Analyse 0.95;
use version 0.77;

sub _do_automated { 0 }

# init CPANTS with the latest tarball
my $tarball;
sub _is_disabled {
	$tarball = _get_tarball( '.' );
	if ( ! defined $tarball ) {
		# Dist::Zilla-specific code, the tarball we want is 3 levels up ( when using dzp::TestRelease :)
		# [@Apocalyptic/TestRelease] Extracting /home/apoc/mygit/perl-pod-weaver-pluginbundle-apocalyptic/Pod-Weaver-PluginBundle-Apocalyptic-0.001.tar.gz to .build/MiNXla4CY7
		$tarball = _get_tarball( '../../..' );
		if ( ! defined $tarball ) {
			return 'Distribution tarball not found, unable to run CPANTS Kwalitee tests!';
		}
	}
}

# the following code was copied/plagarized/transformed from Test::Kwalitee, thanks!
# The reason why I didn't just use that module is because it doesn't print the kwalitee or consider extra metrics...
sub do_test {
	my $analyzer = Module::CPANTS::Analyse->new({
		'dist'	=> $tarball,
	});

	# set the number of tests / run analyzer
	my @indicators = $analyzer->mck()->get_indicators();
	plan tests => scalar @indicators;
	$analyzer->unpack;
	$analyzer->analyse;
	$analyzer->calc_kwalitee;
	my $kwalitee_points = 0;
	my $available_kwalitee = 0;

	# loop over the kwalitee metrics
	foreach my $gen ( @{ $analyzer->mck()->generators() } ) {
		foreach my $metric ( @{ $gen->kwalitee_indicators() } ) {
			# get the result
			my $result = $metric->{'code'}->( $analyzer->d(), $metric );
			my $type = 'CORE';
			if ( exists $metric->{'is_experimental'} and $metric->{'is_experimental'} ) {
				$type = 'EXPERIMENTAL';
			}
			if ( exists $metric->{'is_extra'} and $metric->{'is_extra'} ) {
				$type = 'EXTRA';
			}

			if ( $type eq 'CORE' or $result ) {
				ok( $result, "[$type] $metric->{'name'}" );
			} else {
				if ( ! $ENV{PERL_APOCALYPSE} ) {
					# non-core tests PASS automatically for ease of use
					pass( "[$type] $metric->{'name'} treated as PASS" );
				} else {
					fail( "[$type] $metric->{'name'}" );
				}
			}

			# print more diag if it failed
			if ( ! $result && $ENV{TEST_VERBOSE} ) {
				diag( '[' . $metric->{'name'} . '] error(' . $metric->{'error'} . ') remedy(' . $metric->{'remedy'} . ')' );
				if ( $metric->{'name'} eq 'prereq_matches_use' or $metric->{'name'} eq 'build_prereq_matches_use' ) {
					require Data::Dumper; ## no critic (Bangs::ProhibitDebuggingModules)
					diag( "module information: " . Data::Dumper::Dumper( $analyzer->d->{'uses'} ) );
				}
			}

			# should we tally up the kwalitee?
			if ( ! exists $metric->{'is_experimental'} || ! $metric->{'is_experimental'} ) {
				# we increment available only for CORE, not extra
				if ( ! exists $metric->{'is_extra'} || ! $metric->{'is_extra'} ) {
					$available_kwalitee++;
				}
				if ( $result ) {
					$kwalitee_points++;
				}
			}
		}
	}

	# for diag, print out the kwalitee of the module
	diag( "Kwalitee rating: " . sprintf( "%.2f%%", 100 * ( $kwalitee_points / $available_kwalitee ) ) . " [$kwalitee_points / $available_kwalitee]" );

	# That piece of crap dumps files all over :(
	_cleanup_debian_files();

	return;
}

sub _get_tarball {
	my $path = shift;

	# get our list of stuff, and try to find the latest tarball
	opendir( my $dir, $path ) or die "Unable to opendir: $!";
	my @dirlist = readdir( $dir );
	closedir( $dir ) or die "Unable to closedir: $!";

	# get the tarballs
	@dirlist = grep { /(?:tar(?:\.gz|\.bz2)?|tgz|zip)$/ } @dirlist;

	# short-circuit
	if ( scalar @dirlist == 0 ) {
		return;
	}

	# get the versions
	@dirlist = map { [ $_, $_ ] } @dirlist;
	for ( @dirlist ) {
		$_->[0] =~ s/^.*\-([^\-]+)(?:tar(?:\.gz|\.bz2)?|tgz|zip)$/$1/;
		$_->[0] = version->new( $_->[0] );
	}

	# sort by version
	@dirlist = reverse sort { $a->[0] <=> $b->[0] } @dirlist;

	# TODO should we use file::spec and stuff here?
	return $path . '/' . $dirlist[0]->[1];
}

# Module::CPANTS::Kwalitee::Distros suck!
#t/a_manifest..............1/1
##   Failed test at t/a_manifest.t line 13.
##          got: 1
##     expected: 0
## The following files are not named in the MANIFEST file: /home/apoc/workspace/VCS-perl-trunk/VCS-2.12.2/Debian_CPANTS.txt
## Looks like you failed 1 test of 1.
#t/a_manifest.............. Dubious, test returned 1 (wstat 256, 0x100)
sub _cleanup_debian_files {
	foreach my $file ( qw( Debian_CPANTS.txt ../Debian_CPANTS.txt ) ) {
		if ( -e $file and -f _ ) {
			my $status = unlink( $file );
			if ( ! $status ) {
				warn "unable to unlink $file";
			}
		}
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse Niebur Ryan kwalitee

=for Pod::Coverage do_test

=head1 NAME

Test::Apocalypse::Kwalitee - Plugin for Test::Kwalitee

=head1 VERSION

  This document describes v1.006 of Test::Apocalypse::Kwalitee - released October 25, 2014 as part of Test-Apocalypse.

=head1 DESCRIPTION

Encapsulates L<Test::Kwalitee> functionality. This plugin also processes the extra metrics, and prints out the kwalitee as a diag() for info.

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
