package TM::Materialized::CTM;

use TM::Materialized::Stream;
use base qw (TM::Materialized::Stream);

use Class::Trait qw(TM::Serializable::CTM);
use Data::Dumper;

=pod

=head1 NAME

TM::Materialized::CTM - Topic Maps, Parsing of CTM instances.

=head1 SYNOPSIS

  use TM::Materialized::CTM;
  my $tm = new TM::Materialized::CTM (inline => '....CTM code here...');
  $tm->sync_in;
  # ...

  # or
  my $tm = new TM::Materialized::CTM (file => 'test.ctm');
  # ...
  $tm->sync;

=head1 DESCRIPTION

This package provides parsing functionality for CTM instances. CTM is a textual shorthand
notation for Topic Map authoring. See L<TM::Serializable::CTM> for details.

B<NOTE>: This is EXPERIMENTAL.

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

L<TM>, L<TM::Materialized::Stream>, L<TM::Serializable::CTM>

=head1 AUTHOR INFORMATION

Copyright 200[8], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.1';
our $REVISION = '$Id$';

1;

__END__
