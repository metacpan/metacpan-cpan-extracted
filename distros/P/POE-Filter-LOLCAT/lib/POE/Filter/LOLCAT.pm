package POE::Filter::LOLCAT;

use strict;
use warnings;
use Acme::LOLCAT ();
use base qw(POE::Filter);
use vars qw($VERSION);

$VERSION = '1.10';

sub new {
  my $class = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  $opts{BUFFER} = [];
  return bless \%opts, $class;
}

sub get_one_start {
  my ($self, $raw) = @_;
  push @{ $self->{BUFFER} }, $_ for @$raw;
}

sub get_one {
  my $self = shift;
  my $events = [];

  my $event = shift @{ $self->{BUFFER} };
  if ( defined $event ) {
    my $record = Acme::LOLCAT::translate($event);
    push @$events, $record if $record;
  }
  return $events;
}

sub get_pending {
  my $self = shift;
  return $self->{BUFFER};
}

sub put {
  return;
}

sub clone {
  my $self = shift;
  my $nself = { };
  $nself->{$_} = $self->{$_} for keys %{ $self };
  $nself->{BUFFER} = [ ];
  return bless $nself, ref $self;
}

1;
__END__

=head1 NAME

POE::Filter::LOLCAT - POE FILTR T SPEKK LIEK LOLCATZ. KTHNX!

=head1 SYNOPSIZ

  my $filter = POE::Filter::LOLCAT->new();

  $arrayref_of_logical_chunks =
    $filter->get($arrayref_of_raw_chunks_from_driver);

=head1 DESCRIPSHUN

POE::Filter::LOLCAT is a L<POE::Filter> for translating lines of text into "LOLCAT", using the 
excellent L<Acme::LOLCAT>. KTHNX!

It is intended to be used in a stackable filter, L<POE::Filter::Stackable>, with L<POE::Filter::Line>.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::LOLCAT object.

=back

=head1 METHODZ

=over

=item C<get>

=item C<get_one_start>

=item C<get_one>

TAKEZ AN ARRAYREF WHICH AR TEH CONTAINZ LINEZ OF TEXT, RETURNZ AN ARRAYREF OV LOLCAT TRANSLATED TEXT. KTHX.

=item C<get_pending>

RETURNZ TEH FILTRZ PARTIAL INPUT BUFFR

=item C<put>

TEH PUT METHOD AR TEH NOT IMPLEMENTED. KTHNX!

=item C<clone>

MAKEZ COPY OV TEH FILTR, AND CLEARZ TEH COPYZ BUFFR.  KTHX.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright E<copy> 2008 Chris Williams

THIZ MODULE MAY BE USED, MODIFIED, AND DISTRIBUTED UNDR TEH SAME TERMZ AZ PERL ITSELF. PLEEZ SEE TEH LICENSE THAT CAME WITH YORE PERL DISTRIBUSHUN FOR DETAILZ. KTHX.

=head1 SEE ALSO

L<Acme::LOLCAT>

L<POE::Filter::Stackable>

L<POE::Filter::Line>

=cut
