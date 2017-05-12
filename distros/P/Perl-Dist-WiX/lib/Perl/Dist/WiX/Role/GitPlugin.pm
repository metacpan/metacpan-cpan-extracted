package Perl::Dist::WiX::Role::GitPlugin;

=pod

=head1 NAME

Perl::Dist::WiX::Role::GitPlugin - Role for plugins that build from git checkouts.

=head1 VERSION

This document describes Perl::Dist::WiX::Role::GitPlugin version 1.500.

=head1 SYNOPSIS

	# Since this is a role, it is composed into classes that use it.
  
=head1 DESCRIPTION

B<Perl::Dist::WiX::Role::GitPlugin> is a role that provides an attribute 
that is common to all plugins that build Perl from git checkouts.

=cut

use 5.010;
use Moose::Role;
use English qw( -no_match_vars );

our $VERSION = '1.500';
$VERSION =~ s/_//sm;

=head1 METHODS

=head2 git_describe

The C<git_describe> method returns the output of C<git describe> on the
directory pointed to by L<git_checkout()|Perl::Dist::WiX/git_checkout>.

It is only executed once, and then the value is stored.

=cut

has 'git_describe' => (
	is       => 'ro',
	lazy     => 1,
	builder  => '_build_git_describe',
	init_arg => undef,
);

sub _build_git_describe {
	my $self     = shift;
	my $checkout = $self->git_checkout();
	my $location = $self->git_location();
	if ( not -f $location ) {
		PDWiX::File->throw(
			message => 'Could not find git',
			file    => $location
		);
	}
	$location = Win32::GetShortPathName($location);
	if ( not defined $location ) {
		PDWiX->throw( 'Could not convert the location of git.exe'
			  . ' to a path with short names' );
	}

	## no critic(ProhibitBacktickOperators)
	$self->trace_line( 2,
		"Finding current commit using $location describe\n" );
	my $describe =
qx{cmd.exe /d /e:on /c "pushd $checkout && $location describe && popd"};

	if ($CHILD_ERROR) {
		PDWiX->throw("'git describe' returned an error: $CHILD_ERROR");
	}

	$describe =~ s/v5[.]/5./ms;
	$describe =~ s/\n//ms;

	return $describe;
} ## end sub _build_git_describe


no Moose::Role;

1;

__END__

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<Perl::Dist::WiX::BuildPerl::PluginInterface|Perl::Dist::WiX::BuildPerl::PluginInterface>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
