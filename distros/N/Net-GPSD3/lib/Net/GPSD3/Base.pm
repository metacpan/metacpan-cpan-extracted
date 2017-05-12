package Net::GPSD3::Base;
use strict;
use warnings;

our $VERSION='0.12';

=head1 NAME

Net::GPSD3::Base - Net::GPSD3 base object

=head1 SYNOPSIS

  use base qw{Net::GPSD3::Base};

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my $self=shift;
  %$self=@_;
}

=head1 BUGS

Log on RT and Send to gpsd-dev email list

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

Try gpsd-dev email list

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>michaelrdavis,tld=>com,account=>perl
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Net::GPSD3>

=cut

1;
