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

package Net::Nmsg::Input;

use strict;
use warnings;
use Carp;

use base qw( Net::Nmsg::Layer );

use overload
  '<>'     => \&read,
  fallback => 1;

use Net::Nmsg::Util qw( :io :vendor :result );
use Net::Nmsg::Msg;
use Net::Nmsg::Handle;

use constant HANDLE_IO => 'Net::Nmsg::Handle';
use constant INPUT_XS  => 'Net::Nmsg::XS::input';

my %Defaults = (

  # nmsg
  filter_vendor   => undef,
  filter_msgtype  => undef,
  filter_source   => undef,
  filter_operator => undef,
  filter_group    => undef,
  blocking_io     => 1,

  # socket
  rcvbuf => NMSG_DEFAULT_SO_RCVBUF,

  # pcap
  bpf      => undef,
  snaplen  => NMSG_DEFAULT_SNAPLEN,
  promisc  => 0,

);

sub _defaults { \%Defaults }

sub get_filter_msgtype  { shift->_get_xs_opt(filter_msgtype  => @_) }
sub get_filter_operator { shift->_get_xs_opt(filter_operator => @_) }
sub get_filter_source   { shift->_get_xs_opt(filter_source   => @_) }
sub get_filter_group    { shift->_get_xs_opt(filter_group    => @_) }
sub get_blocking_io     { shift->_get_xs_opt(blocking_io     => @_) }

sub set_filter_msgtype  { shift->_set_xs_opt(filter_msgtype  => @_) }
sub set_filter_operator { shift->_set_xs_opt(filter_operator => @_) }
sub set_filter_source   { shift->_set_xs_opt(filter_source   => @_) }
sub set_filter_group    { shift->_set_xs_opt(filter_group    => @_) }
sub set_blocking_io     { shift->_set_xs_opt(blocking_io     => @_) }

sub get_snaplen { shift->_get_io_opt(snaplen => @_) }
sub get_promisc { shift->_get_io_opt(promisc => @_) }
sub get_bpf     { shift->_get_io_opt(bpf     => @_) }

sub set_snaplen { shift->_set_io_opt(snaplen => @_) }
sub set_promisc { shift->_set_io_opt(promisc => @_) }
sub set_bpf     { shift->_set_io_opt(bpf     => @_) }

###

sub is_file  { (shift->_xs || return)->is_file  }
sub is_json  { (shift->_xs || return)->is_json  }
sub is_sock  { (shift->_xs || return)->is_sock  }
sub is_pres  { (shift->_xs || return)->is_pres  }
sub is_pcap  { (shift->_xs || return)->is_pcap  }
sub is_iface { (shift->_xs || return)->is_iface }

###

sub _map_opts {
  my $self = shift;
  my %opt  = @_;
  my $vendor  = delete $opt{filter_vendor};
  my $msgtype = delete $opt{filter_msgtype};
  if (defined $vendor || defined $msgtype) {
    $opt{filter_msgtype} = [$vendor, $msgtype];
  }
  %opt;
}

sub _init_input {
  my $self = shift;
  my($spec, $io, $xs, %opt) = @_;
  *$self->{_spec} = $spec;
  *$self->{_io}   = $io;
  *$self->{_xs}   = $xs;
  $self->_dup_io_r;
  $self->_init_opts(%opt);
  $self;
}

sub open {
  my $self = shift;
  my $spec = shift;
  if (@_ % 2 && $_[0] =~ /^\d+$/) {
    $spec = join('/', $spec, shift);
  }
  ($self, $spec, my($fatal, %opt)) = $self->_open_init($spec, @_);
  if (Net::Nmsg::Util::looks_like_socket($spec)) {
    #print STDERR "SOCKET $self\n";
    return $self->open_sock($spec, %opt)
      || ($fatal ? croak $self->error : return);
  }
  elsif (Net::Nmsg::Util::is_filehandle($spec)) {
    #print STDERR "FHND $self\n";
    return $self->open_file($spec, %opt)
      || ($fatal ? croak $self->error : return);
  }
  elsif (Net::Nmsg::Util::is_file($spec) || ($spec || '') =~ /\.\w+$/) {
    #print STDERR "FILE $self\n";
    if (($spec || '') =~ /\.w+$/ && ! -f $spec) {
      $fatal ? croak("file does not exist " . $spec) : return;
    }
    if (Net::Nmsg::Util::is_nmsg_file($spec) ||
        ($spec || '') =~ /\.nmsg$/) {
      #print STDERR "NMSG $self\n";
      return $self->open_file($spec, %opt)
        || ($fatal ? croak $self->error : return);
    }
    elsif (Net::Nmsg::Util::is_pcap_file($spec) ||
           ($spec || '') =~ /\.pcap$/) {
      #print STDERR "PCAP $self\n";
      return $self->open_pcap($spec, %opt)
        || ($fatal ? croak $self->error : return);
    }
    else {
      $self->error("unknown input file type $spec");
      croak $self->error if $fatal;
    }
  }
  elsif (Net::Nmsg::Util::is_interface($spec)) {
    #print STDERR "IFACE $self\n";
    return $self->open_iface($spec, %opt)
      || ($fatal ? croak $self->error : return);
  }
  else {
    #print STDERR "OOPS UNKNOWN $spec\n";
    $self->error("not sure what to do with spec $spec");
    croak $self->error if $fatal;
  }
  $self;
}

sub open_file {
  my($self, $spec, $fatal, %opt) = shift->_open_init(@_);
  my $io;
  eval { $io = $self->HANDLE_IO->open_input_file($spec, %opt) };
  $@ && $self->error($@) && ($fatal ? croak $@ : return);
  my $xs;
  eval { $xs = $self->INPUT_XS->open_file($io) };
  $@ && $self->error($@) && ($fatal ? croak $@ : return);
  $self->_init_input($spec, $io, $xs, %opt);
}

sub open_json {
  my($self, $spec, $fatal, %opt) = shift->_open_init(@_);
  my $io;
  eval { $io = $self->HANDLE_IO->open_input_file($spec, %opt) };
  $@ && $self->error($@) && ($fatal ? croak $@ : return);
  my $xs;
  eval { $xs = $self->INPUT_XS->open_json($io) };
  $@ && $self->error($@) && ($fatal ? croak $@ : return);
  $self->_init_input($spec, $io, $xs, %opt);
}

sub open_sock {
  my $self = shift;
  my $spec = @_ % 2 ? shift : join('/', splice(@_, 0, 2));
  ($self, $spec, my($fatal, %opt)) = $self->_open_init($spec, @_);
  if (! defined $spec) {
    $self->error("spec required");
    return unless $fatal;
    croak $self->error;
  }
  my $io;
  $io = $self->HANDLE_IO->open_input_sock($spec, %opt);
  my $xs = $self->INPUT_XS->open_sock($io);
  $self->_init_input($spec, $io, $xs, %opt);
  $self;
}

sub open_pres {
  my($self, $spec, $fatal, %opt) = shift->_open_init(@_);
  if (! $opt{filter_msgtype}) {
    $self->error("filter_vendor and filter_msgtype required");
    return unless $fatal;
    croak $self->error;
  }
  my $io;
  eval { $io = $self->HANDLE_IO->open_input_file($spec, %opt) };
  $@ && $self->error($@) && ($fatal ? croak $@ : return);
  my $xs;
  eval { $xs = $self->INPUT_XS->open_pres($io, @{$opt{filter_msgtype}}) };
  $@ && $self->error($@) && ($fatal ? croak $@ : return);
  $self->_init_input($spec, $io, $xs, %opt);
}

sub open_pcap {
  my($self, $spec, $fatal, %opt) = shift->_open_init(@_);
  if (! $opt{filter_msgtype}) {
    $self->error("filter_vendor and filter_msgtype required");
    return unless $fatal;
    croak $self->error;
  }
  my $io;
  eval { $io = $self->HANDLE_IO->open_input_pcap_file($spec, %opt) };
  $@ && $self->error($@) && ($fatal ? croak $@ : return);
  my $xs;
  eval { $xs = $self->INPUT_XS->open_pcap($io->_xs, @{$opt{filter_msgtype}}) };
  $@ && $self->error($@) && ($fatal ? croak $@ : return);
  $self->_init_input($spec, $io, $xs, %opt);
}

sub open_iface {
  my($self, $spec, $fatal, %opt) = shift->_open_init(@_);
  if (! $opt{filter_msgtype}) {
    $self->error("vendor and msgtype required");
    return unless $fatal;
    croak $self->error;
  }
  my $io;
  eval { $io = $self->HANDLE_IO->open_input_pcap_iface($spec, %opt) };
  $@ && $self->error($@) && ($fatal ? croak $@ : return);
  my $xs;
  eval { $xs = $self->INPUT_XS->open_pcap($io->_xs, @{$opt{filter_msgtype}}) };
  $@ && $self->error($@) && ($fatal ? croak $@ : return);
  $self->_init_input($spec, $io, $xs, %opt);
}

### nmsg input

sub loop {
  my $self = shift;
  my $res  = $self->_xs->loop(shift, shift || -1);
  $self->eof(1) if $res == NMSG_RES_EOF;
  $self;
}

### perl IO

sub blocking {
  my $self = shift;
  @_ ? $self->set_blocking_io(shift) : $self->get_blocking_io;
}

sub eof {
  my $self = shift;
  @_ ? $self->_set_opt(_eof => shift) : $self->_get_opt('_eof');
}

sub read {
  my $self = shift;
  my $xs = $self->_xs || return;
  if (wantarray) {
    my $io = $self->get_blocking_io;
    my @msgs;
    while (my $msg = $xs->read($io)) {
      push(@msgs, $msg);
    }
    $self->eof(1);
    return @msgs;
  }
  my $msg = $xs->read($self->get_blocking_io);
  return($_ = $msg) if $msg;
  $self->eof(1);
  return;
}

###

1;

__END__

=head1 NAME

Net::Nmsg::Input - Perl interface for nmsg inputs

=head1 SYNOPSIS

  use Net::Nmsg::Input;
  use Net::Nmsg::Output;

  my $in  = Net::Nmsg::Input->open('input.nmsg');
  my $out = Net::Nmsg::Output->open('output.nmsg');

  my $c = 0;

  while (my $msg = $in->read) {
    print "got message $c $msg\n";
    $out->write($msg);
    +$c;
  }

  # alternatively:

  my $cb = sub {
    print "got message $c ", shift, "\n"
    $out->write($msg);
    ++$c;
  };
  $in->loop($cb);

=head1 DESCRIPTION

Net::Nmsg::Input is the base class of a set format-specific input
classes which provide perl interfaces for the Net::Nmsg::XS::input
extension.

=head1 CONSTRUCTORS

=over 4

=item open($spec, %options)

Creates a new input object from the given specification. A reasonable
attempt is made to determine whether the specification is a file name
(nmsg, pcap), file handle (nmsg), channel alias or socket specification
(nmsg), or network device name (pcap), and is opened accordingly. If for
some reason this reasonable guess is not so reasonable, use one of the
specific open calls detailed below. The class of the returned object
depends on the apparent format of the input.

The resulting object can be treated like an IO handle. The following
both work:

  while (my $msg = <$in>) {
    # deal with $msg
  }

  while (my $msg = $in->read()) {
    # deal with $msg
  }

Options, where applicable, are valid for the more specific open calls
detailed further below. Available options:

=over 4

=item filter_vendor

=item filter_msgtype

Filter incoming messages based on the given vendor/msgtype. Both are
required if filtering is desired. Values can either be by name or
numeric id.

=item filter_source

Filter incoming messages based on the given source (nmsg only).

=item filter_operator

Filter incoming messages based on the given operator (nmsg only).

=item filter_group

Filter incoming messages based on the given group (nmsg only).

=item blocking_io

Specify whether or not this input is blocking or not.

=item rcvbuf

Set the receive buffer size (socket only)

=item bpf

Specify a Berkley Packet Filter (pcap file/interface only)

=item snaplen

Packet capture size (live interface only)

=item promisc

Promiscuous mode (live interface only)

=back

=item open_file($spec, %options)

Opens an input in nmsg format, as specified by file name or file handle.

=item open_json($spec, %options)

Opens an input in JSON format, as specified by file name or file handle.

=item open_sock($spec, %options)

Opens an input socket as specified by "host/port" or socket handle.
The host and port can also be passed as separate arguments.

=item open_pres($spec, %options)

Opens an input in nmsg presentation format, as specified by file name.
The 'filter_vendor' and 'filter_msgtype' options are required.

=item open_pcap($spec, %options)

Opens an input in pcap format, as specified by file name. The
'filter_vendor' and 'filter_msgtype' options are required.

=item open_iface($spec, %options)

Opens an input in pcap format, as specified by interface name. The
'filter_vendor' and 'filter_msgtype' options are required.

=back

=head2 ACCESSORS

=over

=item set_msgtype($vendor, $msgtype)

=item get_msgtype()

=item set_filter_source($source)

=item get_filter_source()

=item set_filter_operator($operator)

=item get_filter_operator()

=item set_filter_group($group)

=item get_filter_group()

=item set_blocking_io($bool)

=item get_blocking_io()

=item set_bpf($bpf)

=item get_bpf()

=item set_snaplen($len)

=item get_snaplen()

=item set_promisc($bool)

=item get_promisc()

=back

=head2 METHODS

=over 4

=item read()

Returns the next message from this input, if available, as a
Net::Nmsg::Msg object.

=item loop($callback, [$count])

Initiate processing of this input source, passing messages to the given
code reference. Callbacks receive a single Net::Nmsg::Msg reference as
an argument. An optional parameter I<count> stops the loop after that
many messages have been returned via the callback.

=back

=head1 SEE ALSO

L<Net::Nmsg>, L<Net::Nmsg::IO>, L<Net::Nmsg::Output>, L<Net::Nmsg::Msg>, L<nmsgtool(1)>

=head1 AUTHOR

Matthew Sisk, E<lt>sisk@cert.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010-2015 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
