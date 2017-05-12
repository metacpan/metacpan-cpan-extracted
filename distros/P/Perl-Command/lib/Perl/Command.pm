
package Perl::Command;

use strict 'vars', 'subs';
use 5.006;
use warnings;

our $VERSION = 0.01;

=head1 NAME

Perl::Command - return an ARGV for running this perl

=head1 SYNOPSIS

 use Perl::Command;

 # clear PERL5LIB and PERL5OPT to stop any monkey business
 NOLIB;

 system(@PERL, "-le", "print for @INC");

=head1 DESCRIPTION

This module exports one symbol - @PERL, which is very similar to C<$^X>
(see L<perlvar/$^X>), except it also contains a list of commands which
will give the sub-perl all of the same @INC paths as this one.

This is a very trivial module; its principle use is for bundling with
modules whose test scripts need to test running scripts.

=cut

our @PERL;
use base 'Exporter';

our @EXPORT = qw(@PERL NOLIB);

BEGIN {
	local ( $ENV{PERL5LIB} ) = "";
	local ( $ENV{PERL5OPT} ) = "";
	my @default_inc = `$^X -le 'print for \@INC'`;
	chomp($_) for @default_inc;

	my @add_inc;
	for my $path (@INC) {
		next if ref $path;
		if ( !grep { $_ eq $path } @default_inc ) {
			push @add_inc, $path;
		}
	}
	@PERL = ( $^X, map { "-Mlib=$_" } @add_inc );
} ## end BEGIN

sub NOLIB {
	delete $ENV{PERL5LIB};
	delete $ENV{PERL5OPT};
}

1;

__END__

=head1 AUTHOR

Sam Vilain, <samv@cpan.org>.

=head1 LICENSE

Copyright (c) 2008, Catalyst IT (NZ) Ltd.  This program is free
software; you may use it and/or redistribute it under the same terms
as Perl itself.

=head1 CHANGELOG

For the complete history,

  git clone git://utsl.gen.nz/Perl-Command

=head1 BUGS / SUBMISSIONS

If you find an error, please submit the failure as an addition to the
test suite, as a patch.  Version control is at:

 git://utsl.gen.nz/Perl-Command

See the file F<SubmittingPatches> in the distribution for a basic
command sequence you can use for this.  Feel free to also harass me
via L<https://rt.cpan.org/Ticket/Create.html?Queue=Perl%3A%3ACommand>
or mail me something other than a patch, but you win points for just
submitting a patch in `git-format-patch` format that I can easily
apply and work on next time.

To take that to its logical extension, you can expect well written
patch series which include test cases and clearly described
progressive changes to spur me to release a new version of the module
with your great new feature in it.  Because I hopefully didn't have to
do any coding for that, just review.

=cut

