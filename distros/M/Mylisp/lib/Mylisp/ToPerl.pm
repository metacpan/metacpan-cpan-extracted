package Mylisp::ToPerl;

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(AstToPerl);

use Mylisp::Builtin;
use Mylisp::Estr;
use Mylisp::LintMyAst;

sub AstToPerl {
  my ($t,$ast) = @_;
  my $head_str = get_perl_head_str($t,$ast);
  my $exprs_str = exprs_to_perl($t,$ast);
  my $perl_str = add($head_str,$exprs_str,"\n1;");
  $t->{'count'} = 0;
  return $perl_str;
}

sub get_perl_head_str {
  my ($t,$exprs) = @_;
  my $names = [];
  my $head_str = '';
  for my $expr (@{atoms($exprs)}) {
    my ($name,$value) = flat($expr);
    given ($name) {
      when ('package') {
        InContext($t,$value);
        $head_str = package_to_perl($value);
      }
      when ('func') {
        apush($names,name(first(atoms($value))));
      }
    }
  }
  my $export_str = get_export_str($t,$names);
  return add($head_str,$export_str);
}

sub package_to_perl {
  my $ns = shift;
  my $package_str = "package $ns;\n";
  my $head_str = <<'EOF'

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA = qw(Exporter);
EOF
;;
  return add($package_str,$head_str);
}

sub get_export_str {
  my ($t,$names) = @_;
  my $sym_names = [ map { sym_to_perl($_) } @{$names} ];
  my $ns = Context($t);
  if (not(end_with($ns,'Estr'))) {
    $sym_names = [ grep { is_exported($_) } @{$sym_names} ];
  }
  my $names_str = ajoin(' ',$sym_names);
  return add('our @EXPORT = qw(',"$names_str);\n");
}

sub is_exported {
  my $name = shift;
  return is_upper(first_char($name));
}

sub exprs_to_perl {
  my ($t,$atoms) = @_;
  my $strs = atoms_to_perl_strs($t,$atoms);
  return ajoin("\n",$strs);
}

sub atoms_to_perl_strs {
  my ($t,$atoms) = @_;
  my $strs = [];
  for my $atom (@{atoms($atoms)}) {
    apush($strs,atom_to_perl($t,$atom));
  }
  return $strs;
}

sub atom_to_perl {
  my ($t,$atom) = @_;
  my ($name,$args) = flat($atom);
  given ($name) {
    when ('Cursor') {
      return exprs_to_perl($t,$args);
    }
    when ('Lint') {
      return exprs_to_perl($t,$args);
    }
    when (':ocall') {
      return ocall_to_perl($t,$args);
    }
    when ('Aindex') {
      return aindex_to_perl($t,$args);
    }
    when ('Arange') {
      return arange_to_perl($t,$args);
    }
    when ('while') {
      return while_to_perl($t,$args);
    }
    when ('for') {
      return for_to_perl($t,$args);
    }
    when ('given') {
      return given_to_perl($t,$args);
    }
    when ('when') {
      return when_to_perl($t,$args);
    }
    when ('then') {
      return then_to_perl($t,$args);
    }
    when ('if') {
      return if_to_perl($t,$args);
    }
    when ('elif') {
      return elif_to_perl($t,$args);
    }
    when ('else') {
      return else_to_perl($t,$args);
    }
    when ('func') {
      return func_to_perl($t,$args);
    }
    when ('my') {
      return my_to_perl($t,$args);
    }
    when ('our') {
      return our_to_perl($t,$args);
    }
    when ('const') {
      return const_to_perl($t,$args);
    }
    when ('return') {
      return return_to_perl($t,$args);
    }
    when ('Array') {
      return array_to_perl($t,$args);
    }
    when ('Hash') {
      return hash_to_perl($t,$args);
    }
    when ('exists') {
      return exists_to_perl($t,$args);
    }
    when ('==') {
      return eq_to_perl($t,$args);
    }
    when ('!=') {
      return ne_to_perl($t,$args);
    }
    when ('<=') {
      return le_to_perl($t,$args);
    }
    when ('>=') {
      return ge_to_perl($t,$args);
    }
    when ('>') {
      return gt_to_perl($t,$args);
    }
    when ('<') {
      return lt_to_perl($t,$args);
    }
    when ('String') {
      return string_to_perl($args);
    }
    when ('use') {
      return use_to_perl($args);
    }
    when ('Lstr') {
      return lstr_to_perl($args);
    }
    when ('Str') {
      return str_to_perl($args);
    }
    when ('Bool') {
      return bool_to_perl($args);
    }
    when ('Sym') {
      return sym_to_perl($args);
    }
    when ('Char') {
      return char_to_perl($args);
    }
    when ('Int') {
      return $args;
    }
    when ('package') {
      return '';
    }
    when ('struct') {
      return '';
    }
    default {
      return oper_to_perl($t,$name,$args);
    }
  }
}

sub ocall_to_perl {
  my ($t,$sym_call) = @_;
  my ($sym,$call) = flat($sym_call);
  if (IsDefine($t,$call)) {
    my $call_name = name_to_perl($call);
    return "$call_name($sym)";
  }
  return add($sym,"->{'$call'}");
}

sub arange_to_perl {
  my ($t,$args) = @_;
  my ($sym,$range) = match($args);
  my $type = GetAtomType($t,$sym);
  my $range_strs = atoms_to_perl_strs($t,$range);
  my $range_str = ajoin(',',$range_strs);
  my $sym_str = atom_to_perl($t,$sym);
  if ($type eq 'Str') {
    return "substr($sym_str, $range_str)";
  }
  return "subarray($sym_str, $range_str)";
}

sub aindex_to_perl {
  my ($t,$args) = @_;
  my ($sym,$indexs) = match($args);
  my $type = GetAtomType($t,$sym);
  if ($type eq 'Str') {
    return index_str_to_perl($t,$args);
  }
  my $indexs_strs = indexs_to_perls($t,$indexs);
  my $index_str = to_str($indexs_strs);
  my $sym_str = sym_to_perl(value($sym));
  return add($sym_str,"->$index_str");
}

sub indexs_to_perls {
  my ($t,$indexs) = @_;
  my $strs = [];
  for my $index (@{atoms($indexs)}) {
    my $type = GetAtomType($t,$index);
    my $index_str = atom_to_perl($t,$index);
    if ($type eq 'Int') {
      apush($strs,"[$index_str]");
    }
    else {
      apush($strs,"{$index_str}");
    }
  }
  return $strs;
}

sub index_str_to_perl {
  my ($t,$args) = @_;
  my ($sym,$index) = flat($args);
  my $name = atom_to_perl($t,$sym);
  my $index_str = atom_to_perl($t,$index);
  return "substr($name, $index_str, 1)";
}

sub while_to_perl {
  my ($t,$args) = @_;
  my $str = cond_block_to_perl($t,$args);
  my $indent = GetIndent($t);
  return add($indent,"while $str");
}

sub cond_block_to_perl {
  my ($t,$args) = @_;
  my ($cond,$exprs) = match($args);
  my $cond_str = atom_to_perl($t,$cond);
  my $exprs_str = block_to_perl($t,$exprs);
  return "($cond_str) $exprs_str";
}

sub block_to_perl {
  my ($t,$exprs) = @_;
  InBlock($t);
  my $strs = atoms_to_perl_strs($t,$exprs);
  OutBlock($t);
  my $str = ajoin("\n",$strs);
  my $indent = GetIndent($t);
  return "{\n$str\n$indent}";
}

sub for_to_perl {
  my ($t,$args) = @_;
  my ($iter_expr,$exprs) = match($args);
  my $iter_str = iter_to_perl($t,$iter_expr);
  my $exprs_str = block_to_perl($t,$exprs);
  my $indent = GetIndent($t);
  return add($indent,"for $iter_str $exprs_str");
}

sub iter_to_perl {
  my ($t,$expr) = @_;
  my ($loop,$iter_atom) = flat($expr);
  my $iter = value($iter_atom);
  if ($iter eq '@args') {
    return "my $loop ($iter)";
  }
  my $iter_str = atom_to_perl($t,$iter_atom);
  my $type = GetAtomType($t,$iter_atom);
  given ($type) {
    when ('Str') {
      return "my $loop (split '', $iter_str)";
    }
    when ('Table') {
      return "my $loop (keys \%{$iter_str})";
    }
    default {
      return "my $loop (\@{$iter_str})";
    }
  }
}

sub given_to_perl {
  my ($t,$args) = @_;
  my $str = cond_block_to_perl($t,$args);
  my $indent = GetIndent($t);
  return add($indent,"given $str");
}

sub when_to_perl {
  my ($t,$args) = @_;
  my $str = cond_block_to_perl($t,$args);
  my $indent = GetIndent($t);
  return add($indent,"when $str");
}

sub then_to_perl {
  my ($t,$args) = @_;
  my $str = block_to_perl($t,$args);
  my $indent = GetIndent($t);
  return add($indent,"default $str");
}

sub if_to_perl {
  my ($t,$exprs) = @_;
  my $str = cond_block_to_perl($t,$exprs);
  my $indent = GetIndent($t);
  return add($indent,"if $str");
}

sub elif_to_perl {
  my ($t,$exprs) = @_;
  my $str = cond_block_to_perl($t,$exprs);
  my $indent = GetIndent($t);
  return add($indent,"elsif $str");
}

sub else_to_perl {
  my ($t,$exprs) = @_;
  my $str = block_to_perl($t,$exprs);
  my $indent = GetIndent($t);
  return add($indent,"else $str");
}

sub func_to_perl {
  my ($t,$atoms) = @_;
  my ($args,$rest) = match($atoms);
  my $exprs = erest($rest);
  my ($call,$func_args) = flat($args);
  my $args_str = args_to_perl($t,$func_args);
  InFunc($t,$call);
  my $exprs_str = exprs_to_perl($t,$exprs);
  OutBlock($t);
  my $name = sym_to_perl($call);
  return "\nsub $name {\n$args_str$exprs_str\n}";
}

sub args_to_perl {
  my ($t,$args) = @_;
  if (is_blank($args)) {
    return '';
  }
  my $strs = [ map { sym_to_perl($_) } @{[ map { name($_) } @{atoms($args)} ]} ];
  my $str = ajoin(',',$strs);
  if (len($strs) == 1) {
    if ($str eq '@args') {
      return "  my $str = \@_;\n";
    }
    return "  my $str = shift;\n";
  }
  return "  my ($str) = \@_;\n";
}

sub my_to_perl {
  my ($t,$args) = @_;
  my ($sym,$value) = flat($args);
  my $value_str = atom_to_perl($t,$value);
  my $name = atom_to_perl($t,$sym);
  my $indent = GetIndent($t);
  return add($indent,"my $name = $value_str;");
}

sub our_to_perl {
  my ($t,$args) = @_;
  my ($slist,$value) = flat($args);
  my $names = atoms_to_perl_strs($t,value($slist));
  my $slist_str = ajoin(',',$names);
  my $value_str = atom_to_perl($t,$value);
  my $indent = GetIndent($t);
  return add($indent,"my ($slist_str) = $value_str;");
}

sub const_to_perl {
  my ($t,$args) = @_;
  my $strs = atoms_to_perl_strs($t,$args);
  my $str = ajoin(' = ',$strs);
  my $indent = GetIndent($t);
  return add($indent,"our $str");
}

sub return_to_perl {
  my ($t,$args) = @_;
  my $strs = atoms_to_perl_strs($t,$args);
  my $str = ajoin(',',$strs);
  my $indent = GetIndent($t);
  return add($indent,"return $str;");
}

sub array_to_perl {
  my ($t,$array) = @_;
  my $atoms = atoms_to_perl_strs($t,$array);
  my $atoms_str = ajoin(',',$atoms);
  return "[$atoms_str]";
}

sub hash_to_perl {
  my ($t,$pairs) = @_;
  my $strs = [];
  for my $pair (@{atoms($pairs)}) {
    my ($key,$value) = flat($pair);
    my $key_str = str_to_perl($key);
    my $value_str = atom_to_perl($t,$value);
    apush($strs,add($key_str,' => ',$value_str));
  }
  my $str = ajoin(',',$strs);
  return "{$str}";
}

sub exists_to_perl {
  my ($t,$args) = @_;
  my ($map,$keys) = match($args);
  my $map_str = atom_to_perl($t,$map);
  my $keys_str = keys_to_perl($t,$keys);
  return "exists $map_str\->$keys_str";
}

sub keys_to_perl {
  my ($t,$keys) = @_;
  my $strs = atoms_to_perl_strs($t,$keys);
  my $keys_strs = [ map { key_to_perl($_) } @{$strs} ];
  return to_str($keys_strs);
}

sub key_to_perl {
  my $key = shift;
  return "{$key}";
}

sub eq_to_perl {
  my ($t,$args) = @_;
  my $first = first(atoms($args));
  my $strs = atoms_to_perl_strs($t,$args);
  my $type = GetAtomType($t,$first);
  if ($type eq 'Str') {
    return ajoin(' eq ',$strs);
  }
  return ajoin(' == ',$strs);
}

sub ne_to_perl {
  my ($t,$args) = @_;
  my $first = first(atoms($args));
  my $strs = atoms_to_perl_strs($t,$args);
  my $type = GetAtomType($t,$first);
  if ($type eq 'Str') {
    return ajoin(' ne ',$strs);
  }
  return ajoin(' != ',$strs);
}

sub le_to_perl {
  my ($t,$args) = @_;
  my $first = first(atoms($args));
  my $strs = atoms_to_perl_strs($t,$args);
  my $type = GetAtomType($t,$first);
  if ($type eq 'Str') {
    return ajoin(' le ',$strs);
  }
  return ajoin(' <= ',$strs);
}

sub ge_to_perl {
  my ($t,$args) = @_;
  my $first = first(atoms($args));
  my $strs = atoms_to_perl_strs($t,$args);
  my $type = GetAtomType($t,$first);
  if ($type eq 'Str') {
    return ajoin(' ge ',$strs);
  }
  return ajoin(' >= ',$strs);
}

sub lt_to_perl {
  my ($t,$args) = @_;
  my $first = first(atoms($args));
  my $strs = atoms_to_perl_strs($t,$args);
  my $type = GetAtomType($t,$first);
  if ($type eq 'Str') {
    return ajoin(' lt ',$strs);
  }
  return ajoin(' < ',$strs);
}

sub gt_to_perl {
  my ($t,$args) = @_;
  my $first = first(atoms($args));
  my $strs = atoms_to_perl_strs($t,$args);
  my $type = GetAtomType($t,$first);
  if ($type eq 'Str') {
    return ajoin(' gt ',$strs);
  }
  return ajoin(' > ',$strs);
}

sub oper_to_perl {
  my ($t,$name,$args) = @_;
  my $strs = atoms_to_perl_strs($t,$args);
  my $indent = GetIndent($t);
  if ($name eq 'set') {
    my $str = ajoin(' = ',$strs);
    return add($indent,"$str;");
  }
  if ($name ~~ ['-','&&','||','~~']) {
    return ajoin(" $name ",$strs);
  }
  given ($name) {
    when ('map') {
      return map_to_perl($strs);
    }
    when ('grep') {
      return grep_to_perl($strs);
    }
    default {
      my $args_str = ajoin(',',$strs);
      my $call_str = call_to_perl($name,$args_str);
      my $call_type = GetCallType($t,$name);
      if ($call_type eq 'Nil') {
        return add($indent,"$call_str;");
      }
      return $call_str;
    }
  }
}

sub call_to_perl {
  my ($name,$str) = @_;
  given ($name) {
    when ('+') {
      return "add($str)";
    }
    when ('say') {
      return "say $str";
    }
    when ('print') {
      return "print $str";
    }
    when ('trace') {
      return "croak($str)";
    }
    when ('chop') {
      return "Chop($str)";
    }
    when ('inc') {
      return "$str++;";
    }
    when ('dec') {
      return "$str --";
    }
    when ('stdin') {
      return "<STDIN>";
    }
    when ('join') {
      return "ajoin($str)";
    }
    when ('split') {
      return "asplit($str)";
    }
    when ('push') {
      return "apush($str)";
    }
    when ('unshift') {
      return "aunshift($str)";
    }
    when ('shift') {
      return "ashift($str)";
    }
    when ('nextif') {
      return "next if $str";
    }
    when ('exitif') {
      return "exit() if $str";
    }
    default {
      $name = name_to_perl($name);
      return "$name($str)";
    }
  }
}

sub string_to_perl {
  my $args = shift;
  my $strs = [];
  for my $name (@{atoms($args)}) {
    if (start_with($name,'$')) {
      apush($strs,name_to_perl($name));
    }
    else {
      apush($strs,$name);
    }
  }
  my $str = to_str($strs);
  return "\"$str\"";
}

sub use_to_perl {
  my $args = shift;
  return "use $args;";
}

sub lstr_to_perl {
  my $str = shift;
  return "<<'EOF'\n$str\nEOF\n";
}

sub str_to_perl {
  my $str = shift;
  return "'$str'";
}

sub bool_to_perl {
  my $bool = shift;
  if ($bool eq 'true') {
    return '1';
  }
  return '0';
}

sub sym_to_perl {
  my $name = shift;
  if ($name eq '@args') {
    return $name;
  }
  given ($name) {
    when ('Int') {
      return '0';
    }
    when ('Str') {
      return "''";
    }
    when ('Bool') {
      return '1';
    }
    when ('Strs') {
      return '[]';
    }
    when ('Ints') {
      return '[]';
    }
    when ('Table') {
      return '{}';
    }
    when ('Tree') {
      return '{}';
    }
    default {
      return name_to_perl($name);
    }
  }
}

sub name_to_perl {
  my $name = shift;
  my $chars = [];
  for my $char (@{to_chars($name)}) {
    given ($char) {
      when ('-') {
        apush($chars,'_');
      }
      when ('@') {
        apush($chars,'$');
      }
      when ('%') {
        apush($chars,'$');
      }
      default {
        apush($chars,$char);
      }
    }
  }
  return to_str($chars);
}

sub char_to_perl {
  my $args = shift;
  my $last_char = last_char($args);
  given ($last_char) {
    when ('n') {
      return '"\n"';
    }
    when ('t') {
      return '"\t"';
    }
    when ('r') {
      return '"\r"';
    }
    when (Ep) {
      return '"\\"';
    }
    when ("'") {
      return '"\'"';
    }
    default {
      return "'$last_char'";
    }
  }
}

sub map_to_perl {
  my $strs = shift;
  my ($fn,$array) = aflat($strs);
  if ($array eq '@args') {
    return "[ map { $fn(\$_) } $array ]";
  }
  return "[ map { $fn(\$_) } \@{$array} ]";
}

sub grep_to_perl {
  my $strs = shift;
  my ($fn,$array) = aflat($strs);
  return "[ grep { $fn(\$_) } \@{$array} ]";
}
1;