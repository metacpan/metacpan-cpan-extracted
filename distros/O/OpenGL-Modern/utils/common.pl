use strict;
use warnings;

my %type2func = (
  GLboolean => 'IV',
  GLubyte => 'UV',
  GLbyte => 'IV',
  GLfixed => 'IV',
  GLshort => 'IV',
  GLushort => 'UV',
  GLuint => 'UV',
  GLint => 'IV',
  GLsizei => 'IV',
  GLuint64 => 'UV',
  GLuint64EXT => 'UV',
  GLint64 => 'IV',
  GLint64EXT => 'IV',
  GLhalf => 'NV', # not right
  GLfloat => 'NV',
  GLdouble => 'NV',
  GLclampf => 'NV',
  GLclampd => 'NV',
  'GLchar*' => 'PV_nolen',
  'GLcharARB*' => 'PV_nolen',
  GLenum => 'IV',
);
sub typefunc {
  my ($type) = @_;
  $type2func{$type};
}

sub is_stringtype {
  my ($type, $const) = @_;
  return $type =~ /^\s*const\s+GLchar(?:ARB)?\s*\*\s*$/ if $const;
  $type =~ /^\s*GLchar(?:ARB)?\s*\*\s*$/;
}

sub slurp {
    my $filename = $_[0];
    open my $old_fh, '<:raw', $filename
      or die "Couldn't read '$filename': $!";
    join '', <$old_fh>;
}

sub save_file {
    my ( $filename, $new ) = @_;
    my $old = -e $filename ? slurp( $filename ) : "";
    if ( $new ne $old ) {
        print "Saving new version of $filename\n";
        open my $fh, '>:raw', $filename
          or die "Couldn't write new version of '$filename': $!";
        print $fh $new;
    }
}

sub make_aliases {
  my ($aliases) = @_;
  my $i = 0;
  !@$aliases ? "" : "ALIAS:\n".join '', map "  $_ = ".++$i."\n", @$aliases;
}

sub parse_ptr {
  my ($data) = @_;
  my $const = (my $type = $data->[1]) =~ s#\bconst\b##g;
  $type =~ s#\*##;
  $type =~ s#\s##g;
  [$type, $const];
}

sub bindings {
  die "list context only" if !wantarray;
  my ($name, $s, $counts, $signatures) = @_;
  die "bindings: no signatures given" if !$signatures;
  my $avail_check = ($s->{glewtype} eq 'fun' && $s->{glewImpl})
    ? "  OGLM_AVAIL_CHECK($s->{glewImpl}, $name)\n"
    : "";
  my @argdata = @{$s->{argdata} || []};
  my $callarg_list = $s->{glewtype} eq 'var' ? "" : "(@{[ join ', ', map $_->[0], @argdata ]})";
  my $thistype = $s->{restype};
  my $isvoid = $thistype eq 'void';
  my @ptr_arg_inds = @{$s->{ptr_args} || []};
  my $c_suffix = @ptr_arg_inds ? '_c' : '';
  my %default = (
    binding_name => $name . $c_suffix,
    xs_rettype => $s->{restype},
    xs_args => join(', ', map $_->[0], @argdata),
    innames => [map "\$$_->[0]", @argdata],
    xs_argdecls => join('', map "  $_->[1]$_->[0];\n", @argdata),
    aliases => [ map "$_$c_suffix", sort keys %{ $s->{aliases} || {} } ],
    xs_code => "CODE:\n",
    error_check => ($name eq "glGetError") ? "" : qq{OGLM_CHECK_ERR("$name", )},
    avail_check => $avail_check,
    beforecall => '',
    retcap => ($isvoid ? '' : 'RETVAL = '),
    retnames => ($isvoid ? [] : ['$retval']),
    callarg_list => $callarg_list,
    error_check2 => ($name eq "glGetError") ? "" : qq{OGLM_CHECK_ERR("$name", )},
    aftercall => '',
    retout => ($isvoid ? '' : "\nOUTPUT:\n  RETVAL"),
  );
  my @ret = \%default;
  my %dynlang = %{ $s->{dynlang} || {} };
  return @ret if !@ptr_arg_inds or !%dynlang;
  my %pbinding = (%default, binding_name => $name . '_p',
    aliases => [ map "${_}_p", sort keys %{ $s->{aliases} || {} } ],
  );
  @ptr_arg_inds = grep $_ >= 0, @ptr_arg_inds;
  my %name2data = map +($_->[0] => $_), @argdata;
  my %name2parsed = map +($_->[0] => parse_ptr($_)), @argdata[@ptr_arg_inds];
  die "$name: undefined dynlang arg '$_'" for grep /^[a-z]/ && !exists $name2data{$_}, keys %dynlang;
  my %this = %pbinding;
  my $cleanup = delete $dynlang{CLEANUP} // '';
  my %indynlang = %dynlang;
  my %is_inarg = map +($_->[0]=>1), @argdata;
  if (my @outaslist = grep $indynlang{$_} =~ /\bOUTASLIST\b/, keys %indynlang) {
    die "$name: >1 OUTASLIST (@outaslist)" if @outaslist > 1;
    die "$name: no OUTASLIST len" unless my ($len) = $indynlang{$outaslist[0]} =~ /\bOUTASLIST:([^\s,]+)/;
    my $parsed = $name2parsed{$outaslist[0]};
    die "$name: no typefunc for $outaslist[0]" unless my $typefunc = typefunc($parsed->[0]);
    my $newfunc = 'newSV' . lc substr $typefunc, 0, 2;
    $dynlang{$outaslist[0]} = "OGLM_ALLOC($len,$parsed->[0],$outaslist[0])";
    $cleanup .= "free($outaslist[0]);";
    $dynlang{OUTPUT} = "OGLM_OUT_FINISH($outaslist[0],$len,$newfunc)";
    $this{retnames} = ["\@$outaslist[0]"];
  }
  my @sized = grep $indynlang{$_} =~ /\bSIZE\b/, keys %indynlang;
  my %arg2lenoverride;
  for my $arg (@sized) {
    die "$name: failed to get SIZE info from '$indynlang{$arg}'" unless
      my ($compsize_group, $compsize_from, $mult) =
        $indynlang{$arg} =~ /\bSIZE:([^:]+):([^,:\s]+)(?::([^,\s]+))?/;
    $mult ||= 1;
    my $parsed = $name2parsed{$arg};
    $arg2lenoverride{$arg} = ["${compsize_from}_count", "OGLM_SIZE_ENUM($compsize_group,$compsize_from,$mult)"];
    $dynlang{$arg} = "OGLM_ALLOC(${compsize_from}_count,$parsed->[0],$arg)";
  }
  die "$name: cannot have both RETVAL and OUTPUT" if $dynlang{OUTPUT} and $dynlang{RETVAL};
  if (my $retval = delete $dynlang{RETVAL}) {
    die "$name: dynlang RETVAL '$retval' not arg to function" if !defined $name2data{$retval};
    if (($name2data{$retval}[2]//'') eq '1') {
      $this{xs_rettype} = $name2parsed{$retval}[0];
      $this{aftercall} = "\n  RETVAL = $retval\[0];";
    } else {
      $this{xs_rettype} = delete $dynlang{RETTYPE} // $name2data{$retval}[1];
      $this{aftercall} = "\n  RETVAL = $retval;";
    }
    $this{retout} = "\nOUTPUT:\n  RETVAL";
    $this{retnames} = ["\$$retval"];
  } elsif (my $output = delete $dynlang{OUTPUT}) {
    $this{aftercall} = "\n  $output";
    $this{xs_code} = "PPCODE:\n";
  } elsif (grep $indynlang{$_} =~ /\bOUT(?:ARRAY|SCALAR)\b/, keys %indynlang) {
    my @retnames = map $indynlang{$_} =~ /\bOUTSCALAR\b/ ? ['$',$_] :
      $indynlang{$_} =~ /\bOUTARRAY\b/ ? ['\\@',$_] :
      (), grep $indynlang{$_}, map $_->[0], @argdata;
    $this{retnames} = [ $isvoid ? () : '$retval', map join('', @$_), @retnames ];
    $this{xs_code} = "PPCODE:\n";
    my $aftercall = "EXTEND(sp, ".(@{ $this{retnames} }).");";
    if (!$isvoid) {
      my $newval = $s->{restype} =~ /^\s*void\s*\*\s*$/ ? "newSViv(PTR2IV(RETVAL))" : "newSV".lc(substr typefunc($s->{restype}), 0, 2)."(RETVAL)";
      $aftercall .= "\n  mPUSHs($newval);";
    }
    for (@retnames) {
      my ($sigil, $arg) = @$_;
      delete $is_inarg{$arg};
      if ($sigil eq '\\@') {
        die "$name: no OUTARRAY len" unless my ($len) = $indynlang{$arg} =~ /\bOUTARRAY:([^\s,]+)/;
        my $parsed = $name2parsed{$arg};
        $dynlang{$arg} = "OGLM_ALLOC($len,$parsed->[0],$arg)";
        my $typefunc = typefunc($name2parsed{$arg}[0]);
        my $newfunc = "newSV".lc(substr $typefunc, 0, 2);
        my $makeav = "OGLM_PUSH_ARRAY($name, $newfunc, $arg, $len)";
        $aftercall .= "\n  $makeav";
        $cleanup .= "free($arg);";
      } else {
        delete $dynlang{$arg};
        my $newval;
        if ($name2parsed{$arg}[0] eq 'void' || is_stringtype($name2data{$arg}[1])) {
          my ($len) = $indynlang{$arg} =~ /\bOUTSCALAR:([^\s,]+)/;
          $len //= 0;
          $newval = "newSVpv($arg,$len)";
        } else {
          my $typefunc = typefunc($name2parsed{$arg}[0]);
          $newval = "newSV".lc(substr $typefunc, 0, 2)."($arg\[0])";
        }
        $aftercall .= "\n  mPUSHs($newval);";
      }
    }
    $this{aftercall} = "\n  $aftercall";
    $this{retout} = "";
  }
  delete @is_inarg{keys %dynlang};
  delete @is_inarg{grep !$name2parsed{$_}[1], keys %name2parsed};
  my %is_inarray;
  for my $arg (sort grep $indynlang{$_} =~ /\bINARRAY:/, keys %indynlang) {
    die "$name: no INARRAY len" unless my ($len) = $indynlang{$arg} =~ /\bINARRAY:([^\s,]+)/;
    $is_inarray{$arg} = $is_inarg{$arg} = 1;
    my $parsed = $name2parsed{$arg};
    my $typefunc = typefunc($parsed->[0]);
    $dynlang{$arg} = "OGLM_GET_ARRAY($arg, $parsed->[0], $typefunc, $len)";
    $cleanup .= "free($arg);";
  }
  my $beforecall = '';
  for my $get (sort grep $dynlang{$_} =~ /^</, keys %dynlang) {
    my $val = delete $dynlang{$get};
    $val =~ s#^<##;
    my ($getfunc) = $val =~ /^(\w+)/;
    $val =~ s#&(?![\{\(a-z])#&$get#;
    my $vardata = $name2data{$get};
    $beforecall .= "  $vardata->[1]$get;\n  $val;\n";
    if (my $glewImpl = $signatures->{$getfunc}{glewImpl}) {
      $this{avail_check} = join "", grep $_, $this{avail_check}, "  OGLM_AVAIL_CHECK($glewImpl, $getfunc)\n";
    }
  }
  for my $len (sort grep $dynlang{$_} =~ /\bLEN:/, keys %dynlang) {
    my $val = delete $dynlang{$len};
    die "$name: failed to parse LEN '$val'" unless my ($varname) = $val =~ /\bLEN:([^,\s]+)/;
    my $vardata = $name2data{$len};
    $beforecall .= "  $vardata->[1]$len = OGLM_LEN_ARRAY($len, $varname);\n";
  }
  my $varargsname;
  if (my @varargs = grep $indynlang{$_} =~ /\bVARARGS\b/, keys %indynlang) {
    die "$name: >1 VARARGS (@varargs)" if @varargs > 1;
    $varargsname = $varargs[0];
    die "$name: failed to parse VARARGS '$dynlang{$varargs[0]}'" unless my ($startfrom, $howmany) = $indynlang{$varargs[0]} =~ /\bVARARGS:(\d+):([^,\s]+)/;
    my $parsed = $name2parsed{$varargs[0]};
    die "$name: no typefunc for $varargs[0] ($parsed->[0])" unless my $typefunc = typefunc($parsed->[0]);
    $dynlang{$varargs[0]} = "OGLM_GET_VARARGS($varargs[0],$startfrom,$parsed->[0],$typefunc,$howmany)";
    $cleanup .= "free($varargs[0]);";
  }
  my @xs_inargs = grep $is_inarg{$_->[0]}, @argdata;
  my $dotdotdot = defined $varargsname;
  $this{xs_args} = join(', ', (map $_->[0].($is_inarray{$_->[0]} ? 'SV' : ''), @xs_inargs), $dotdotdot ? '...' : ());
  $this{xs_argdecls} = join('', map "  ".($is_inarray{$_->[0]} ? 'SV *' : $_->[1])."$_->[0]".($is_inarray{$_->[0]} ? 'SV' : '').";\n", @xs_inargs);
  $this{innames} = [(map +($is_inarray{$_->[0]} ? '\\@' : '$').$_->[0], @xs_inargs), $dotdotdot ? "\@$varargsname" : ()];
  $this{aftercall} .= "\n  $cleanup" if $cleanup;
  $this{error_check2} &&= qq{OGLM_CHECK_ERR("$name", $cleanup)};
  my $need_cast;
  my %gotdynlang = map +($_=>1), keys %dynlang;
  my %hasitems = map +($_=>1), grep $dynlang{$_} =~ /\bitems\b/, keys %dynlang;
  for my $var (
    (sort keys %hasitems),
    (sort grep !$hasitems{$_}, keys %dynlang),
  ) {
    my $val = delete $dynlang{$var};
    die "$name: no arg data found for '$var'" unless my $data = $name2data{$var};
    my $type = $data->[1];
    $need_cast = 1 if $type =~ s#\bconst\b\s*##g;
    $beforecall .= "  $arg2lenoverride{$var}->[1]\n" if $arg2lenoverride{$var};
    $beforecall .= "  $type$var = $val;\n";
  }
  for my $arr (sort grep +($indynlang{$_}//'') =~ /\bOUTSCALAR\b/ || (!$gotdynlang{$_} && !$name2parsed{$_}[1]), keys %name2parsed) {
    my $len = $name2data{$arr}[2] // die "$name: pointer arg without len";
    my $type = $name2parsed{$arr}[0];
    $type = 'char' if $type eq 'void';
    $beforecall .= "  $type $arr\[$len];\n";
  }
  if ($need_cast) {
    $this{callarg_list} = $s->{glewtype} eq 'var' ? "" : "(@{[ join ', ', map qq{($_->[1])$_->[0]}, @argdata ]})";
  }
  $this{beforecall} = $beforecall;
  push @ret, \%this;
  @ret;
}

sub assemble_enum_groups {
  my ($groups, $counts, %g2c2s) = @_;
  for my $g (keys %$groups) {
    my (@syms, %c2s) = @{ $groups->{$g} };
    for (@syms) {
      next if !defined(my $c = $counts->{$_});
      push @{ $c2s{$c} }, $_;
    }
    $g2c2s{$g} = \%c2s if keys %c2s;
  }
  \%g2c2s;
}

1;
