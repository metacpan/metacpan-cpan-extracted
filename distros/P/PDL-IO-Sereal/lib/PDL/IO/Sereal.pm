package PDL::IO::Sereal;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK   = qw(rsereal wsereal);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.003';

use constant DEBUG => $ENV{PDL_IO_SEREAL_DEBUG} ? 1 : 0;

use PDL;
use PDL::Types;
use PDL::IO::Misc   qw(bswap2 bswap4 bswap8);
use Sereal::Encoder qw(encode_sereal);
use Sereal::Decoder qw(decode_sereal);
use Scalar::Util    qw(looks_like_number);

use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

sub import {
  my $package = shift;
  {
    no strict 'refs';
    *{'PDL::wsereal'} = \&wsereal if grep { /^(:all|wsereal)$/ } @_;
    *{'PDL::FREEZE'}  = \&_FREEZE;
    *{'PDL::THAW'}    = \&_THAW;
  }
  __PACKAGE__->export_to_level(1, $package, @_) if @_;
}

sub wsereal {
  my ($pdl, $filename) = @_;
  my $sereal = encode_sereal($pdl, {freeze_callbacks=>1, compress=>Sereal::Encoder::SRL_ZLIB});
  _write_file($filename, $sereal);
  return $pdl;
}

sub rsereal {
  my $filename = shift;
  my $sereal = _read_file($filename);
  my $pdl = decode_sereal($sereal);
  return $pdl;
}

sub _FREEZE {
  my ($self, $serializer) = @_;
  my $ref = $self->get_dataref;
  my $out = {
    version     => 1,
    dims        => [$self->dims],
    type_name   => $self->type->ioname,
    type_size   => PDL::Core::howbig($self->type),
    packed_data => $$ref,
    native_one  => pack('L', 1),
  };
  if (ref $self->hdr eq 'HASH') {
    $out->{hash_hdr} = $self->hdr;
  }
  if ($self->isa("HASH")) {
    for (keys %$self) {
      next if $_ eq 'PDL'; # "PDL" is reserved
      $out->{hash_main}{$_} = $self->{$_};
    }
  }
  if ($self->badflag) {
    $out->{bad_flag}  = $self->badflag;
    $out->{bad_value} = $self->badvalue;
  }
  $out->{hdrcpy_flag} = 1 if $self->hdrcpy;
  return $out;
}

sub _THAW {
  my ($class, $serializer, $data) = @_;
  croak "THAW: bad input data" unless ref $data eq 'HASH' && looks_like_number($data->{version});
  if ($data->{version} == 1) {
    croak "THAW: invalid type_name"   unless defined $data->{type_name} && !ref $data->{type_name};
    croak "THAW: invalid type_size"   unless defined $data->{type_size} && looks_like_number($data->{type_size});
    croak "THAW: invalid dims"        unless ref $data->{dims} eq 'ARRAY';
    croak "THAW: invalid native_one"  unless defined $data->{native_one} && !ref $data->{native_one};
    croak "THAW: invalid packed_data" unless defined $data->{packed_data} && !ref $data->{packed_data};
    my $type = PDL::Type->new($data->{type_name});
    croak "THAW: unsupported type" unless $type;
    my $type_sz = PDL::Core::howbig($type);
    croak "THAW: type '$data->{type_name}' size mismatch ($type_sz != $data->{type_size})" unless $type_sz == $data->{type_size};
    my $native_one = unpack('L', $data->{native_one});
    croak "THAW: unknown endianness" unless $native_one == 0x01000000 || $native_one == 0x00000001;
    my $do_swap = $native_one == 0x01000000 ? 1 : 0;
    my $pdl = PDL::new_from_specification($class, $type, @{$data->{dims}});
    my $dataref = $pdl->get_dataref;
    croak "THAW: data size mismatch" unless length $$dataref == length $data->{packed_data};
    $$dataref = $data->{packed_data};
    if ($do_swap && $type_sz > 1) {
      bswap2($pdl) if($type_sz==2);
      bswap4($pdl) if($type_sz==4);
      bswap8($pdl) if($type_sz==8);
    }
    $pdl->upd_data;
    if (ref $data->{hash_hdr} eq "HASH") {
      $pdl->sethdr($data->{hash_hdr});
    }
    if ($pdl->isa("HASH") && ref $data->{hash_main} eq "HASH") {
      for (keys %{$data->{hash_main}}) {
        next if $_ eq 'PDL'; # "PDL" is reserved
        $pdl->{$_} = $data->{hash_main}{$_};
      }
    }
    if ($data->{bad_flag}) {
      $pdl->badflag($data->{bad_flag});
      $pdl->badvalue($data->{bad_value}) if defined $data->{bad_value};
    }
    $pdl->hdrcpy(1) if $data->{hdrcpy_flag};
    return $pdl;
  }
  else {
    croak "THAW: invalid version";
  }
}

sub _read_file {
  my ($filename) = @_;
  open my $fh, '<', $filename or croak "rsereal: cannot open '$filename': $!";
  my $rv;
  my $data = '';
  while ($rv = sysread($fh, my $buffer, 102400, 0)) {
    $data .= $buffer
  }
  croak "rsereal: cannot read file '$filename': $!" if !defined $rv;
  return $data;
}

sub _write_file {
  my ($filename, $data) = @_;
  open my $fh, '>', $filename or croak "wsereal: cannot open '$filename': $!";
  my $rv = syswrite($fh, $data);
  croak "wsereal: cannot write '$filename': $!" if !defined $rv;
}

1;

__END__

=head1 NAME

PDL::IO::Sereal - Load/save complete PDL content serialized via Sereal

=head1 SYNOPSIS

  use PDL;
  use PDL::IO::Sereal ':all';

  my $pdl = random(100, 100, 100);
  # write piddle to file
  $pdl->wsereal('saved-piddle1.sereal');
  # read piddle from file
  my $new_pdl = rsereal('saved-piddle1.sereal');

=head1 DESCRIPTION

Loading and saving PDL piddle serialized via L<Sereal> (by default with ZLIB compression).
Saved files should be portable across different architectures and PDL versions (there might
be some troubles with piddles of 'indx' type which are not portable between perls with
64bit vs. 32bit integers).

=head1 FUNCTIONS

By default PDL::IO::Sereal doesn't import any function. You can import individual functions like this:

 use PDL::IO::Sereal qw(rsereal wsereal);

Or import all available functions:

 use PDL::IO::Sereal ':all';

B<BEWARE:> any C<use PDL::IO::Sereal> also installs C<FREEZE> and C<THAW> functions
into C<PDL> namespace - see L<Sereal::Encoder>.

=head2 wsereal

  wsereal($pdl, 'piddle1.sereal');
  # or
  $pdl->wsereal('piddle2.sereal');
  # or even
  $pdl->wsereal('piddle3.sereal')->minus($x, 0)->wsereal('piddle4.sereal');

=head2 rsereal

  $pdl = rsereal('saved-piddle.sereal');

=head1 SEE ALSO

L<PDL>, L<Sereal>, L<Sereal::Encoder>, L<Sereal::Decoder>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 COPYRIGHT

2015 KMX E<lt>kmx@cpan.orgE<gt>
