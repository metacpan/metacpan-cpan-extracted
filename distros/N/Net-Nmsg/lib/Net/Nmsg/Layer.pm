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

package Net::Nmsg::Layer;

use strict;
use warnings;
use Carp;

use Symbol ();

sub _defaults { {} }

sub defaults {
  my $defaults = shift->_defaults;
  wantarray ? %$defaults : {%$defaults};
}

sub opt_required { }

sub _io   { *{shift()}->{_io  } }
sub _xs   { *{shift()}->{_xs  } }
sub _spec { *{shift()}->{_spec} }
sub _opt  { *{shift()}->{_opt } }

###

sub _get_io_opt {
  my $self = shift;
  $self->_get_inner_opt($self->_io, @_);
}

sub _set_io_opt {
  my $self = shift;
  $self->_set_inner_opt($self->_io, @_);
}

sub _get_xs_opt {
  my $self = shift;
  $self->_get_inner_opt($self->_xs, @_);
}

sub _set_xs_opt {
  my $self = shift;
  $self->_set_inner_opt($self->_xs, @_);
}

sub _get_opt {
  my $self = shift;
  my $opt  = shift;
  my $v = *$self->{_opt}{$opt} || [];
  return $v->[0] if @$v == 1;
  wantarray ? @$v : [@$v];
}

sub _get_inner_opt {
  my $self = shift;
  my($io, $opt) = splice(@_, 0, 2);
  my $m = 'get_' . $opt;
  return $self->_set_opt($opt, $io->$m()) if $io && UNIVERSAL::can($io => $m);
  $self->_get_opt($opt);
}

sub _set_opt {
  my $self = shift;
  my $opt  = shift;
  if (@_ == 1 && ref $_[0] eq 'ARRAY') {
    @_ = @{$_[0]};
  }
  *$self->{_opt}{$opt} = [@_] if @_;
  $self->_get_opt($opt);
}

sub _set_inner_opt {
  my $self = shift;
  my($io, $opt) = splice(@_, 0, 2);
  if (@_ == 1 && ref $_[0] eq 'ARRAY') {
    @_ = @{$_[0]};
  }
  my $m = 'set_' . $opt;
  eval { $io->$m(@_) };
  croak $@ if $@ && $@ !~ /locate\s+object\s+method/i;
  $self->_set_opt($opt, @_);
}

### construction/opening

sub _map_opts { shift; @_ }

sub _open_init {
  my $self  = shift;
  my $fatal;
  if (! ref $self) {
    $self  = $self->new;
    $fatal = 1;
  }
  croak "spec required" unless @_;
  my $spec     = shift;
  my %opt      = (%{$self->_opt}, @_);
  my $defaults = $self->_defaults;
  for my $o (keys %opt) {
    if (! exists $defaults->{$o} && $o !~ /^_/) {
      warn "unknown option '$o'";
      delete $opt{$o};
    }
  }
  for my $o (grep { defined $_ } $self->opt_required) {
    croak "option '$o' required" unless defined $opt{$o};
  }
  return($self, $spec, $fatal, $self->_map_opts(%$defaults, %opt));
}

sub new {
  my $class = shift;
  $class = ref $class || $class;
  my $self = Symbol::gensym();
  bless $self, $class;
  *$self->{_opt} = {};
  $self->open(@_) if @_;
  $self;
}

sub _dup_io_r {
  my $self = shift;
  my $fh = @_ ? shift : $self->_io;
  return unless defined $fh && defined fileno($fh);
  open($self, '<&=', $fh) || die "problem duping read fh : $!";
  $self;
}

sub _dup_io_w {
  my $self = shift;
  my $fh = @_ ? shift : $self->_io;
  return unless defined $fh && defined fileno($fh);
  open($self, '>&=', $fh) || die "problem duping write fh : $!";
  $self;
}

sub _init_opts {
  my $self = shift;
  my %opt  = @_;
  for my $o (keys %opt) {
    next if $o =~ /^_/;
    my $v = $opt{$o};
    next unless defined $v;
    my $m = 'set_' . $o;
    $self->$m($v) if UNIVERSAL::can($self, $m);
  }
  $self;
}

### IO layer

sub error {
  my $self = shift;
  @_ ? *$self->{_error} = shift : *$self->{_error};
}

sub clear_error { *shift->{_error} = undef }

sub close {
  my $self  = shift;
  # delete xs first in order to defer cleanup of unmanaged members
  # e.g. destroy output xs before destroying rate objects
  delete ${*$self}{_xs};
  %{*$self} = ();
  undef *$self if $] eq "5.008"; # cargo cult; see IO::String
  1;
}

sub opened { (shift->_io || return)->opened }
sub fileno { (shift->_io || return)->fileno }
sub stat   { (shift->_io || return)->stat   }

sub blocking { (shift->_io || croak "Bad filehandle")->blocking }
sub eof      { (shift->_io || croak "Bad filehandle")->eof      }

sub _fake_stat {
  my $self = shift;
  return unless $self->opened;
  return 1 unless wantarray;
  return (
    undef, # dev
    undef, # ino
    0666,  # mode
    1,     # links
    $>,    # uid
    $),    # gid
    undef, # did
    0,     # size
    undef, # atime
    undef, # mtime
    undef, # ctime
    0,     # blksize
    0,     # blocks
  );
}

###

1;
