package TM::Materialized::Stream;

use TM;
use base qw(TM);

=pod

=head1 NAME

TM::Materialized::Stream - Topic Maps, abstract class for maps with stream based input/output drivers

=head1 SYNOPSIS

  # this class will never be directly used for instantiation
  # see the description in TM and individual low-level drivers (AsTMa, ...)

=head1 DESCRIPTION

This class is a subclass of L<TM>, so it implements map objects. It is abstract, though, as it only
defined how a stream-based driver package should behave. It may thus be inherited by classes which
implement external formats (L<TM::Materialized::AsTMa>, L<TM::Materialized::XML>, ....).

=head1 INTERFACE

=head2 Constructor

The constructor of implementations should expect a hash as parameter containing the field(s) from
L<TM> and one or more of the following:

=over

=item I<url>:

If given, then the instance will be read from this url whenever synced in.

=item I<file>:

If given, then the data will be read/written from/to this file. This is just a convenience as it
will be mapped to I<url>.

=item I<inline>:

If given, then the instance will be read directly from this text provided inline when synced.

=back

If several fields (C<file>, C<url>, C<inline>) are specified, it is undefined which one will be
taken.

Examples (using AsTMa):

   # opening from an AsTMa= file
   $atm = new TM::Materialized::AsTMa (file   => 'here.atm');

   # why need a file? files are evil, anyway
   $atm = new TM::Materialized::AsTMa (inline => '# this is AsTMa');

=cut

sub new {
  my $class   = shift;
  my %options = @_;

  my $url   = 'inline:'.delete $options{inline} if $options{inline};
     $url   = 'file:'.  delete $options{file}   if $options{file};
     $url   =           delete $options{url}    if $options{url};
     $url ||= 'null:'; # default

  return bless $class->SUPER::new (%options, url => $url), $class;
}

=pod

=head1 SEE ALSO

L<TM>

=head1 AUTHOR INFORMATION

Copyright 200[2-6], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION = 0.10;
our $REVISION = '$Id: Stream.pm,v 1.2 2006/11/13 08:02:34 rho Exp $';

1;

__END__
