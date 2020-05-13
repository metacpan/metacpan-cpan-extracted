#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Net::Prometheus::ProcessCollector;

use strict;
use warnings;

our $VERSION = '0.11';

use Net::Prometheus::Types qw( MetricSamples Sample );

=head1 NAME

C<Net::Prometheus::ProcessCollector> - obtain a process collector for the OS

=head1 SYNOPSIS

   use Net::Prometheus::ProcessCollector;

   my $collector = Net::Prometheus::ProcessCollector->new;

=head1 DESCRIPTION

This module-loading package provides a method that attempts to load a process
collector appropriate for the host OS it is running on.

The following OS-specific modules are provided with this distribution:

=over 2

=item *

L<Net::Prometheus::ProcessCollector::linux>

=back

Other OSes may be supported by 3rd-party CPAN modules by following this naming
pattern based on the value of the C<$^O> variable on the OS concerned.

=cut

=head1 MAGIC CONSTRUCTORS

=cut

=head2 new

   $collector = Net::Prometheus::ProcessCollector->new( %args )

Attempts to construct a new process collector for the OS named by C<$^O>,
passing in any extra arguments into the C<new> constructor for the specific
class.

If no perl module is found under the appropriate file name, C<undef> is
returned. If any other error occurs while loading or constructing the
instance, the exception is thrown as normal.

Typically a process exporter should support the following named arguments:

=over

=item prefix => STR

A prefix to prepend on all the exported variable names. If not provided, the
default should be C<"process">.

=item labels => ARRAY

Additional labels to set on exported variables. If not provided, no extra
labels will be set.

=back

=cut

sub new
{
   my $class = shift;
   $class->for_OS( $^O, @_ );
}

=head2 for_OS

   $collector = Net::Prometheus::ProcessCollector->for_OS( $os, @args )

Attempts to construct a new process collector for the named OS. Except under
especially-exceptional circumstances, you don't want to call this method.
Call L</new> instead.

=cut

sub for_OS
{
   shift; # class
   my ( $os, @args ) = @_;

   my $pkg = __PACKAGE__ . "::$os";

   ( my $file = "$pkg.pm" ) =~ s{::}{/}g;
   if( !eval { require $file } ) {
      return if $@ =~ m/^Can't locate \Q$file\E in \@INC/;
      die $@;
   }

   return $pkg->new( @args );
}

# Methods for subclasses

sub __new
{
   my $class = shift;
   my %args = @_;

   return bless {
      prefix => $args{prefix} || "process",
      labels => $args{labels} || [],
   }, $class;
}

sub _make_metric
{
   my $self = shift;
   my ( $varname, $value, $type, $help ) = @_;

   my $prefix = $self->{prefix};

   return MetricSamples( "${prefix}_$varname", $type, $help,
      [ Sample( "${prefix}_$varname", $self->{labels}, $value ) ] );
}

0x55AA;
