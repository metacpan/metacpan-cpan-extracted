package TM::Materialized::XTM;

use strict;
use warnings;

use TM::Materialized::Stream;
use base qw (TM::Materialized::Stream);

use Class::Trait qw(TM::Serializable::XTM);
use Data::Dumper;

=pod

=head1 NAME

TM::Materialized::XTM - Topic Maps, Parsing and dumping of XTM instances.

=head1 SYNOPSIS

  use TM::Materialized::XTM;
  my $tm = new TM::Materialized::XTM (inline => '....xtm here...');
  $tm->sync_in;
  # ...

  # or
  my $tm = new TM::Materialized::XTM (file => 'test.xtm');
  # ...
  $tm->sync;

  # or
  my $tm  = ... however you arrive at a map
  my $xml = $tm->sync_out;

=head1 DESCRIPTION

This package provides parsing and dumping functionality for XTM 1.0 instances.
See L<TM::Serializable::XTM> for details.

=head1 INTERFACE

=head2 Constructor

The constructor expects a hash as described in L<TM::Materialized::Stream>.

=cut

sub new {
    my $class   = shift;
    my %options = @_;
    $options{psis} = $TM::PSI::topicmaps; # make sure we have what we need
    return bless $class->SUPER::new (%options), $class;
}

=pod

=head1 SEE ALSO

L<TM>, L<TM::Materialized::Stream>

=head1 AUTHOR INFORMATION

Copyright 200[1-68], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION = 0.02;

1;
