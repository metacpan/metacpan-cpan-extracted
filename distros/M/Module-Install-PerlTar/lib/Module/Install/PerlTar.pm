package Module::Install::PerlTar;

use 5.006001;
use strict;
use warnings;
use Module::Install::Base ();

our @ISA     = qw(Module::Install::Base);
our $VERSION = '1.001';
$VERSION =~ s/_//ms;

sub use_ptar {
	my $self = shift;

	return if not $Module::Install::AUTHOR;

	eval { require Archive::Tar; 1; } or warn "Cannot find Archive::Tar\n";
	eval { require IO::Compress::Gzip; 1; }
	  or warn "Cannot find IO::Compress::Gzip\n";

	my %args = (
		TAR      => 'ptar',
		TARFLAGS => '-c -C -f',
		COMPRESS =>
q{perl -MIO::Compress::Gzip=gzip,:constants -e"my $$in = $$ARGV[0]; gzip($$in => qq($$in.gz), q(Level) => Z_BEST_COMPRESSION, q(BinModeIn) => 1) or die q(gzip failed); unlink $$in;"},
	);

	$self->makemaker_args( dist => \%args );

	return 1;
} ## end sub use_ptar

1;
__END__

=encoding utf-8

=head1 NAME

Module::Install::PerlTar - Removes the requirement for a tar executable.

=head1 SYNOPSIS

  # in Makefile.PL
  use inc::Module::Install;
  use_ptar;

=head1 DESCRIPTION

Module::Install::DistArchiveTar is a Module::Install plugin to
set the options that allow the use of the 'ptar' script
when running 'make dist'.

This way, there is no reliance on any binaries external to Perl.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Module::Install|Module::Install>

=cut
