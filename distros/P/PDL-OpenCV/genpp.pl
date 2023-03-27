use strict;
use warnings;
use Config;
use PDL::Types;
use File::Spec::Functions qw(catfile curdir);
use File::Basename 'dirname';
require ''. catfile dirname(__FILE__), 'doxyparse.pl';

our $INT_PDLTYPE = $Config{intsize} == 4 ? 'int' :
  $Config{intsize} == 8 ? 'longlong' :
  die "Unknown intsize $Config{intsize}";
our %REALCTYPE2PDLTYPE = (
  int => PDL::Type->new($INT_PDLTYPE),
  map +($_->realctype=>$_), PDL::Types::types
);
my $T = [qw(A B S U L F D)];
our %type_overrides = (
  String => ['StringWrapper*', 'StringWrapper*'], # PP, C
  bool => ['byte', 'unsigned char'],
  char => ['byte', 'char'],
  uchar => ['byte', 'unsigned char'],
  c_string => ['char *', 'char *'],
  size_t => ['indx', 'size_t'],
  uint64 => ['ulonglong', 'uint64_t'],
  int => [$INT_PDLTYPE, 'int'],
);
our %type_alias = (
  string => 'String',
  HOGDescriptor_HistogramNormType => 'int',
);
$type_overrides{$_} = $type_overrides{$type_alias{$_}} for keys %type_alias;
our %default_overrides = (
  'vector_Mat()' => ['undef',],
  'Mat()' => ['PDL->zeroes(sbyte,0,0,0)',],
  'cv::Mat()' => ['PDL->zeroes(sbyte,0,0,0)',],
  'Ptr<float>()' => ['empty(float)','0'],
  'Scalar::all(0)' => ['[0,0,0,0]',],
  'String()' => ['undef',],
  false => [0,0], # perl, C
  true => [1,1],
);
our %STAYWRAPPED = map +($_=>[]), qw(Mat String DMatch KeyPoint);
our $IF_ERROR_RETURN = "if (CW_err.error) return *(pdl_error *)&CW_err";

{
package PP::OpenCV;
our %DIMTYPES = (
  Point2f=>[map ['float', $_], qw(x y)],
  Point2d=>[map ['double', $_], qw(x y)],
  Point=>[map ['ptrdiff_t', $_], qw(x y)],
  Rect=>[map ['ptrdiff_t', $_], qw(x y width height)],
  Scalar=>[map ['double', "v$_", "val[$_]"], 0..3],
  Size=>[map ['ptrdiff_t', $_], qw(width height)],
  Size2f=>[map ['float', $_], qw(width height)],
  Vec3d=>[map ['double', "v$_", "val[$_]"], 0..2],
  Vec4f=>[map ['float', "v$_", "val[$_]"], 0..3],
  Vec4i=>[map ['ptrdiff_t', "v$_", "val[$_]"], 0..3],
  Vec6f=>[map ['float', "v$_", "val[$_]"], 0..5],
);
my $dimtypes_re = join '|', sort keys %DIMTYPES; $dimtypes_re = qr/$dimtypes_re/;
our %CTYPE2PDL = map +($_->realctype => $_->ppforcetype), PDL::Types::types();
our %FLAG2KEY = ('/IO' => 'is_io', '/O' => 'is_output');
sub new {
  my ($class, $pcount, $type, $name, $default, $f) = @_;
  my %flags = map +($_=>1), grep $_, map $FLAG2KEY{$_}, @{$f||[]};
  my $self = bless {type=>$type, name=>$name, %flags, pcount => $pcount, pdltype => ''}, $class;
  $self->{is_vector} = (my $nonvector_type = $type) =~ s/vector_//g;
  $nonvector_type = $type_alias{$nonvector_type} || $nonvector_type;
  $self->{type_pp} = ($type_overrides{$nonvector_type} || [$nonvector_type])->[0];
  $self->{type_c_underlying} = $self->{type_c} = ($type_overrides{$nonvector_type} || [0,$nonvector_type])->[1];
  $self->{default} = $default if defined $default and length $default;
  @$self{qw(is_other naive_otherpar)} = (1,1), return $self if ($self->{type_c} eq 'char' or $self->{type_c} eq 'char *') and !$self->{is_vector};
  @$self{qw(is_other naive_otherpar use_comp)} = (1,1,1), return $self if $self->{type_c} eq 'StringWrapper*' and !$self->{is_vector};
  my $type_nostar = $type;
  $self->{type_c_underlying} = $self->{type_c} = "$type_nostar *", $self->{type_pp} = $type_nostar, $self->{was_ptr} = 1 if $type_nostar =~ s/\s*\*+$// or $type_nostar =~ s/^Ptr_//;
  $self->{type_nostar} = $type_nostar;
  if ($self->{is_vector}) {
    $self->{fixeddims} = 1 if my $spec = $DIMTYPES{$nonvector_type};
    $self->{use_comp} = 1 if $self->{is_output};
    @$self{qw(pdltype type_c)} = (
      $spec ? $CTYPE2PDL{$self->{type_c_underlying} = $spec->[0][0]} : $self->{type_pp},
      ('vector_'x$self->{is_vector})."${nonvector_type}Wrapper *",
    );
    @$self{qw(is_other naive_otherpar use_comp pdltype)} = (1,1,1,'') if $STAYWRAPPED{$nonvector_type} || $self->{is_vector} > 1;
    return $self;
  } elsif ($self->{type_pp} !~ /^[A-Z]/) {
    ($self->{pdltype} = $self->{type_pp}) =~ s#\s*\*+$##;
    @$self{qw(dimless)} = (1);
    return $self;
  }
  %$self = (%$self,
    type_c => "${type_nostar}Wrapper *",
  );
  if (my $spec = $DIMTYPES{$type_nostar}) {
    $self->{fixeddims} = 1;
    $self->{pdltype} = $CTYPE2PDL{$self->{type_c_underlying} = $spec->[0][0]};
  } elsif ($type ne 'Mat') {
    @$self{qw(is_other use_comp)} = (1,1);
  }
  $self->{use_comp} = 1 if $self->{is_output} and !$self->{fixeddims};
  bless $self, $class;
}
sub isempty {
  my ($self, $compmode) = @_;
  '!'.($compmode ? "$self->{name}->dims[0]" :
    "\$SIZE(@{[$self->{dimless} || $self->{fixeddims} ? 'n' : 'l']}$self->{pcount})");
}
sub dataptr {
  my ($self, $compmode) = @_;
  my $cast = "($self->{type_c_underlying}@{[$self->{was_ptr}?'':'*']})";
  '('.(!$compmode ? "\$P($self->{name})" :
    ($self->{type} eq 'Mat' ? "" : $cast) . "$self->{name}->data"
  ).')';
}
sub c_input {
  my ($self, $compmode, $force_comp) = @_;
  return "\$COMP($self->{name})" if $force_comp and $compmode;
  return $self->isempty($compmode)." ? NULL : ".$self->dataptr($compmode)
    if $self->{was_ptr} and $self->wantempty;
  return ($self->{was_ptr} ? '&' : '').$self->dataptr($compmode).'[0]'
    if $self->{dimless};
  return "\$COMP($self->{name})" if $self->{is_other} || $self->{use_comp};
  $self->{name}.($compmode?'_LOCAL':'');
}
sub par {
  my ($self, $phys) = @_;
  my $flags = ($self->{is_output} || ($self->{is_other} && $self->{is_io})) ? 'o' : $self->{is_io} ? 'io' : '';
  $flags = join ',', grep length, $flags, $phys ? 'phys' : ();
  join ' ', grep length, $self->{pdltype},
    ($flags ? "[$flags]" : ()),
    $self->_par;
}
sub _par {
  my ($self) = @_;
  my ($name, $type, $pcount) = @$self{qw(name type_nostar pcount)};
  return qq{$name(@{[$self->wantempty ? "n$pcount" : ""]})} if $self->{dimless};
  return "@$self{qw(type_c name)}" if $self->{naive_otherpar};
  return "$name(l$pcount,c$pcount,r$pcount)" if $self->{type} eq 'Mat';
  return qq{$name(n$pcount}.($self->wantempty ? '' : '='.scalar(@{$DIMTYPES{$type}})).")"
    if $self->{fixeddims} and !$self->{is_vector};
  return "$name(".join(',',
    (!$self->{fixeddims} ? () : "n$pcount".($self->wantempty ? '' : '='.scalar(@{$DIMTYPES{$self->{type_pp}}}))),
    (map "n${pcount}d$_", 0..$self->{is_vector}-1)).")"
    if $self->{is_vector};
  "@$self{qw(type_c name)}";
}
sub frompdl {
  my ($self, $compmode) = @_;
  die "Called frompdl on OtherPar" if $self->{is_other};
  my ($name, $type, $pcount) = @$self{qw(name type_nostar pcount)};
  return "CW_err = cw_${type}_new(&\$COMP($name), NULL); $IF_ERROR_RETURN;\n" if $compmode and $self->{is_output};
  my $localname = $self->c_input($compmode);
  my $decl = ($compmode && ($self->{use_comp} || $self->{is_other})) ? '' : "$self->{type_c} $localname;\n";
  return $decl.qq{CW_err = cw_${type}_newWithVals(@{[
    join ',', "&$localname", $self->dataptr($compmode),
        $compmode ? "$name->dims[@{[$self->{fixeddims} ? 1 : 0]}]" : "\$SIZE(n${pcount}d0)"
      ]})}."; $IF_ERROR_RETURN;\n" if $self->{is_vector};
  return $decl."CW_err = ".(!$self->wantempty ? '' : $self->isempty($compmode).
    " ? cw_Mat_new(&$localname, NULL) : "
    )."cw_Mat_newWithDims(&$localname," .
    ($compmode
      ? join ',', (map "$name->dims[$_]", 0..2), "$name->datatype"
      : "\$SIZE(l$pcount),\$SIZE(c$pcount),\$SIZE(r$pcount),\$PDL($name)->datatype"
    ) . ','.$self->dataptr($compmode) .
    "); $IF_ERROR_RETURN;\n" if !$self->{fixeddims};
  $decl."CW_err = ".(!$self->wantempty ? '' : $self->isempty($compmode).
    " ? cw_${type}_new(&$localname, NULL) : "
    ).qq{cw_${type}_newWithVals(@{[
      join ',', "&$localname", map $self->dataptr($compmode)."[$_]",
        0..@{$DIMTYPES{$type}}-1
    ]})}."; $IF_ERROR_RETURN;\n";
}
sub topdl1 {
  my ($self, $compmode) = @_;
  die "Called topdl1 on OtherPar" if $self->{is_other};
  my ($name, $type, $pcount) = @$self{qw(name type_nostar pcount)};
  return
    "CW_err = cw_${type}_size(&\$SIZE(n${pcount}d0), ".$self->c_input($compmode)."); $IF_ERROR_RETURN;\n"
    if $self->{is_vector};
  return
    "CW_err = cw_Mat_pdlDims(".$self->c_input($compmode).", &\$PDL($name)->datatype, &\$SIZE(l$pcount), &\$SIZE(c$pcount), &\$SIZE(r$pcount)); $IF_ERROR_RETURN;\n"
    if !$self->{fixeddims};
  "";
}
sub topdl2 {
  my ($self, $compmode) = @_;
  die "Called topdl2 on OtherPar" if $self->{is_other};
  my ($name, $type, $pcount) = @$self{qw(name type_nostar pcount)};
  return <<EOF if $self->{is_vector} or !$self->{fixeddims};
CW_err = cw_${type}_copyDataTo(@{[$self->c_input($compmode)]}, \$P($name), \$PDL($name)->nbytes);
$IF_ERROR_RETURN;
EOF
  qq{CW_err = cw_${type}_getVals(}.$self->c_input($compmode).qq{,@{[join ',', map "&\$$name(n$pcount=>$_)", 0..@{$DIMTYPES{$type}}-1]}); $IF_ERROR_RETURN;\n};
}
sub destroy_code {
  my ($self, $compmode) = @_;
  "cw_$self->{type_nostar}_DESTROY(".$self->c_input($compmode).");\n";
}
sub default_pl {
  my ($self) = @_;
  my $d = $self->{default} // '';
  $d =~ s/[A-Z][A-Z0-9_]+/$&()/g if length $d and $d !~ /\(|::/;
  if ($self->{is_output}) {
    $d = 'PDL->null' if !$self->{is_other} and (!length $d or $d eq 'Mat()' or ($d eq '0' && $self->{was_ptr}));
  }
  if ($default_overrides{$d}) {
    $d = $default_overrides{$d}[0];
  }
  $d =~ s/^std::vector<($dimtypes_re|int)>\(\)$/"empty($REALCTYPE2PDLTYPE{$DIMTYPES{$1} ? $DIMTYPES{$1}[0][0] : $1})"/e;
  $d =~ s/^($dimtypes_re)\(\)$/"empty($REALCTYPE2PDLTYPE{$DIMTYPES{$1}[0][0]})"/e;
  $d =~ s/^($dimtypes_re)(\(.*\))$/$REALCTYPE2PDLTYPE{$DIMTYPES{$1}[0][0]}.$2/e;
  $d =~ s/([A-Za-z0-9_:]+::[A-Za-z_][A-Za-z0-9_]+)/PDL::OpenCV::$1()/g;
  $d =~ s/^(TermCriteria)(\(.*\))$/"PDL::OpenCV::$1->new".(length $2 == 2 ? '' : '2').$2/e;
  length $d ? "\$$self->{name} = $d if !defined \$$self->{name};" : ();
}
sub xs_par {
  my ($self) = @_;
  my $xs_par = ($self->{type} =~ /^[A-Z]/ && $self->{is_other}) ? $self->par : "@$self{qw(type_c name)}";
  my $d = $self->{default} // '';
  $d = $default_overrides{$d}[1] if $default_overrides{$d};
  $d = 'cw_const_' . $d . '()' if length $d and $d !~ /\(/ and $d =~ /[^0-9\.\-]/ and ($d =~ s/::/_/g or 1);
  $xs_par . (length $d ? "=$d" : '');
}
sub cdecl {
  my ($self) = @_;
  ($self->{use_comp} ? $self->{type_c} : PDL::Type->new($self->{type_pp})->ctype)." $self->{name}";
}
sub wantempty { ($_[0]->default_pl // return 0) =~ /empty\(|zeroes\(.*,0/ }
}

sub text_trim {
  my ($text) = @_;
  $text =~ s/\s+$/\n/gm;
  $text =~ s/\n{3,}/\n\n/g;
  $text;
}

sub make_example {
  my ($class, $func, $ismethod, $inputs, $outputs, $objname, $suppress_only) = @_;
  $inputs = [@$inputs[1..$#$inputs]] if $ismethod;
  my $out = "\n\n=for example\n\n";
  for my $suppress_default ($suppress_only ? 1 : (1,0)) {
    my $this_in = $inputs;
    $this_in = [grep !length($_->{default}//''), @$this_in] if $suppress_default;
    next if $suppress_default and !$suppress_only and @$this_in == @$inputs;
    $out .= ' '.
      (!@$outputs ? '' : @$outputs == 1 ? qq{\$$outputs->[0]{name} = } : "(@{[join ',', map qq{\$$_->{name}}, @$outputs]}) = ").
      ($ismethod ? ($objname||'$obj').'->' : $class ? "PDL::OpenCV::${class}::" : '')."$func".
      (@$this_in ? '('.join(',', map "\$$_->{name}", @$this_in).')' : '').
      ";".(($suppress_default and !$suppress_only) ? ' # with defaults' : '')."\n";
  }
  $out."\n";
}

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,@params) = @_;
    die "No class given for func='$func' method='$ismethod'" if !$class and $ismethod;
    my %hash = (NoPthread=>1, HandleBad=>0);
    my $doxy = doxyparse($doc);
    my $pcount = 1;
    $func = $func->[1] if ref $func;
    my $cfunc = join('_', 'cw', my $pfunc = join '_', grep length,$class,$func);
    unshift @params, [$class,'self'] if $ismethod;
    push @params, [$ret,'res','',['/O']] if $ret ne 'void';
    my @allpars = map PP::OpenCV->new($pcount++, @$_), @params;
    my (@inputs, @outputs); push @{$_->{is_output} ? \@outputs : \@inputs}, $_ for @allpars;
    $hash{PMFunc} = $class ? '' : "*$func = \\&${main::PDLOBJ}::$func;\n";
    my $ex_doc = $func =~ /^new\d*$/
      ? make_example($class, $func, 1, \@inputs, [{name=>'obj'}], "PDL::OpenCV::$class")
      : make_example($class, $func, $ismethod, \@inputs, \@outputs);
    if (!grep $_->{is_vector} || ($_->{type_pp} =~ /^[A-Z]/ && !$_->{is_other}), @allpars) {
      $doxy->{brief}[0] .= $ex_doc;
      $hash{Doc} = text_trim doxy2pdlpod($doxy);
      pp_addpm("=head2 $func\n\n$hash{Doc}\n\n=cut\n\n");
      pp_addpm($hash{PMFunc}) if $hash{PMFunc};
      my $ret_type = $ret eq 'void' ? $ret : pop(@allpars)->{type_c};
      my @cw_params = (($ret ne 'void' ? '&RETVAL' : ()), map $_->{name}, @allpars);
      my $xs = <<EOF;
MODULE = ${main::PDLMOD} PACKAGE = ${main::PDLOBJ} PREFIX=@{[join '_', grep length,'cw',$class]}_
\n$ret_type $cfunc(@{[join ', ', map $_->xs_par, @allpars]})
  PROTOTYPE: DISABLE
  CODE:
    cw_error CW_err = $cfunc(@{[join ', ', @cw_params]});
    PDL->barf_if_error(*(pdl_error *)&CW_err);
EOF
      $xs .= "  OUTPUT:\n    RETVAL\n" if $ret_type ne 'void';
      pp_addxs($xs);
      return;
    }
    my @defaults = map $_->default_pl, @allpars;
    my (@pars, @otherpars); push @{$_->{is_other} ? \@otherpars : \@pars}, $_ for @allpars;
    my @pdl_inits = grep !$_->{dimless}, @pars;
    my $compmode = grep $_->{use_comp}, @pdl_inits;
    my $destroy_in = join '', map $_->destroy_code($compmode), grep !$_->{is_output}, @pdl_inits;
    my $destroy_out = join '', map $_->destroy_code($compmode), grep $_->{is_output}, @pdl_inits;
    my @nonfixed_outputs = grep $_->{is_output}, @pdl_inits;
    (my $ret_obj) = pop @allpars if my $retcapture = $ret eq 'void' ? '' : ($ret =~ /^[A-Z]/ ? 'res' : '$res()');
    %hash = (%hash,
      Pars => join('; ', map $_->par(1), @pars), OtherPars => join('; ', map $_->par, @otherpars),
      GenericTypes=>(grep !$_->{pdltype}, @pars) ? $T : ['D'],
      PMCode => <<EOF,
sub ${main::PDLOBJ}::$func {
  barf "Usage: ${main::PDLOBJ}::$func(@{[join ',', map "\\\$$_->{name}", @inputs]})\\n" if \@_ < @{[0+(grep !defined $_->{default} || !length $_->{default}, @inputs)]};
@{[!@inputs ? () : qq{  my (@{[join ',', map "\$$_->{name}", @inputs]}) = \@_;\n}
]}  @{[!@outputs ? '' : "my (@{[join ',', map qq{\$$_->{name}}, @outputs]});\n"
]}  @{[ join "\n  ", @defaults ]}
  ${main::PDLOBJ}::_${pfunc}_int(@{[join ',', map '$'.$_->{name}, @pars, @otherpars]});
  @{[!@outputs ? '' : "!wantarray ? \$$outputs[-1]{name} : (@{[join ',', map qq{\$$_->{name}}, @outputs]})"]}
}
EOF
      ($compmode ? 'MakeComp' : 'Code') => join('',
        "cw_error CW_err;\n",
        !$compmode ? () : (map "PDL_RETERROR(PDL_err, PDL->make_physical($_->{name}));\n", @pars),
        (map $_->frompdl($compmode), @pdl_inits),
        (!@pdl_inits ? () : qq{if (@{[join ' || ', map "!".$_->c_input($compmode), @pdl_inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        "CW_err = $cfunc(".join(',',
          ($retcapture ? "&".$ret_obj->c_input($compmode, 1) : ()),
          map $_->c_input($compmode), @allpars
        ).");\n",
        !$compmode ? (map $_->topdl2(0), @nonfixed_outputs) : (),
        $destroy_in, !$compmode ? ($destroy_out) : (),
        "$IF_ERROR_RETURN;\n",
      ),
    );
    $doxy->{brief}[0] .= " NO BROADCASTING." if $compmode;
    $doxy->{brief}[0] .= $ex_doc;
    $hash{Doc} = text_trim doxy2pdlpod($doxy);
    if ($compmode) {
      $hash{Comp} = join '; ', map $_->cdecl, grep !$_->{is_other}, @outputs;
      $hash{CompFreeCodeComp} = $destroy_out;
      $hash{RedoDimsCode} = join '', "cw_error CW_err;\n", map $_->topdl1(1), @nonfixed_outputs;
      $hash{Code} = join '', "cw_error CW_err;\n", map $_->topdl2(1), @nonfixed_outputs;
      $hash{Code} .= "$retcapture = \$COMP(res);\n" if $ret_obj and !$ret_obj->{use_comp} and $ret !~ /^[A-Z]/;
    }
    pp_def($pfunc, %hash);
}

sub maybe_suffix {
  my ($suffixh, $class, $name, @rest) = @_;
  ($class,
    ref($name) ? $name : [
      !$rest[1] ? join('::', grep length, "cv", $class, $name) : $name,
      $name.($suffixh->{$class}{$name}++ ? $suffixh->{$class}{$name} : '')],
    @rest
  );
}

sub genheader {
  my ($last, $suppress_pmheader) = @_;
  my $lastorig = $last;
  $last &&= "::$last";
  local $@; my @classdata = !-f 'classes.pl' ? () : do ''. catfile curdir, 'classes.pl'; die if $@;
  my %class2super = map +($_->[0]=>[map "PDL::OpenCV::$_", @{$_->[1]}]), @classdata;
  my %class2doc = map +($_->[0]=>$_->[2]), @classdata;
  my %class2info = map +($_->[0]=>[@$_[4..$#$_]]), @classdata;
  my @classes = sort keys %class2doc;
  if (@classes) {
    require ExtUtils::Typemaps;
    my $tm = ExtUtils::Typemaps->new;
    $tm->add_typemap(ctype => "${_}Wrapper *", xstype => 'T_PTROBJ_SPECIAL') for @classes;
    pp_add_typemaps(typemap => $tm);
  }
  my $descrip_label = @classes ? join(', ', @classes) : $lastorig;
  pp_addpm({At=>'Top'},<<"EOPM") if !$suppress_pmheader;
=head1 NAME
\nPDL::OpenCV$last - PDL bindings for OpenCV $descrip_label
\n=head1 SYNOPSIS
\n use PDL::OpenCV$last;
\n=cut
\nuse strict;
use warnings;
use PDL::OpenCV; # get constants
EOPM
  pp_addhdr(qq{#include "opencv_wrapper.h"\n#include "wraplocal.h"\n});
  my @flist = genpp_readfile('funclist.pl');
  my @topfuncs = grep $_->[0] eq '', @flist;
  my %class2func2suffix;
  if (@topfuncs) {
    pp_bless("PDL::OpenCV$last");
    pp_addxs(<<EOF); # work around PP bug
MODULE = ${main::PDLMOD} PACKAGE = ${main::PDLOBJ}
EOF
    genpp(maybe_suffix \%class2func2suffix, @$_) for @topfuncs;
  } else {
    pp_addpm("=pod\n\nNone.\n\n=cut\n\n");
  }
  for my $c (@classes) {
    pp_bless(my $fullclass = "PDL::OpenCV::$c");
    pp_addxs(<<EOF); # work around PP bug
MODULE = ${main::PDLMOD} PACKAGE = ${main::PDLOBJ}
EOF
    my $doc = $class2doc{$c} // '';
    $doc = text_trim doxy2pdlpod(doxyparse($doc)) if $doc;
    pp_addpm(<<EOD);
=head1 METHODS for $fullclass\n\n
$doc\n\n@{[@{$class2super{$c}} ? "Subclass of @{$class2super{$c}}\n\n" : '']}
=cut\n
\@${fullclass}::ISA = qw(@{$class2super{$c}});
EOD
    if ($class2info{$c}[0]) {
      my $cons_info = ($class2info{$c}||[])->[1] || [[[], "\@brief Initialize OpenCV $c object."]];
      for my $tuple (@$cons_info) {
        my ($extra_args, $cons_doc) = @$tuple;
        genpp(maybe_suffix \%class2func2suffix, $c, 'new', $cons_doc, 0, $c, ['char *', 'klass'], @$extra_args);
      }
    }
    genpp(maybe_suffix \%class2func2suffix, @$_) for grep $_->[0] eq $c, @flist;
  }
  pp_export_nothing();
  %class2func2suffix = ();
  pp_add_exported(map ref($_->[1])?$_->[1][1]:$_->[1], map [maybe_suffix \%class2func2suffix, @$_], grep !$_->[0], @flist);
  genconsts($last);
}

sub genconsts {
  my ($last) = @_;
  return if !-f 'constlist.txt';
  open my $consts, '<', 'constlist.txt' or die "constlist.txt: $!";
  my %pkgsuff2defs;
  while (!eof $consts) {
    chomp(my $line = <$consts>);
    $line =~ s/^cv:://;
    my ($text, $args) = split /\|/, $line;
    pp_add_exported($text) if $text !~ /(.*)::/;
    my $pkgsuff = $1 || '';
    $pkgsuff2defs{$pkgsuff} ||= ['',''];
    $pkgsuff2defs{$pkgsuff}[1] .= "=item PDL::OpenCV$last\::$text(@{[$args || '']})\n\n";
    $text =~ s/::/_/g;
    $pkgsuff2defs{$pkgsuff}[0] .= "\nint cw_const_$text(@{[$args || '']})\n";
  }
  my $pod = "=head1 CONSTANTS\n\n=over\n\n";
  for my $key (sort keys %pkgsuff2defs) {
    my $pkg = join '::', grep length, "PDL::OpenCV$last", $key;
    my $pref = join '_', (grep length, "cw_const", $key), '';
    pp_addxs(<<EOF);
MODULE = ${main::PDLMOD} PACKAGE = $pkg PREFIX=$pref
$pkgsuff2defs{$key}[0]
EOF
    $pod .= $pkgsuff2defs{$key}[1];
  }
  pp_addpm("$pod\n=back\n\n=cut\n\n");
}

sub genpp_readfile {
  my ($file) = @_;
  my @flist = do ''. catfile curdir, $file;
  die if $@;
  @flist;
}

1;
