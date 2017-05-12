package PPI::XS::Tokenizer;

use 5.006002;
use strict;
use warnings;

our $VERSION = '0.03';
BEGIN {
  no warnings 'once';
  $PPI::Lexer::X_TOKENIZER = "PPI::XS::Tokenizer";
}
sub PPI::Tokenizer::__dummy_func_do_not_use { 5 }
our @ISA = qw{PPI::Tokenizer};

use Carp ();
use Params::Util    qw{_INSTANCE _SCALAR0 _ARRAY0};

use PPI::XS::Tokenizer::Constants;

require XSLoader;
XSLoader::load('PPI::XS::Tokenizer', $VERSION);

sub new {
  my $class = ref($_[0]) || $_[0];

  my $self = {};

  if ( ! defined $_[1] ) {
    # We weren't given anything
    PPI::Exception->throw("No source provided to Tokenizer");

  } elsif ( ! ref $_[1] ) {
    my $source = PPI::Util::_slurp($_[1]);
    if ( ref $source ) {
      # Content returned by reference
      $self->{source} = $$source;
    } else {
      # Errors returned as a string
      return( $source );
    }

  } elsif ( _SCALAR0($_[1]) ) {
    $self->{source} = ${$_[1]};

  } elsif ( _ARRAY0($_[1]) ) {
    $self->{source} = join '', map { "\n" } @{$_[1]};

  } else {
    # We don't support whatever this is
    PPI::Exception->throw(ref($_[1]) . " is not supported as a source provider");
  }

  $self->{source_bytes} = length $self->{source};
  if ( $self->{source_bytes} ) {
    # Split on local newlines
    $self->{source} =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;
    $self->{source} = [ split /(?<=\n)/, $self->{source} ];

  } else {
    $self->{source} = [ ];
  }
  
  return $class->InternalNew($self->{source});
}


1;

__END__

=head1 NAME

PPI::XS::Tokenizer - C++ replaction for the PPI Tokenizer

=head1 SYNOPSIS

  use PPI::XS::Tokenizer;
  use PPI;

=head1 DESCRIPTION

This is a C++ port for the PPI Tokenizer, aimed to make it faster.
It build to be identical replacement, and as the are no user serviciable
parts in the original tokenizer, there are none here either.

This package is compatible with PPI version 1.213

The effort was seeded be the Padre - the Perl IDE project, mentored by
Adam Kennedy, the Perl-C++ binding was done by Steffen Mueller, and the
tokenizer itself was written by Shmuel Fomberg.

=head1 Benchmark

Code:

  timethis( 1000, sub { PPI::Document->new(".../lib/PPI/Node.pm") } );

Results:

  with PPI::XS::Tokenizer
  timethis 1000: 206 wallclock secs (203.29 usr +  0.67 sys = 203.96 CPU) @  4.90/s (n=1000)
  Pure perl:
  timethis 1000: 260 wallclock secs (257.66 usr +  0.28 sys = 257.94 CPU) @  3.88/s (n=1000)

=head1 SEE ALSO

=head1 AUTHOR

Shmuel Fomberg, E<lt>semuelf@cpan.orgE<gt>

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Shmuel Fomberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
