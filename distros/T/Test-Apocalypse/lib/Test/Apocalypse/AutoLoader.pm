#
# This file is part of Test-Apocalypse
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Test::Apocalypse::AutoLoader;
$Test::Apocalypse::AutoLoader::VERSION = '1.006';
BEGIN {
  $Test::Apocalypse::AutoLoader::AUTHORITY = 'cpan:APOCAL';
}

# ABSTRACT: Plugin for Test::AutoLoader

use Test::More;
use Test::AutoLoader 0.03;
use YAML 0.70;

sub do_test {
	# does META.yml exist?
	if ( -e 'META.yml' and -f _ ) {
		_load_yml( 'META.yml' );
	} else {
		# maybe one directory up?
		if ( -e '../META.yml' and -f _ ) {
			_load_yml( '../META.yml' );
		} else {
			plan tests => 1;
			fail( 'META.yml is missing, unable to process it!' );
		}
	}

	return;
}

# loads a yml file
sub _load_yml {
	# we'll load a file
	my $file = shift;

	# okay, proceed to load it!
	my $data;
	eval {
		$data = YAML::LoadFile( $file );
	};
	if ( $@ ) {
		plan tests => 1;
		fail( "Unable to load $file => $@" );
		return;
	}

	# massage the data
	$data = $data->{'provides'};

	# Okay, how many modules do we have?
	if ( scalar keys %$data > 0 ) {
		plan tests => scalar keys %$data;
	} else {
		plan skip_all => "No provided modules found in META.yml";
	}

	# analyze every one of them!
	foreach my $module ( keys %$data ) {
		if ( _module_has_autoload( $module ) ) {
			autoload_ok( $module );
		} else {
			pass( "Skipping '$module' because it has no autoloaded files" );
		}
	}

	return;
}

# basically ripped off from Test::AutoLoader so we don't get the annoying "unable to find autoload directory" failure
sub _module_has_autoload {
	my $pkg = shift;
	my $dirname;

	if (defined($dirname = $INC{"$pkg.pm"})) {
		if ( $^O eq 'MacOS' ) {
			$pkg =~ tr#/#:#;
			$dirname =~ s#^(.*)$pkg\.pm\z#$1auto:$pkg#s;
		} else {
			$dirname =~ s#^(.*)$pkg\.pm\z#$1auto/$pkg#s;
		}
	}
	unless (defined $dirname and -d $dirname && -r _ ) {
		return 0;
	} else {
		return 1;
	}
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse Niebur Ryan

=for Pod::Coverage do_test

=head1 NAME

Test::Apocalypse::AutoLoader - Plugin for Test::AutoLoader

=head1 VERSION

  This document describes v1.006 of Test::Apocalypse::AutoLoader - released October 25, 2014 as part of Test-Apocalypse.

=head1 DESCRIPTION

Encapsulates L<Test::AutoLoader> functionality.

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
