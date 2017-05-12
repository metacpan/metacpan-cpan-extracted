package Module::Install::TrustMetaYml;

use 5.005;
use strict;

BEGIN {
	$Module::Install::TrustMetaYml::AUTHORITY = 'cpan:TOBYINK';
	$Module::Install::TrustMetaYml::VERSION   = '0.003';
}

use base qw(Module::Install::Base);

sub trust_meta_yml
{
	my ($self, $where) = @_;
	$where ||= 'META.yml';

	$self->perl_version('5.005') unless defined $self->perl_version;
	
	$self->include('YAML::Tiny', 0);
	return $self if $self->is_admin;

	require YAML::Tiny;
	my $data = YAML::Tiny::LoadFile($where);

	$self->perl_version($data->{requires}{perl} || '5.005');
	
	KEY: foreach my $key (qw(requires recommends build_requires))
	{
		next KEY unless ref $data->{$key} eq 'HASH';
		my %deps = %{$data->{$key}};
		DEP: while (my ($pkg, $ver) = each %deps)
		{
			next if $pkg eq 'perl';
			$self->$key($pkg, $ver);
		}
	}
	
	return $self;
}

*trust_meta_yaml = \&trust_meta_yml;

1;

__END__

=encoding utf8

=head1 NAME

Module::Install::TrustMetaYml - trusts META.yml list of dependencies

=head1 SYNOPSIS

In Makefile.PL:

	trust_meta_yml;

=head1 DESCRIPTION

CPAN doesn't trust C<META.yml>'s list of dependencies for a module. Instead it
expects C<Makefile.PL> run on the computer the package is being installed
upon to generate its own list of dependencies (called C<MYMETA.yml> or
C<MYMETA.json>).

This module is a Module::Install plugin that generates C<MYMETA.yml> by simply
passing through the dependencies from C<META.yml>.

It does nothing when run from the module author's development copy.

The module defines two functions which are aliases for each other:

=over

=item C<trust_meta_yml>

=item C<trust_meta_yaml>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Module-Install-TrustMetaYml>.

=head1 SEE ALSO

L<Module::Install>, L<Module::Package::RDF>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 CREDITS

Thanks to Chris Williams (BINGOS), Ingy döt Net (INGY) and Florian Ragwitz (FLORA)
for explaining the role of C<MYMETA.json>, and helping me figure out why mine
weren't working.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

