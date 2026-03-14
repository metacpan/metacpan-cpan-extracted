use strict;
use warnings;
use OpenGL::Modern::Registry;
use OpenGL::Misc;

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
  GLenum => 'IV',
);
sub typefunc {
  my ($type) = @_;
  $type2func{$type};
}

our %signature;
*signature = \%OpenGL::Modern::Registry::registry;

my $g2c2s = assemble_enum_groups(\%OpenGL::Modern::Registry::groups, \%OpenGL::Modern::Registry::counts);
sub generate_packed_xs {
  my $content;
  for (@_) {
    my ($gen_name, $official_name) = @$_;
    my $item = $signature{$official_name};
    for my $s (bindings($gen_name, $item, $g2c2s, \%signature)) {
      die "Error generating for $gen_name: no return type" if !$s->{xs_rettype};
      my $res = "";
      my $add_ifdef = $item->{feature} && $item->{feature} ne 'GL_VERSION_1_1';
      my $feature = ($item->{aliases} && $item->{aliases}{$gen_name}) || $item->{feature};
      $res .= "#ifdef $feature\n\n" if $add_ifdef;
      $res .= "$s->{xs_rettype}\n$s->{binding_name}($s->{xs_args})\n";
      $res .= $s->{xs_argdecls};
      $res .= "INIT:\n$s->{avail_check}" if $s->{avail_check};
      $res .= $s->{xs_code};
      $res .= "  $s->{error_check}\n" if $s->{error_check};
      $res .= $s->{beforecall};
      $res .= "  $s->{retcap}$gen_name$s->{callarg_list};";
      $res .= "\n  $s->{error_check2}" if $s->{error_check2};
      $content .= "$res$s->{aftercall}$s->{retout}\n\n";
      $content .= "#endif\n\n" if $add_ifdef;
    }
  }
  $content;
}

my @filtered = sort {$a->[0] cmp $b->[0] } map {
  (my $t = $_) =~ s#_s$##;
  (my $noARB = $t) =~ s#(?:ARB|EXT)$##;
  my $official_name = $signature{$t}{dynlang} ? $t :
    $signature{$noARB}{dynlang} ? $noARB :
    undef;
  $official_name ? [$t, $official_name] : ()
} @OpenGL::Misc::extra_gl_func;
my $xs_code = generate_packed_xs(@filtered);
save_file('auto-xs.inc', $xs_code);

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
    ? "  loadProc($name,\"$name\");\n"
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
    avail_check => $avail_check,
    beforecall => '',
    retcap => ($isvoid ? '' : 'RETVAL = '),
    retnames => ($isvoid ? [] : ['$retval']),
    callarg_list => $callarg_list,
    aftercall => '',
    retout => ($isvoid ? '' : "\nOUTPUT:\n  RETVAL"),
  );
  my @ret;
  my %dynlang = %{ $s->{dynlang} || {} };
  die "$name: no pointers or dynlang" if !@ptr_arg_inds or !%dynlang;
  my %pbinding = (%default, binding_name => $name . '_s',
    aliases => [ map "${_}_p", sort keys %{ $s->{aliases} || {} } ],
  );
  @ptr_arg_inds = grep $_ >= 0, @ptr_arg_inds;
  my %name2data = map +($_->[0] => $_), @argdata;
  my %name2parsed = map +($_->[0] => parse_ptr($_)), @argdata[@ptr_arg_inds];
  die "$name: undefined dynlang arg '$_'" for grep /^[a-z]/ && !exists $name2data{$_}, keys %dynlang;
  my %this = %pbinding;
  if (my $retval = delete $dynlang{RETVAL}) {
    $dynlang{$retval} = "OUTSCALAR";
  }
  delete @dynlang{grep !$name2parsed{$_}, keys %dynlang};
  $dynlang{$_} = 'OUTSCALAR'
    for grep +(!$dynlang{$_} || $dynlang{$_} eq 'NULL') && $name2data{$_}[2] == 1, keys %name2parsed;
  my %indynlang = %dynlang;
  my %is_array;
  if (my @outaslist = grep $indynlang{$_} =~ /\bOUTASLIST\b/, keys %indynlang) {
    die "$name: >1 OUTASLIST (@outaslist)" if @outaslist > 1;
    die "$name: no OUTASLIST len" unless my ($len) = $indynlang{$outaslist[0]} =~ /\bOUTASLIST:([^\s,]+)/;
    $is_array{$outaslist[0]} = 1;
    my $parsed = $name2parsed{$outaslist[0]};
    $dynlang{$outaslist[0]} = "EL($outaslist[0], sizeof($parsed->[0])*$len)";
  }
  my @sized = grep $indynlang{$_} =~ /\bSIZE\b/, keys %indynlang;
  my %arg2lenoverride;
  for my $arg (@sized) {
    $is_array{$arg} = 1;
    die "$name: failed to get SIZE info from '$indynlang{$arg}'" unless
      my ($compsize_group, $compsize_from, $mult) =
        $indynlang{$arg} =~ /\bSIZE:([^:]+):([^,:\s]+)(?::([^,\s]+))?/;
    $mult ||= 1;
    my $parsed = $name2parsed{$arg};
    $arg2lenoverride{$arg} = [
      "${compsize_from}_count",
      "int ${compsize_from}_count = gl_${compsize_group}_count($compsize_from);\n  if (${compsize_from}_count < 0) croak(\"Unknown $compsize_group parameter\");",
    ];
    $dynlang{$arg} = "EL($arg, sizeof($parsed->[0])*${compsize_from}_count)";
  }
  if (grep $indynlang{$_} =~ /\bOUT(?:ARRAY|SCALAR)\b/, keys %indynlang) {
    my @retnames = map $indynlang{$_} =~ /\bOUTSCALAR\b/ ? ['$',$_] :
      $indynlang{$_} =~ /\bOUTARRAY\b/ ? ['\\@',$_] :
      (), grep $indynlang{$_}, map $_->[0], @argdata;
    for (@retnames) {
      my ($sigil, $arg) = @$_;
      $is_array{$arg} = 1;
      my ($parsed, $len) = ($name2parsed{$arg}, $name2data{$arg}[2]);
      if ($sigil eq '\\@') {
        die "$name: no OUTARRAY len" unless ($len) = $indynlang{$arg} =~ /\bOUTARRAY:([^\s,]+)/;
      }
      $dynlang{$arg} = "EL($arg, sizeof($parsed->[0])*$len)";
    }
  }
  for my $arg (sort grep $indynlang{$_} =~ /\b(?:VARARGS|INARRAY):/, keys %indynlang) {
    my ($len) = $indynlang{$arg} =~ /\bVARARGS:[^:]+:([^\s,]+)/;
    if (!defined $len) {
      ($len) = $indynlang{$arg} =~ /\bINARRAY:([^\s,]+)/;
    }
    die "$name: couldn't get len from INARRAY|VARARGS" unless defined $len;
    $is_array{$arg} = 1;
    my $parsed = $name2parsed{$arg};
    my $typefunc = typefunc($parsed->[0]);
    $dynlang{$arg} = "EL($arg, sizeof($parsed->[0])*$len)";
  }
  my $beforecall = '';
  for my $len (sort grep $dynlang{$_} =~ /\bLEN:/, keys %dynlang) {
    my $val = delete $dynlang{$len};
  }
  $this{xs_argdecls} = join('', map "  ".($is_array{$_->[0]} ? 'SV *' : $_->[1])."$_->[0]\n", @argdata);
  $this{callarg_list} = "(@{[ join ', ', map $_->[0].($is_array{$_->[0]} ? '_s' : ''), @argdata ]})";
  my %gotdynlang = map +($_=>1), keys %dynlang;
  for my $var (
    grep exists $dynlang{$_}, map $_->[0], @argdata
  ) {
    my $val = delete $dynlang{$var};
    die "$name: no arg data found for '$var'" unless my $data = $name2data{$var};
    my $type = $data->[1];
    $beforecall .= "  $arg2lenoverride{$var}->[1]\n" if $arg2lenoverride{$var};
    my $_s = $is_array{$var} ? '_s' : '';
    $beforecall .= "  $type$var$_s = $val;\n";
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
