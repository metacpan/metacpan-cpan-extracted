package QRCode::Encoder;
use v5.24;
use warnings;
use experimental qw< signatures >;
{ our $VERSION = '0.005' }

use Math::ReedSolomon::Encoder qw< rs_correction_string >;
use QRCode::Encoder::QRSpec qw< :all >;
use QRCode::Encoder::Matrix qw< add_matrix >; 
use Exporter qw< import >;
our @EXPORT_OK = qw<
   qr_best_params
   qr_encode
   qr_mode
>;
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub qr_mode ($octets) {
   return 'numeric' if $octets =~ m{\A \d* \z}mxs;
   return 'alphanumeric'
      if $octets =~ m{\A [0-9A-Z\x20\x24\x25\x2a\x2b\x2d-\x2f\x3a]+ \z}mxs;
   return 'kanji'
      if $octets =~ m{\A
         (?:  # start of a pair
               (?: [\x81-\x9f\xe0-\xea] [\x40-\x7e\x80-\xfc])
            |  (?: \xeb [\x40-\x7e\x80\xbf])
         )+
      \z}mxs;
   return 'byte';
}

sub qr_best_params (@args) {
   state $rank_for = { L => 1, M => 2, Q => 3, H => 4 };
   my %args = scalar(@args) % 2 ? (octets => @args) : @args;
   my $size = length($args{octets});
   my $mode = $args{mode} // qr_mode($args{octets});

   my $version = $args{version};
   my $min_version = $args{'min-version'} // 1;
   $version //= 40 if $min_version eq 40;

   my $level = $args{level};
   my $min_level = $args{min_level} // 'L';
   $level //= 'H' if $min_level eq 'H';

   if (defined($level)) {
      my $minv = qrspec_min_version_for($mode, $size, $level)
         or die "no suitable version for $mode/$size/$level";
      if (defined($version)) { # just check
         die "version $version insufficient for $mode/$size/$level"
            if $version < $minv;
      }
      else {
         my $req = $args{min_version} // 1;
         $version =  $minv < $req ? $req : $minv;
      }
   }
   elsif (defined($version)) {
      my $min_rank = $rank_for->{$min_level};
      for my $candidate (qw< H Q M L >) {
         last if $rank_for->{$candidate} < $min_rank;
         my $minv = qrspec_min_version_for($mode, $size, $candidate);
         if ($minv <= $version) {
            $level = $candidate;
            last;
         }
      }
      die "no level for $mode/$size/$version (min rank: $min_rank)"
         unless defined $level;
   }
   else { # nothing is defined, go for the smaller size
      $level = $min_level;
      my $min_rank = $rank_for->{$level};
      my $minv = qrspec_min_version_for($mode, $size, $level);
      my $req = $args{'min-version'} // 1;
      $version = $minv <= $req ? $req : $minv;
      for my $candidate (qw< L M Q H >) {
         next if $rank_for->{$candidate} <= $min_rank;
         my $altv = qrspec_min_version_for($mode, $size, $candidate);
         last if $altv > $minv;
         $level = $candidate;
      }
   }

   return (
      %args,
      mode    => $mode,
      level   => $level,
      version => $version,
   );
}

sub qr_encode (@args) {
   my %args = qr_best_params(@args);
   my $mode = $args{mode};
   my $level = $args{level};
   my $size = length($args{octets});
   $args{version} //= qrspec_min_version_for($mode, $size, $level);
   _add_encoded(\%args);
   _add_codewords(\%args);
   _add_error_correction(\%args);
   add_matrix(\%args);
   _add_plot(\%args);
   return \%args;
}

sub _add_plot ($args) {
   $args->{plot} = [
      map { [ map { $_ & 0x01 ? '*' : ' ' } $_->@* ] } $args->{matrix}->@*
   ];
   return $args;
}

sub _add_encoded ($args) {
   state $encoder_for = {
      numeric => \&_qr_encode_numeric,
      alphanumeric => \&_qr_encode_alphanumeric,
      byte => \&_qr_encode_byte,
      kanji => \&_qr_encode_kanji,
   };

   my $mode = $args->{mode};
   my $encoder = $encoder_for->{$mode} or die "missing mode <$mode>\n";
   my $mi = qrspec_mode_indicator($mode);

   my $version = $args->{version};
   my $size = length($args->{octets});

   my $lis = qrspec_length_indicator($mode, $args->{version});
   my $li = _dec2bin(length($args->{octets}), $lis);
   
   $args->{encoded} = $mi . $li . $encoder->($args->{octets});

   return $args;
}

sub _add_codewords ($args) {
   my $bit_stream = $args->{encoded};
   my $data_size = qrspec_data_size($args->@{qw< version level >});
   my $needed_bits = length($bit_stream);
   my $residual_bits = 8 * $data_size - $needed_bits;
   die "not enough bits, wrong version?\n" if $residual_bits < 0;
   my $terminator_size = $residual_bits >= 4 ? 4 : $residual_bits;
   $bit_stream .= '0' x $terminator_size;
   $residual_bits -= $terminator_size;
   if (my $pad1 = $residual_bits % 8) {
      $bit_stream .= '0' x $pad1;
      $residual_bits -= $pad1;
   }
   while ($residual_bits > 0) {
      $bit_stream .= '11101100';
      last if $residual_bits == 8;
      $bit_stream .= '00010001';
      $residual_bits -= 16;
   }
   $args->{bit_stream} = $bit_stream;
   $args->{codewords} = pack 'B*', $bit_stream;
   return $args;
}

sub _add_error_correction ($args) {
   my @blocks = qrspec_ecc_spec($args->@{qw< version level >});
   $args->{ecc} = \@blocks;
   my $expanded = '';
   my $codewords = $args->{codewords};
   my $i = 0;
   my (@codewords, @eccs);
   for my $block (@blocks) {
      my ($ecc, $data, $count) = $block->@{qw< ecc data count >};
      while ($count-- > 0) {
         my $cw = substr($codewords, $i, $data);
         push @codewords, $cw;
         push @eccs, rs_correction_string($cw, $ecc);
         $i += $data;
      }
   }
   $args->{expanded} = _linearize(\@codewords) . _linearize(\@eccs);
   $args->{remainder} = qrspec_remainder($args->{version});
   return $args;
}

sub _linearize ($strings) {
   return $strings->[0] if $strings->@* == 1;
   my $retval = '';
   my $i = 0;
   my $n = length($strings->[-1]);
   while ($i < $n) {
      for my $string ($strings->@*) {
         next if $i >= length($string);
         $retval .= substr($string, $i, 1);
      }
      ++$i;
   }
   return $retval;
}

sub _dec2bin ($v, $n) { substr(unpack('B*', pack('N', $v)), -$n, $n) }

sub _qr_encode_numeric ($octets) {
   state $n_bits_for = [ 4, 7, 10 ];
   my $i = 0; # index of start of substr, advanced each iteration
   my $r = length($octets); # number of residual octets to take
   my $bits = '';
   while ($r > 0) {
      my $l = $r >= 3 ? 3 : $r;
      $bits .= _dec2bin(substr($octets, $i, $l), $n_bits_for->[$l - 1]);
      $r -= $l;
      $i += $l;
   }
   return $bits;
}

sub _qr_encode_alphanumeric ($octets) {
   state $chars = [ 0 .. 9, 'A' .. 'Z', split //, ' $%*+-./:' ];
   state $value_for = { map { $chars->[$_] => $_ } 0 .. $chars->$#* };
   my $i = 0; # index of start of substr, advanced each iteration
   my $r = length($octets); # number of residual octets to take
   my $bits = '';
   while ($r > 0) {
      if ($r == 1) {
         $bits .= _dec2bin($value_for->{substr($octets, $i, 1)}, 6);
         $r = 0;
      }
      else {
         my $value = $value_for->{substr($octets, $i++, 1)} * 45;
         $value += $value_for->{substr($octets, $i++, 1)};
         $bits .= _dec2bin($value, 11);
         $r -= 2;
      }
   }
   return $bits;
}

sub _qr_encode_kanji ($octets) {
   my $i = 0;
   my $r = length($octets);
   my $bits = '';
   while ($r > 0) {
      my $v = unpack('n', substr($octets, $i, 2));
      $v -= ($v <= 0x9FFC) ? 0x8140 : 0xC140;
      $v = ($v >> 8) * 0xC0 + ($v & 0xFF);
      $bits .= _dec2bin($v, 13);
      $r -= 2;
      $i += 2;
   }
   return $bits;
}

sub _qr_encode_byte ($octets) { unpack 'B*', $octets }


1;
