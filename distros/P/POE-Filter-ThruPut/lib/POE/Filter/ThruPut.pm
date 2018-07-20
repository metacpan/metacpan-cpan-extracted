package POE::Filter::ThruPut;
$POE::Filter::ThruPut::VERSION = '1.00';
#ABSTRACT: a POE filter that passes data through unchanged whilst counting bytes sent and received

use strict;
use POE::Filter;
require bytes;

our @ISA = qw(POE::Filter);

sub new {
  my $type = shift;
  my $self = bless { buffer => '', in => 0, out => 0 }, $type;
  $self;
}

sub clone {
  my $self = shift;
  my $clone = bless { buffer => '', in => 0, out => 0 }, ref $self;
}

sub get_one_start {
  my ($self, $stream) = @_;
  my $dat = join '', @$stream;
  $self->{in} += bytes::length $dat;
  $self->{buffer} .= $dat;
}

sub get_one {
  my $self = shift;
  return [ ] unless CORE::length($self->{buffer});
  my $chunk = $self->{buffer};
  $self->{buffer}  = '';
  return [ $chunk ];
}

sub put {
  my ($self, $chunks) = @_;
  $self->{out} += bytes::length(join '', @$chunks);
  [ @$chunks ];
}

sub get_pending {
  my $self = shift;
  return undef if !CORE::length($self->{buffer});
  $self->{in} += bytes::length($self->{buffer});
  return [ $self->{buffer} ];
}

sub send {
  my $self = shift;
  return $self->{out};
}

sub recv {
  my $self = shift;
  return $self->{in};
}

sub stats {
  my $self = shift;
  return [ $self->{out}, $self->{in} ];
}

'Are you receiving?';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Filter::ThruPut - a POE filter that passes data through unchanged whilst counting bytes sent and received

=head1 VERSION

version 1.00

=head1 DESCRIPTION

POE::Filter::ThruPut passes data through without changing it, but counts the bytes sent and received.
It follows POE::Filter's API and can be used with L<POE::Filter::Stackable>.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::ThruPut object.

=back

=head1 METHODS

=over

=item C<get_one_start>

=item C<get_one>

=item C<get_pending>

=item C<get>

=item C<put>

All the above are standard L<POE::Filter> methods. They pass data through unchanged.

=item C<send>

Returns the number of bytes sent through the filter

=item C<recv>

Returns the numbers of bytes received through the filter

=item C<stats>

Returns an C<ARRAYREF> of the number of bytes sent and received, respectively.

=back

=head1 SEE ALSO

L<POE::Filter> for more information about filters in general.

This module was based on L<POE::Filter::Stream>.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Chris Williams and Rocco Caputo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
