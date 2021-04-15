package See;
######################################################################
#
# See - Debug See
#
# https://metacpan.org/release/See
#
# Copyright (c) 2021 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.01';
$VERSION = $VERSION;

BEGIN { pop @INC if $INC[-1] eq '.' } # CVE-2016-1238: Important unsafe module load path flaw
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 } use warnings; local $^W=1;

use vars qw( $seen );
BEGIN {
    if (defined($ENV{'PERL_DEBUG_SEE'}) and $ENV{'PERL_DEBUG_SEE'}) {
        $seen = \do { local *_ } if $] < 5.006;
        my($year,$month,$day,$hour,$min,$sec) = (localtime)[5,4,3,2,1,0];
        open $seen, sprintf(">seen-%04d%02d%02d-%02d%02d%02d-$$.log", 1900+$year, $month+1, $day, $hour, $min, $sec);
    }
}

END {
    if (defined($ENV{'PERL_DEBUG_SEE'}) and $ENV{'PERL_DEBUG_SEE'}) {
        close $seen;
    }
}

use vars qw( %script );
sub See::see ($) {
    if (defined($ENV{'PERL_DEBUG_SEE'}) and $ENV{'PERL_DEBUG_SEE'}) {
        my $got = $_[0] || '';
        my($package, $filename, $line) = caller;
        if (not defined $script{$filename}) {
            my $fh = \do { local *_ } if $] < 5.006;
            if (open $fh, $filename) {
                push @{$script{$filename}}, undef;
                while (<$fh>) {
                    chomp;
                    s/\A \s+ //x;
                    push @{$script{$filename}}, $_;
                }
                close $fh;
            }
        }
        print {$seen} qq{got($got) by $script{$filename}[$line] at $filename($line)\n};
    }
    return $_[0];
}

sub See::notsee ($) {
    return $_[0];
}

sub import {
    no strict 'refs';
    *{caller().'::see'} = \&See::see;
}

sub unimport {
    no strict 'refs';
    *{caller().'::see'} = \&See::notsee;
}

1;

__END__

=pod

=head1 NAME

See - Debug See

=head1 SYNOPSIS

  $ set PERL_DEBUG_SEE=1
  
  use See;
  if (see foo($bar)) {
  }
  
  no See;
  if (see foo($bar)) {
  }
  
  $ set PERL_DEBUG_SEE=

=head1 INSTALLATION BY MAKE

To install this software by make, type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 INSTALLATION WITHOUT MAKE (for DOS-like system)

To install this software without make, type the following:

   pmake.bat test
   pmake.bat install

=head1 DEPENDENCIES

  This mb.pm modulino requires perl5.00503 or later to use. Also requires 'strict'
  module. It requires the 'warnings' module, too if perl 5.6 or later.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See the LICENSE
file for details.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
