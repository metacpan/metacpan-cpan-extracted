package Nobody::PP;
require Exporter;
*import = \&Exporter::import;

use FindBin qw($RealBin);
use lib "$RealBin/../lib", "$RealBin/lib";
use Nobody::Auto qw( common::sense );
use strict;
use common::sense;
use vars qw(@EXPORT @EXPORT_OK $VERSION $DEBUG %EXPORT_TAGS @subs);
use Data::Dumper;
use Scalar::Util qw(blessed);
BEGIN {
  # blessed imported from Scalar::Util above (builtin::blessed requires perl 5.36+)
  @subs=qw(dd ddx ee eex pp ppx quote qquote loc); 
};
use subs @subs;
@EXPORT = @EXPORT_OK = @subs;
%EXPORT_TAGS = ( 
  all=>[ @EXPORT_OK ],
);

sub qquote {
  local ($Data::Dumper::Deparse, $Data::Dumper::Terse) = ( 1, 1 );
  return Data::Dumper::qquote(@_);
};
sub deparse {
  local ($Data::Dumper::Deparse, $Data::Dumper::Terse) = ( 1, 1 );
  return Data::Dumper::Dumper(@_);
};
sub ee {
  print STDERR pp(@_), "\n";
}
sub dd {
  print pp(@_), "\n";
}
sub loc {
  my($idx)=0;
  my($pkg, $file, $line);
  do {
    ($pkg,$file,$line)=caller($idx++);
  } while($pkg eq 'Nobody::PP');
  join(':',$file,$line,"@_");
};
sub ppx {
  return loc(pp(@_));
}
sub ddx {
  say STDOUT ppx(@_);
}
sub eex {
  say STDERR ppx(@_);
};

$VERSION = "1.25";
$DEBUG = 0;

use overload ();
use vars qw(%seen %refcnt @dump @fixup %require $TRY_BASE64  $INDENT $LINEWIDTH);

$TRY_BASE64 = 50 unless defined $TRY_BASE64;
$INDENT = "  " unless defined $INDENT;
$LINEWIDTH = 60 unless defined $LINEWIDTH;

sub pp
{
  local %seen;
  local %refcnt;
  local %require;
  local @fixup;


  my $name = "a";
  my @dump;

  for my $v (@_) {
    my $val = _pp($v, $name, [], tied($v));
    push(@dump, [$name, $val]);
  } continue {
    $name++;
  }

  my $out = "";
  if (%require) {
    for (sort keys %require) {
      $out .= "require $_;\n";
    }
  }
  if (%refcnt) {
    # output all those with refcounts first
    for (@dump) {
      my $name = $_->[0];
      if ($refcnt{$name}) {
        $out .= "my \$$name = $_->[1];\n";
        undef $_->[1];
      }
    }
    for (@fixup) {
      $out .= "$_;\n";
    }
  }

  my $paren = (@dump != 1);
  $out .= "(" if $paren;
  $out .= format_list($paren, undef,
    map {defined($_->[1]) ? $_->[1] : "\$".$_->[0]}
    @dump
  );
  $out .= ")" if $paren;

  if (%refcnt || %require) {
    $out .= ";\n";
    $out =~ s/^/$INDENT/gm;
    $out = "do {\n$out}";
  }

  print STDERR "$out\n" unless defined wantarray;
  $out;
}

sub dd {
  say pp(@_);
}

sub ddx {
  say ppx(@_);
}


sub Path::Tiny::selfpp($) {
  my($rval)=shift;
  return "path(".qquote($rval).")";
}
sub URI::selfpp($) {
  my($rval)=shift;
  return "uri(".qquote($rval).")";
};

sub tied_str {
  my $tied = shift;
  if ($tied) {
    if (my $tied_ref = ref($tied)) {
      $tied = "tied $tied_ref";
    }
    else {
      $tied = "tied";
    }
  }
  return $tied;
}

sub fullname
{
  my($name, $idx, $ref) = @_;
  substr($name, 0, 0) = "\$";

  my @i = @$idx;  # need copy in order to not modify @$idx
  if ($ref && @i && $i[0] eq "\$") {
    shift(@i);  # remove one deref
    $ref = 0;
  }
  while (@i && $i[0] eq "\$") {
    shift @i;
    $name = "\$$name";
  }

  my $last_was_index;
  for my $i (@i) {
    if ($i eq "*" || $i eq "\$") {
      $last_was_index = 0;
      $name = "$i\{$name}";
    } elsif ($i =~ s/^\*//) {
      $name .= $i;
      $last_was_index++;
    } else {
      $name .= "->" unless $last_was_index++;
      $name .= $i;
    }
  }
  $name = "\\$name" if $ref;
  $name;
}

sub format_list
{
  my $paren = shift;
  my $comment = shift;
  my $indent_lim = $paren ? 0 : 1;
  if (@_ > 3) {
    # can we use range operator to shorten the list?
    my $i = 0;
    while ($i < @_) {
      my $j = $i + 1;
      my $v = $_[$i];
      while ($j < @_) {
        # XXX allow string increment too?
        if ($v eq "0" || $v =~ /^-?[1-9]\d{0,9}\z/) {
          $v++;
        }
        elsif ($v =~ /^"([A-Za-z]{1,3}\d*)"\z/) {
          $v = $1;
          $v++;
          $v = qq("$v");
        }
        else {
          last;
        }
        last if $_[$j] ne $v;
        $j++;
      }
      if ($j - $i > 3) {
        splice(@_, $i, $j - $i, "$_[$i] .. $_[$j-1]");
      }
      $i++;
    }
  }
  my $tmp = "@_";
  if ($comment || (@_ > $indent_lim && (length($tmp) > $LINEWIDTH || $tmp =~ /\n/))) {
    my @elem = @_;
    for (@elem) { s/^/$INDENT/gm; }
    return "\n" . ($comment ? "$INDENT# $comment\n" : "") .
    join(",\n", @elem, "");
  } else {
    return join(", ", @_);
  }
}

sub str {
  if (length($_[0]) > 20) {
    for ($_[0]) {
      # Check for repeated string
      if (/^(.)\1\1\1/s) {
        # seems to be a repeating sequence, let's check if it really is
        # without backtracking
        unless (/[^\Q$1\E]/) {
          my $base = quote($1);
          my $repeat = length;
          return "($base x $repeat)"
        }
      }
      # Length protection because the RE engine will blow the stack [RT#33520]
      if (length($_) < 16 * 1024 && /^(.{2,5}?)\1*\z/s) {
        my $base   = quote($1);
        my $repeat = length($_)/length($1);
        return "($base x $repeat)";
      }
    }
  }

  local $_ = &quote;

  if (length($_) > 40  && !/\\x\{/ && length($_) > (length($_[0]) * 2)) {
    # too much binary data, better to represent as a hex/base64 string

    # Base64 is more compact than hex when string is longer than
    # 17 bytes (not counting any require statement needed).
    # But on the other hand, hex is much more readable.
    if ($TRY_BASE64 && length($_[0]) > $TRY_BASE64 &&
      (defined &utf8::is_utf8 && !utf8::is_utf8($_[0])) &&
      eval { require MIME::Base64 })
    {
      $require{"MIME::Base64"}++;
      return "MIME::Base64::decode(\"" .
      MIME::Base64::encode($_[0],"") .
      "\")";
    }
    return "pack(\"H*\",\"" . unpack("H*", $_[0]) . "\")";
  }

  return $_;
}

my %esc = (
  "\a" => "\\a",
  "\b" => "\\b",
  "\t" => "\\t",
  "\n" => "\\n",
  "\f" => "\\f",
  "\r" => "\\r",
  "\e" => "\\e",
);

# put a string value in double quotes
sub quote {
  local($_) = $_[0];
  # If there are many '"' we might want to use qq() instead
  s/([\\\"\@\$])/\\$1/g;
  return qq("$_") unless /[^\040-\176]/;  # fast exit

  s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

  # no need for 3 digits in escape for these
  s/([\0-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;

  s/([\0-\037\177-\377])/sprintf('\\x%02X',ord($1))/eg;
  s/([^\040-\176])/sprintf('\\x{%X}',ord($1))/eg;

  return qq("$_");
}
BEGIN {
  sub _pp
  {
    if(blessed($_[0]) && $_[0]->can("selfpp")){
      return $_[0]->selfpp();
    };
    my $ref  = ref $_[0];
    my $rval = $ref ? $_[0] : \$_[0];
    shift;
    my($name, $idx, $dont_remember, $pclass, $pidx) = @_;

    my($class, $type, $id);
    my $strval = overload::StrVal($rval);
    # Parse $strval without using regexps, in order not to clobber $1, $2,...
    if ((my $i = rindex($strval, "=")) >= 0) {
      $class = substr($strval, 0, $i);
      $strval = substr($strval, $i+1);
    }
    if ((my $i = index($strval, "(0x")) >= 0) {
      $type = substr($strval, 0, $i);
      $id = substr($strval, $i + 2, -1);
    }
    else {
      die "Can't parse " . overload::StrVal($rval);
    }
    #  Not sure what is happening here, so gonna change the
    #  min version to 5.008.
    #  if ($] < 5.008 && $type eq "SCALAR") {
    #  $type = "REF" if $ref eq "REF";
    #}
    warn "\$$name(@$idx) $class $type $id ($ref)" if $DEBUG;

    my $out;
    my $comment;
    my $hide_keys;

    unless ($dont_remember) {
      if (my $s = $seen{$id}) {
        my($sname, $sidx) = @$s;
        $refcnt{$sname}++;
        my $sref = fullname($sname, $sidx,
          ($ref && $type eq "SCALAR"));
        warn "SEEN: [\$$name(@$idx)] => [\$$sname(@$sidx)] ($ref,$sref)" if $DEBUG;
        return $sref unless $sname eq $name;
        $refcnt{$name}++;
        push(@fixup, fullname($name,$idx)." = $sref");
        return "do{my \$fix}" if @$idx && $idx->[-1] eq '$';
        return "'fix'";
      }
      $seen{$id} = [$name, $idx];
    }

    if ($class) {
      $pclass = $class;
      $pidx = @$idx;
    }
    {
    if (defined $out) {
      # keep it
    }
    elsif ($type eq "SCALAR" || $type eq "REF" || $type eq "REGEXP") {
      if ($ref) {
        if ($class && $class eq "Regexp") {
          my $v = "$rval";

          my $mod = "";
          if ($v =~ /^\(\?\^?([msix-]*):([\x00-\xFF]*)\)\z/) {
            $mod = $1;
            $v = $2;
            $mod =~ s/-.*//;
          }

          my $sep = '/';
          my $sep_count = ($v =~ tr/\///);
          if ($sep_count) {
            # see if we can find a better one
            for ('|', ',', ':', '#') {
              my $c = eval "\$v =~ tr/\Q$_\E//";
              #print "SEP $_ $c $sep_count\n";
              if ($c < $sep_count) {
                $sep = $_;
                $sep_count = $c;
                last if $sep_count == 0;
              }
            }
          }
          $v =~ s/\Q$sep\E/\\$sep/g;

          $out = "qr$sep$v$sep$mod";
          undef($class);
        }
        else {
          delete $seen{$id} if $type eq "SCALAR";  # will be seen again shortly
          my $val = _pp($$rval, $name, [@$idx, "\$"], 0, $pclass, $pidx);
          $out = $class ? "do{\\(my \$o = $val)}" : "\\$val";
        }
      } else {
        if (!defined $$rval) {
          $out = "undef";
        }
        elsif ($$rval =~ /^-?(?:nan|inf)/i) {
          $out = str($$rval);
        }
        elsif (do {no warnings 'numeric'; $$rval + 0 eq $$rval}) {
          $out = $$rval;
        }
        else {
          $out = str($$rval);
        }
        if ($class && !@$idx) {
          # Top is an object, not a reference to one as perl needs
          $refcnt{$name}++;
          my $obj = fullname($name, $idx);
          my $cl  = quote($class);
          push(@fixup, "bless \\$obj, $cl");
        }
      }
    }
    elsif ($type eq "GLOB") {
      if ($ref) {
        delete $seen{$id};
        my $val = _pp($$rval, $name, [@$idx, "*"], 0, $pclass, $pidx);
        $out = "\\$val";
        if ($out =~ /^\\\*Symbol::/) {
          $require{Symbol}++;
          $out = "Symbol::gensym()";
        }
      } else {
        my $val = "$$rval";
        $out = "$$rval";

        for my $k (qw(SCALAR ARRAY HASH)) {
          my $gval = *$$rval{$k};
          next unless defined $gval;
          next if $k eq "SCALAR" && ! defined $$gval;  # always there
          my $f = scalar @fixup;
          push(@fixup, "RESERVED");  # overwritten after _pp() below
          $gval = _pp($gval, $name, [@$idx, "*{$k}"], 0, $pclass, $pidx);
          $refcnt{$name}++;
          my $gname = fullname($name, $idx);
          $fixup[$f] = "$gname = $gval";  #XXX indent $gval
        }
      }
    }
    elsif ($type eq "ARRAY") {
      my @vals;
      my $tied = tied_str(tied(@$rval));
      my $i = 0;
      for my $v (@$rval) {
        push(@vals, _pp($v, $name, [@$idx, "[$i]"], $tied, $pclass, $pidx));
        $i++;
      }
      $out = "[" . format_list(1, $tied, @vals) . "]";
    }
    elsif ($type eq "HASH") {
      my(@keys, @vals);
      my $tied = tied_str(tied(%$rval));

      # statistics to determine variation in key lengths
      my $kstat_max = 0;
      my $kstat_sum = 0;
      my $kstat_sum2 = 0;

      my @orig_keys = keys %$rval;
      if ($hide_keys) {
        @orig_keys = grep !$hide_keys->($_), @orig_keys;
      }
      my $text_keys = 0;
      for (@orig_keys) {
        $text_keys++, last unless /^[-+]?(?:0|[1-9]\d*)(?:\.\d+)?\z/;
      }

      if ($text_keys) {
        @orig_keys = sort { lc($a) cmp lc($b) } @orig_keys;
      }
      else {
        @orig_keys = sort { $a <=> $b } @orig_keys;
      }

      my $quote;
      for my $key (@orig_keys) {
        next if $key =~ /^-?[a-zA-Z_]\w*\z/;
        next if $key =~ /^-?[1-9]\d{0,8}\z/;
        $quote++;
        last;
      }

      for my $key (@orig_keys) {
        my $val = \$rval->{$key};  # capture value before we modify $key
        $key = quote($key) if $quote;
        $kstat_max = length($key) if length($key) > $kstat_max;
        $kstat_sum += length($key);
        $kstat_sum2 += length($key)*length($key);

        push(@keys, $key);
        push(@vals, _pp($$val, $name, [@$idx, "{$key}"], $tied, $pclass, $pidx));
      }
      my $nl = "";
      my $klen_pad = 0;
      my $tmp = "@keys @vals";
      if (length($tmp) > $LINEWIDTH || $tmp =~ /\n/ || $tied) {
        $nl = "\n";

        # Determine what padding to add
        if ($kstat_max < 4) {
          $klen_pad = $kstat_max;
        }
        elsif (@keys >= 2) {
          my $n = @keys;
          my $avg = $kstat_sum/$n;
          my $stddev = sqrt(($kstat_sum2 - $n * $avg * $avg) / ($n - 1));

          # I am not actually very happy with this heuristics
          if ($stddev / $kstat_max < 0.25) {
            $klen_pad = $kstat_max;
          }
          if ($DEBUG) {
            push(@keys, "__S");
            push(@vals, sprintf("%.2f (%d/%.1f/%.1f)",
                $stddev / $kstat_max,
                $kstat_max, $avg, $stddev));
          }
        }
      }
      $out = "{$nl";
      $out .= "$INDENT# $tied$nl" if $tied;
      while (@keys) {
        my $key = shift @keys;
        my $val = shift @vals;
        my $vpad = $INDENT . (" " x ($klen_pad ? $klen_pad + 4 : 0));
        $val =~ s/\n/\n$vpad/gm;
        my $kpad = $nl ? $INDENT : " ";
        $key .= " " x ($klen_pad - length($key)) if $nl && $klen_pad > length($key);
        $out .= "$kpad$key => $val,$nl";
      }
      $out =~ s/,$/ / unless $nl;
      $out .= "}";
    }
    elsif ($type eq "CODE") {
      $out = deparse( $rval );
      while(substr($out,-1,1)eq'\n'){
        substr($out,-1,1)="";
      };
    }
    elsif ($type eq "LVALUE" ) {
      my($rval)=$rval;
      $out=_pp($rval);
    }
    elsif ($type eq "VSTRING") {
      $out = sprintf +($ref ? '\v%vd' : 'v%vd'), $$rval;
    }

    #===
    else {
      warn "Can't handle $type data";
      $out = "'#$type#'";
    }
    #===
  }

    if ($class && $ref) {
      $out = "bless($out, " . quote($class) . ")";
    }
    if ($comment) {
      $comment =~ s/^/# /gm;
      $comment .= "\n" unless $comment =~ /\n\z/;
      $comment =~ s/^#[ \t]+\n/\n/;
      $out = "$comment$out";
    }
    return $out;
  }
}
1;

=head1 NAME

Nobody::PP - Pretty-printer for Perl data structures

=head1 SYNOPSIS

  use Nobody::PP;

  dd({ key => "value", list => [1, 2, 3] });   # print to STDOUT
  ee({ key => "value" });                        # print to STDERR
  my $str = pp({ key => "value" });              # return as string
  ddx($thing);                                   # print with file:line prefix

=head1 DESCRIPTION

C<Nobody::PP> is a pretty-printer for Perl data structures, providing
compact, readable output suitable for debugging.

=head1 EXPORTS

C<dd>, C<ddx>, C<ee>, C<eex>, C<pp>, C<ppx>, C<quote>, C<qquote>, C<loc>
are exported by default.

=head1 FUNCTIONS

=head2 pp( @data )

Returns a string representation of C<@data>.

=head2 dd( @data )

Prints C<pp(@data)> to STDOUT followed by a newline.

=head2 ee( @data )

Prints C<pp(@data)> to STDERR followed by a newline.

=head2 ppx( @data )

Returns C<pp(@data)> prefixed with the caller's file and line number.

=head2 ddx( @data )

Prints C<ppx(@data)> to STDOUT.

=head2 eex( @data )

Prints C<ppx(@data)> to STDERR.

=head2 loc( @strings )

Returns a string of the form C<file:line:@strings> identifying the call site.

=head2 quote( $string )

Returns C<$string> as a single-quoted Perl string literal.

=head2 qquote( $string )

Returns C<$string> as a double-quoted Perl string literal (via C<Data::Dumper>).

=head1 ACKNOWLEDGEMENTS

This module is derived from L<Data::Dump> by Gisle Aas.
Thank him for the features; blame me for the bugs.

=head1 AUTHOR

Rich Paul, C<< <nobody at cpan.org> >>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
