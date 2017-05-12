package Module::Install::Contributors;

use 5.006;
use strict;
use warnings;

BEGIN {
	$Module::Install::Contributors::AUTHORITY = 'cpan:TOBYINK';
	$Module::Install::Contributors::VERSION   = '0.001';
}

use base qw(Module::Install::Base);

sub contributors
{
	my $self = shift;
	push @{ $self->Meta->{values}{x_contributors} ||= [] }, @_;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Module::Install::Contributors - add an "x_contributors" section to your META.yml

=head1 SYNOPSIS

In your Makefile.PL:

 contributors "Alan Smithee", "Nicolas Bourbaki <nic@math.example.fr>";
 contributors "Spartacus <spartacus@example.it>";

=head1 DESCRIPTION

This is a plugin for L<Module::Install>. It adds a C<< x_contributors >>
section to your META.yml file. This is an array of strings, which should
normally be in C<< "Name <email>" >> format.

It provides one function to Module::Install-based Makefile.PLs:

=over

=item C<< contributors(@names) >>

=back

Repeated calls are cumulative. The example in the SYNOPSIS has three
contributors, not just Spartacus.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Module-Install-Contributors>.

=head1 SEE ALSO

L<Pod::Weaver::Section::Contributors>,
L<Dist::Zilla::Plugin::ContributorsFromGit>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

