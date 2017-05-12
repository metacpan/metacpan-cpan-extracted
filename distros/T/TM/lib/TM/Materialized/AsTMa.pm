package TM::Materialized::AsTMa;

use TM::Materialized::Stream;
use base qw (TM::Materialized::Stream);

use Class::Trait qw(TM::Serializable::AsTMa);
use Data::Dumper;

=pod

=head1 NAME

TM::Materialized::AsTMa - Topic Maps, Parsing of AsTMa instances.

=head1 SYNOPSIS

  use TM::Materialized::AsTMa;
  my $tm = new TM::Materialized::AsTMa (inline => '....astma code here...');
  $tm->sync_in;
  # ...

  # or
  my $tm = new TM::Materialized::AsTMa (file => 'test.atm');
  # ...
  $tm->sync_in;

=head1 DESCRIPTION

This package provides parsing functionality for AsTMa= instances. AsTMa= is a textual shorthand
notation for Topic Map authoring. Currently, AsTMa= 1.3 and the (experimental) AsTMa= 2.0 is
supported. See L<TM::Serializable::AsTMa> for details.

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

Copyright 200[1-6], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.18';
our $REVISION = '$Id: AsTMa.pm,v 1.19 2006/11/23 10:02:55 rho Exp $';

1;

__END__
