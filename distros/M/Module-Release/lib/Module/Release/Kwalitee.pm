package Module::Release::Kwalitee;

use strict;
use warnings;
use Exporter qw(import);
use vars qw($VERSION);

our @EXPORT = qw(check_kwalitee cpants_lint cpants_pass_regex );

$VERSION = '2.123';

=encoding utf8

=head1 NAME

Module::Release::Kwalitee - Play the CPANTS game

=head1 SYNOPSIS

The release script automatically loads this module if it thinks that you
want to check the kwalitee of your module.

=head1 DESCRIPTION

=over 4

=item check_kwalitee

Run `cpants_lints.pl distname.tgz`. If it doesn't see "a 'perfect' distribution"
it dies.

It looks in local_name to get the name of the distribution file.

=cut

sub check_kwalitee
	{
	eval "require Module::CPANTS::Analyse; 1" or
		$_[0]->_die( "You need Module::CPANTS::Analyse to check kwalitee" );

	$_[0]->_print( "Checking kwalitee... " );

	my $name    = $_[0]->local_file;
	my $program = $_[0]->cpants_lint;

	{
	no warnings 'uninitialized';
	$_[0]->_die( " no $name---aborting release\n" ) unless -e $name;
	}

	# XXX: what if it's not .tar.gz?
	my $messages = $_[0]->run( "$program $name" );

	my $regex = $_[0]->cpants_pass_regex;

	$_[0]->_die( "Kwalitee is less than perfect:\n$messages\n" )
		unless $messages =~ m/$regex/;

	$_[0]->_print( "done\n" );
	}

=item cpants_lint

=cut

sub cpants_lint { "cpants_lint.pl" }

=item cpants_pass_regex

The regex to use to evaluate the output of cpants_lint.pl to see
if everything was okay.

=cut

sub cpants_pass_regex { qr/a 'perfect' distribution!/ }

=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/module-release

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
