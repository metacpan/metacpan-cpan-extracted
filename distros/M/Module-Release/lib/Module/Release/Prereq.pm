use v5.16;

package Module::Release::Prereq;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT = qw( check_prereqs _get_prereq_ignore_list );

our $VERSION = '2.127';

=encoding utf8

=head1 NAME

Module::Release::Prereq - Check pre-requisites list in build file

=head1 SYNOPSIS

The release script automatically loads this module and checks your
prerequisite declaration against what you actually used in the
tests.

=head1 DESCRIPTION

=over 4

=item check_prereqs

Run `perl -MTest::Prereq -eprereq_ok`. If it doesn't see "^ok 1"
it dies.

It looks in local_name to get the name of the distribution file.

=cut


my %Prereq_modules = (
	'' => 'Test::Prereq',
	'Makefile.PL' => 'Test::Prereq',
	'Build.PL' => 'Test::Prereq::Build',
	);

sub check_prereqs {
	my $prereqs_type = $_[0]->config->makefile_PL;
	my $test_prereqs = $Prereq_modules{$prereqs_type // ''} || 'Test::Prereq';

	eval "require $test_prereqs; 1 " or
		$_[0]->_die( "You need $test_prereqs to check prereqs" );

	$_[0]->_print( "Checking prereqs with $test_prereqs... " );

	my $perl = $_[0]->{perl};

	my @ignore = $_[0]->_get_prereq_ignore_list;

	my $messages = $_[0]->run(
		qq|$perl -M$test_prereqs -e "prereq_ok( undef, undef, [ qw(@ignore) ] )"|
		);

	$_[0]->_die( "Prereqs had a problem:\n$messages\n" )
		unless $messages =~ m/^ok 1 - Prereq test/m;

	$_[0]->_print( "done\n" );
	}

sub _get_prereq_ignore_list {
	my @ignore = split /\s+/, $_[0]->config->ignore_prereqs || '';
	}

=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is in GitHub

	https://github.com/briandfoy/module-release

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2021, brian d foy C<< <bdfoy@cpan.org> >>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=cut

1;
