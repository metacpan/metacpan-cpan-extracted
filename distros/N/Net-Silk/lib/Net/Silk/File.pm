# Use of the Net-Silk library and related source code is subject to the
# terms of the following licenses:
# 
# GNU Public License (GPL) Rights pursuant to Version 2, June 1991
# Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
# 
# NO WARRANTY
# 
# ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER 
# PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY 
# PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN 
# "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY 
# KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT 
# LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE, 
# MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE 
# OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT, 
# SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY 
# TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF 
# WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES. 
# LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF 
# CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON 
# CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE 
# DELIVERABLES UNDER THIS LICENSE.
# 
# Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie 
# Mellon University, its trustees, officers, employees, and agents from 
# all claims or demands made against them (and any related losses, 
# expenses, or attorney's fees) arising out of, or relating to Licensee's 
# and/or its sub licensees' negligent use or willful misuse of or 
# negligent conduct or willful misconduct regarding the Software, 
# facilities, or other rights or assistance granted by Carnegie Mellon 
# University under this License, including, but not limited to, any 
# claims of product liability, personal injury, death, damage to 
# property, or violation of any laws or regulations.
# 
# Carnegie Mellon University Software Engineering Institute authored 
# documents are sponsored by the U.S. Department of Defense under 
# Contract FA8721-05-C-0003. Carnegie Mellon University retains 
# copyrights in all material produced under this contract. The U.S. 
# Government retains a non-exclusive, royalty-free license to publish or 
# reproduce these documents, or allow others to do so, for U.S. 
# Government purposes only pursuant to the copyright license under the 
# contract clause at 252.227.7013.

package Net::Silk::File;

use strict;
use warnings;
use Carp;

use overload
  '<>'     => \&read,
  fallback => 1;

use Net::Silk qw( :basic );

use Scalar::Util qw( looks_like_number );
use Symbol;

use constant SILK_FILE_IO_CLASS => 'Net::Silk::File::io_xs';

my %Mode = (
  '<'  => SILK_FILE_IO_CLASS->SK_IO_READ,
  '>'  => SILK_FILE_IO_CLASS->SK_IO_WRITE,
  '>>' => SILK_FILE_IO_CLASS->SK_IO_APPEND,
);

my %Policy = (
  ignore => SILK_FILE_IO_CLASS->SK_IPV6POLICY_IGNORE,
  asv4   => SILK_FILE_IO_CLASS->SK_IPV6POLICY_ASV4,
  mix    => SILK_FILE_IO_CLASS->SK_IPV6POLICY_MIX,
  force  => SILK_FILE_IO_CLASS->SK_IPV6POLICY_FORCE,
  only   => SILK_FILE_IO_CLASS->SK_IPV6POLICY_ONLY,
);

my %Compression = (
  default => SILK_FILE_IO_CLASS->SK_COMPMETHOD_DEFAULT,
  best    => SILK_FILE_IO_CLASS->SK_COMPMETHOD_BEST,
  none    => SILK_FILE_IO_CLASS->SK_COMPMETHOD_NONE,
  zlib    => SILK_FILE_IO_CLASS->SK_COMPMETHOD_ZLIB,
  lzo1x   => SILK_FILE_IO_CLASS->SK_COMPMETHOD_LZO1X,
);

sub open {
  my $self = shift;
  $self = $self->new unless ref $self;
  my($filename, $mode);
  $filename = shift;
  if (@_ % 2) {
    $mode = shift;
  }
  else {
    $mode = '<';
  }
  my %opt = @_;
  croak("unknown file mode '$mode'") unless exists $Mode{$mode};
  $mode = $Mode{$mode};
  *$self->{io} = SILK_FILE_IO_CLASS->init_open($filename, $mode);
  my $fd = delete $opt{file_des};
  while (my($k, $v) = each %opt) {
    if ($k eq 'policy') {
      croak("unknown policy '$k'") unless exists $Policy{$v};
      $self->io->init_policy($Policy{$v});
    }
    elsif ($k eq 'compression') {
      $v = 'none' unless defined $v;
      croak("unknown compression '$k'") unless exists $Compression{$v};
      $self->io->init_compression($Compression{$v});
    }
    #elsif ($k eq 'format') {
    #  $self->io->init_format($v);
    #}
    elsif ($k eq 'notes') {
      for my $anno (@$v) {
        $self->io->init_add_annotation($anno);
      }
    }
    elsif ($k eq 'invocations') {
      for my $invoc (@$v) {
        $self->io->init_add_invocation($invoc);
      }
    }
    else {
      croak("unknown option '$k'");
    }
  }
  my @arg;
  push(@arg, $fd) if defined $fd;
  $self->io->init_finalize(@arg);
  $self;
}

sub open_fh {
  my $self = shift;
  my $fh = shift;
  my $mode;
  if (@_ % 2) {
    $mode = shift;
  }
  else {
    $mode = '<';
  }
  my $fileno = fileno($fh);
  $fileno = $fh unless defined $fileno;
  looks_like_number($fileno) or croak "invalid file descriptor '$fileno'";
  my %opt = @_;
  my $filename = delete $opt{filename};
  $filename = "<fileno($fileno)>" unless defined $filename;
  $opt{file_des} = $fileno;
  $self->open($filename, $mode, %opt);
}

sub close { shift->io->close }

sub new {
  my $class = shift;
  $class = ref $class || $class;
  my $self = Symbol::gensym();
  bless $self, $class;
  *$self->{io} = undef;
  $self->open(@_) if @_;
  $self;
}

sub io { *{shift()}->{io} }

sub name { shift->io->name }

sub invocations {
  my $self = shift;
  my @invo = $self->io->invocations;
  wantarray ? @invo : \@invo;
}

sub notes {
  my $self = shift;
  my @notes = $self->io->notes;
  wantarray ? @notes : \@notes;
}

sub iter {
  my $io = shift->io;
  sub {
    while ($_ = $io->read) {
      return $_;
    }
  };
}

sub read {
  my $io = $_[0]->io;
  if (wantarray) {
    my @recs;
    while (my $r = $io->read) {
      push(@recs, $r);
    }
    return @recs;
  }
  $_ = $io->read;
}

sub write {
  my $io = shift->io;
  for my $r (@_) {
    $io->write($r);
  }
}

###

1;

__END__


=head1 NAME

Net::Silk::File - SiLK flow file interface

=head1 SYNOPSIS

  use Net::Silk::File;
  use Net::Silk::IPSet;

  my $rwfile = Net::Silk::File->open('<', 'flow_file');
  my $sip_set = Net::Silk::IPSet->new;
  while (<$rwfile>) {
    $sip_set->add($_->sip);
  }

  ###

  open(my $fh, "rwfilter --start-date=2015/01/16 " .
                         "--end-date=2015/01/16  " .
                         "--type=inweb " .
                         "--all-destination=stdout |") or die "oops: $!";

  my $rwf = Net::Silk::File->open_fh($fh);
  while (<$rwf>) {
    ...
  }

=head1 DESCRIPTION

C<Net::Silk::File> is an IO class for writing to or reading from
SiLK flow files.

=head1 METHODS

=over

=item open($mode, $filename, %opt)

=item open($spec, %opt)

Opens a file using the given mode and returns a C<Net::Silk::File> object.
Mode can be '<' for read, '>' for write, or '>>' for append. In the second
form, the mode can be part of the filename strings, e.g. ">filename",
similar to the native perl C<open()> function.

The following optional keyword arguments are accepted:

=over

=item compression

Specifies the type of compression to use in write mode. Valid
compression modes are:

  default
  best
  none
  zlib
  lzo1x

=item policy

Specifies how to handle IPv6 records in the file. Valid policy
options are:

  ignore
  asv4
  mix
  force
  only

=item notes

Array of annotation strings to add to the file header when writing
to a file.

=item invocations

Array of invocation strings to add to the file header when writing
to a file.

=back

=item open_fh($fileno, $mode, %opt)

=item open_fh($fileno, %opt)

Open a file handle or file descriptor in the given mode ('<', '>', or
'>>'). If no mode is given, then '<' is assumed. Keyword options are the
same as with C<open()>, with the addition of an optional 'filename'
parameter if there is a filename associated with the descriptor.

=item close()

Close the flow file.

=item name()

Return the filename of the opened file.

=item notes()

Return a list of annotations present in the file header.

=item invocations()

Return a list of invocations present in the file header.

=item read()

Return the next L<Net::Silk::RWRec> from the file. This will
slurp the whole file if invoked in array context.

=item write($rwrec)

Write a L<Net::Silk::RWRec> to the file.

=back

=head1 IO OPERATION

The C<Net::Silk::File> object references are IO handles and work
with the C<E<lt>E<gt>> operator. The following are equivalent:

  while (my $r = $f->read()) {
    ...
  }

  while (my $r = <$f>) {
    ...
  }

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
