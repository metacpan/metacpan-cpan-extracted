package TM::Materialized::LTM;

use TM::Materialized::Stream;
use base qw (TM::Materialized::Stream);

use Class::Trait 'TM::Serializable::LTM';

use Data::Dumper;

=pod

=head1 NAME

TM::Materialized::LTM - Topic Maps, Parsing of LTM instances.

=head1 SYNOPSIS

  # reading a topic map description from a file/url
  use TM::Materialized::LTM
  $tm = new TM::Materialized::LTM (file => 'mymap.ltm');
  $tm->sync_in();

=head1 DESCRIPTION

This package provides parsing functionality for LTM instances. Please see L<TM::Serializable::LTM>
for details how well LTM is supported.

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

L<TM>

=head1 AUTHOR INFORMATION

Copyright 200[1-6], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.3';
our $REVISION = '$Id: LTM.pm,v 1.7 2006/12/29 09:33:42 rho Exp $';

1;

__END__
