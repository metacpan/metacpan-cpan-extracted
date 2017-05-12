package Module::Install::DOAP;

use 5.008;
use base qw(Module::Install::Base);
use strict;

our $VERSION = '0.006';
our $AUTHOR_ONLY = 1;

sub doap_metadata
{
	my $self = shift;
	$self->admin->doap_metadata(@_) if $self->is_admin;
}

1;

__END__
=head1 NAME

Module::Install::DOAP - generate META.yml data from DOAP

=head1 SYNOPSIS

In Makefile.PL:

  rdf_metadata;
  doap_metadata;
  
=head1 DESCRIPTION

This Module::Install plugin generates your META.yml file from RDF data
(especially DOAP) in your distribution's 'meta' directory.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<Module::Install>, L<Module::Install::DOAPChangeSets> .

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
