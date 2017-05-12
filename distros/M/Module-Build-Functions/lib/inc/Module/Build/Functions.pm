package inc::Module::Build::Functions;

# <ShamelessPlagiat source="Module::Install">

# This module ONLY loads if the user has manually installed their own
# installation of Module::Build::Functions, and are some form of MI author.
#
# It runs from the installed location, and is never bundled
# along with the other bundled modules.
#
# So because the version of this differs from the version that will
# be bundled almost every time, it doesn't have it's own version and
# isn't part of the synchronisation-checking.

# The load order for Module::Build::Functions is a bit magic.
# It goes something like this...
#
# IF ( host has Module::Build::Functions installed, creating author mode ) {
#     1. Build.PL calls "use inc::Module::Build::Functions"
#     2. $INC{inc/Module/Install.pm} set to installed version of inc::Module::Build::Functions
#     3. The installed version of inc::Module::Build::Functions loads
#     4. inc::Module::Build::Functions calls "require Module::Build::Functions"
#     5. The ./inc/ version of Module::Build::Functions loads
# } ELSE {
#     1. Build.PL calls "use inc::Module::Build::Functions"
#     2. $INC{inc/Module/Install.pm} set to ./inc/ version of Module::Build::Functions
#     3. The ./inc/ version of Module::Build::Functions loads
# }


use strict;
use vars qw{$VERSION};
BEGIN {
	# While this version will be overwritten when Module::Build::Functions
	# loads, it remains so Module::Build::Functions itself can detect which
	# version an author currently has installed.
	# This allows it to implement any back-compatibility features
	# it may want or need to.
	$VERSION = '0.04';
}

if ( -d './inc' ) {
	my $author = $^O eq 'VMS' ? './inc/_author' : './inc/.author';
	if ( -d $author ) {
		$Module::Build::Functions::AUTHOR = 1;
		require File::Path;
		File::Path::rmtree('inc');
	}
} else {
	$Module::Build::Functions::AUTHOR = 1;
}

unshift @INC, 'inc' unless $INC[0] eq 'inc';
require Module::Build::Functions;

1;

# </ShamelessPlagiat>

__END__

=pod

=head1 NAME

inc::Module::Build::Functions - Module::Build::Functions configuration system

=head1 SYNOPSIS

  use inc::Module::Build::Functions;

=head1 DESCRIPTION

This module first checks whether the F<inc/.author> directory exists,
and removes the whole F<inc/> directory if it does, so the module author
always get a fresh F<inc> every time they run F<Makefile.PL>.  Next, it
unshifts C<inc> into C<@INC>, then loads B<Module::Build::Functions> from there.

Below is an explanation of the reason for using a I<loader module>:

The original implementation of B<CPAN::MakeMaker> introduces subtle
problems for distributions ending with C<CPAN> (e.g. B<CPAN.pm>,
B<WAIT::Format::CPAN>), because its placement in F<./CPAN/> duplicates
the real libraries that will get installed; also, the directory name
F<./CPAN/> may confuse users.

On the other hand, putting included, for-build-time-only libraries in
F<./inc/> is a normal practice, and there is little chance that a
CPAN distribution will be called C<Something::inc>, so it's much safer
to use.

Also, it allows for other helper modules like B<Module::AutoInstall>
to reside also in F<inc/>, and to make use of them.

=head1 AUTHORS

Audrey Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003, 2004 Audrey Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
