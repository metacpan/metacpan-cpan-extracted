package PITA::Test::Dummy::Perl5::XS;
use strict;
use vars qw($VERSION @ISA);

BEGIN {
  $VERSION = "0.01";
  @ISA = qw(Exporter);
  
  eval {
    require XSLoader;
    XSLoader::load('PITA::Test::Dummy::Perl5::XS', $VERSION);
    1;
  } or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    bootstrap PITA::Test::Dummy::Perl5::XS $VERSION;
  };
}

1;

__END__

=head1 NAME

PITA::Test::Dummy::Perl5::XS - CPAN XS test dummy

=head1 SYNOPSIS

  use PITA::Test::Dummy::Perl5::XS;

  my $dummy = PITA::Test::Dummy::Perl5::XS->dummy;

=head1 DESCRIPTION

This module is part of the Perl Image Testing Architecture (PITA) and
acts as a test module for the L<PITA::Scheme::Perl5::Make> testing
scheme.

1. Contains no functionality, and will never do so.

2. Has no non-core depencies, and will never have any.

3. Exists on CPAN.

=head1 METHODS

=over

=item dummy

Returns the dummy's name, George in this case

=back

=head1 SEE ALSO

L<PITA>, L<PITA::Scheme::Perl5::Make>, L<http://ali.as/pita/>

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=cut


  
