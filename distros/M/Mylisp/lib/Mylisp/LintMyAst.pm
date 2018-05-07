package Mylisp::LintMyAst;

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(Report IsDefine Context InBlock InFunc InContext OutContext OutBlock GetIndent LintMyAst GetAtomType GetArrayType GetCallType);

use Mylisp;
use Mylisp::Builtin;
use Mylisp::Estr;
use Mylisp::Match;

sub get_type_grammar {
  return <<'EOF'

    door    -> |\s+ Spec|+ $
    Spec    -> Rule '->' pat
    pat     -> |\h+ Branch More Maybe Token Str|+
    Branch  -> '|'
    More    -> Token'+'
    Maybe   -> Token'?'
    Rule    -> name
    Token   -> name
    Str     -> ':'\a+
    name    -> \a+
    
EOF
;;
}

sub get_my_type_grammar {
  return <<'EOF'

    Nil     -> :Nil
    Bool    -> :Bool
    Str     -> :Str|:String|:Lstr|:Char
    Int     -> :Int
    Strs    -> :Strs 
    Ints    -> :Ints
    Table   -> :Table
    Tree    -> :Tree
    Fn      -> :Fn
    Atom    -> Str|Int
    Array   -> Strs|Ints
    Hash    -> Table|Tree
    
EOF
;;
}

sub get_type_table {
  my $grammar = get_type_grammar;
  my $ast = GrammarToAst($grammar);
  return AstToTable($ast);
}

sub get_my_type_table {
  my $table = get_type_table;
  my $grammar = get_my_type_grammar;
  my ($match,$ok) = MatchTable($table,$grammar);
  if (not($ok)) {
    error("$match my-type-grammar syntax error");
  }
  my $ast = opt_type_match($match);
  lint_type_ast($ast);
  return AstToTable($ast);
}

sub new_lint {
  my $table = get_type_table();
  my $mytable = get_my_type_table();
  my $stack = ['main'];
  return {'text' => '','locate' => '','stack' => $stack,'tree' => {},'ret' => '','depth' => 0,'pos' => 0,'count' => 0,'typetable' => $table,'mytypetable' => $mytable};
}

sub pat_to_type_rule {
  my ($t,$pat) = @_;
  my $table = $t->{'typetable'};
  my ($match,$ok) = MatchDoor($table,$pat,'pat');
  if (not($ok)) {
    Report($t,"pattern: |$pat| could not to rule!");
  }
  return opt_type_pat($match);
}

sub opt_type_pat {
  my $atoms = shift;
  my $end = estr('End','e');
  if (is_atom($atoms)) {
    my $atom = opt_type_atom($atoms);
    return estr('Rules',estr($atom,$end));
  }
  my $rule = opt_type_atoms($atoms);
  if (is_branch($rule)) {
    return estr('Rules',estr($rule,$end));
  }
  return epush($rule,$end);
}

sub opt_type_match {
  my $match = shift;
  if (is_atom($match)) {
    return opt_type_atom($match);
  }
  return estr_strs([ map { opt_type_atom($_) } @{atoms($match)} ]);
}

sub opt_type_atom {
  my $atom = shift;
  my ($name,$value) = flat($atom);
  given ($name) {
    when ('Spec') {
      return opt_type_spec($value);
    }
    when ('More') {
      return opt_type_more($value);
    }
    when ('Maybe') {
      return opt_type_maybe($value);
    }
    when ('Str') {
      return opt_type_str($value);
    }
    default {
      return estr($name,$value);
    }
  }
}

sub opt_type_spec {
  my $atoms = shift;
  my ($token,$rules) = match($atoms);
  my $name = value($token);
  my $opt_rules = opt_type_atoms($rules);
  return estr($name,$opt_rules);
}

sub opt_type_atoms {
  my $atoms = shift;
  my $opt_atoms = [ map { opt_type_atom($_) } @{atoms($atoms)} ];
  return gather_type_branch($opt_atoms);
}

sub gather_type_branch {
  my $atoms = shift;
  my $branches = [];
  my $branch = [];
  my $flag = 0;
  my $count = 0;
  for my $atom (@{$atoms}) {
    if (is_branch($atom)) {
      if ($count > 1) {
        apush($branches,estr('Rules',estr_strs($branch)));
      }
      elsif ($count == 0) {
        croak("branch -> error locate");
      }
      else {
        apush($branches,$branch->[0]);
      }
      $flag = 1;
      $branch = [];
      $count = 0;
    }
    else {
      apush($branch,$atom);
      $count++;;
    }
  }
  if ($flag == 0) {
    if ($count == 1) {
      return $branch->[0];
    }
    else {
      return estr('Rules',estr_strs($branch));
    }
  }
  if ($count > 1) {
    apush($branches,estr('Rules',estr_strs($branch)));
  }
  else {
    apush($branches,$branch->[0]);
  }
  return estr('Branch',estr_strs($branches));
}

sub is_branch {
  my $atom = shift;
  return is_atom_name($atom,'Branch');
}

sub opt_type_more {
  my $atoms = shift;
  my $atom = first(atoms($atoms));
  return estr('More',opt_type_atom($atom));
}

sub opt_type_maybe {
  my $atoms = shift;
  my $atom = first(atoms($atoms));
  return estr('Maybe',opt_type_atom($atom));
}

sub opt_type_str {
  my $str = shift;
  return estr('Str',rest_str($str));
}

sub lint_type_ast {
  my $ast = shift;
  my $table = {};
  for my $atom (@{atoms($ast)}) {
    my ($name,$value) = flat($atom);
    if (exists $table->{$name}) {
      say "repeat define type: |$name|";
    }
    else {
      $table->{$name} = 'ok';
      lint_type_atom($value,$table);
    }
  }
}

sub lint_type_atom {
  my ($rule,$t) = @_;
  my ($name,$atoms) = flat($rule);
  if (not($name ~~ ['Str','End'])) {
    given ($name) {
      when ('Rules') {
        lint_type_atoms($atoms,$t);
      }
      when ('Branch') {
        lint_type_atoms($atoms,$t);
      }
      when ('More') {
        lint_type_atom($atoms,$t);
      }
      when ('Maybe') {
        lint_type_atom($atoms,$t);
      }
      default {
        lint_type_token($atoms,$t);
      }
    }
  }
}

sub lint_type_token {
  my ($name,$table) = @_;
  if (not(exists $table->{$name})) {
    say "not exists type define: |$name|";
  }
}

sub lint_type_atoms {
  my ($atoms,$table) = @_;
  for my $atom (@{atoms($atoms)}) {
    lint_type_atom($atom,$table);
  }
}

sub apply_char {
  my $t = shift;
  my $text = $t->{'text'};
  my $pos = $t->{'pos'};
  return substr($text, $pos, 1);
}

sub load_text {
  my ($t,$text) = @_;
  $t->{'text'} = add($text,End);
  $t->{'pos'} = 0;
}

sub match_type {
  my ($t,$rule,$text) = @_;
  load_text($t,$text);
  return match_type_rule($t,$rule);
}

sub match_type_rule {
  my ($t,$rule) = @_;
  my ($name,$value) = flat($rule);
  given ($name) {
    when ('Rules') {
      return match_type_rules($t,$value);
    }
    when ('Branch') {
      return match_type_branch($t,$value);
    }
    when ('More') {
      return match_type_more($t,$value);
    }
    when ('Maybe') {
      return match_type_maybe($t,$value);
    }
    when ('Str') {
      return match_type_str($t,$value);
    }
    when ('Token') {
      return match_type_token($t,$value);
    }
    when ('End') {
      return match_type_end($t,$value);
    }
    default {
      croak("unknown rule: $name to match!");
    }
  }
  return 0;
}

sub match_type_rules {
  my ($t,$rules) = @_;
  for my $rule (@{atoms($rules)}) {
    if (not(match_type_rule($t,$rule))) {
      return 0;
    }
  }
  return 1;
}

sub match_type_branch {
  my ($t,$branch) = @_;
  my $pos = $t->{'pos'};
  for my $rule (@{atoms($branch)}) {
    if (match_type_rule($t,$rule)) {
      return 1;
    }
    $t->{'pos'} = $pos;
  }
  return 0;
}

sub match_type_token {
  my ($t,$name) = @_;
  while (is_space(apply_char($t))) {
    $t->{'pos'}++;;
  }
  my $mytable = $t->{'mytypetable'};
  if (not(exists $mytable->{$name})) {
    Report($t,"not regist type: |$name|");
  }
  my $rule = $mytable->{$name};
  return match_type_rule($t,$rule);
}

sub match_type_more {
  my ($t,$rule) = @_;
  my $time = 0;
  while (1) {
    my $pos = $t->{'pos'};
    if (not(match_type_rule($t,$rule))) {
      if ($time == 0) {
        return 0;
      }
      $t->{'pos'} = $pos;
      return 1;
    }
    $time++;;
  }
  return 1;
}

sub match_type_maybe {
  my ($t,$rule) = @_;
  my $cache = $t->{'pos'};
  if (not(match_type_rule($t,$rule))) {
    $t->{'pos'} = $cache;
  }
  return 1;
}

sub match_type_str {
  my ($t,$str) = @_;
  for my $char (@{to_chars($str)}) {
    if ($char ne apply_char($t)) {
      return 0;
    }
    $t->{'pos'}++;;
  }
  return 1;
}

sub match_type_end {
  my ($t,$end) = @_;
  if (apply_char($t) eq End) {
    return 1;
  }
  return 0;
}

sub Report {
  my ($t,$message) = @_;
  my $locate = $t->{'locate'};
  my $line = value($locate);
  error("error! line: $line $message");
}

sub IsDefine {
  my ($t,$name) = @_;
  my $stack = $t->{'stack'};
  for my $ns (@{$stack}) {
    my $tree = $t->{'tree'};
    if (exists $tree->{$ns}{$name}) {
      return 1;
    }
  }
  return 0;
}

sub update_off {
  my ($t,$atom) = @_;
  $t->{'locate'} = off($atom);
}

sub Context {
  my $t = shift;
  my $stack = $t->{'stack'};
  return $stack->[0];
}

sub InBlock {
  my $t = shift;
  my $ns = int_to_str($t->{'count'});
  $t->{'count'}++;;
  $t->{'depth'}++;;
  InContext($t,$ns);
}

sub InFunc {
  my ($t,$ns) = @_;
  $t->{'depth'}++;;
  InContext($t,$ns);
}

sub InContext {
  my ($t,$ns) = @_;
  if ($ns ne Context($t)) {
    my $tree = $t->{'tree'};
    if (not(exists $tree->{$ns})) {
      $tree->{$ns} = {};
    }
    aunshift($ns,$t->{'stack'});
  }
}

sub OutContext {
  my $t = shift;
  ashift($t->{'stack'});
}

sub OutBlock {
  my $t = shift;
  OutContext($t);
  $t->{'depth'} --;
}

sub GetIndent {
  my $t = shift;
  my $depth = $t->{'depth'};
  return repeat('  ',$depth);
}

sub set_name_value {
  my ($t,$name,$value) = @_;
  my $ns = Context($t);
  my $tree = $t->{'tree'};
  if (exists $tree->{$ns}{$name}) {
    Report($t,"redefine exists symbol |$name|.");
  }
  $tree->{$ns}{$name} = $value;
}

sub get_name_value {
  my ($t,$name) = @_;
  my $stack = $t->{'stack'};
  my $tree = $t->{'tree'};
  for my $ns (@{$stack}) {
    if (exists $tree->{$ns}{$name}) {
      return $tree->{$ns}{$name};
    }
  }
  Report($t,"|$name| undefine!");
  return '';
}

sub LintMyAst {
  my $ast = shift;
  my $t = new_lint();
  init_my_lint($t,$ast);
  lint_my_atoms($t,$ast);
  $t->{'count'} = 0;
  return $t;
}

sub init_my_lint {
  my ($t,$ast) = @_;
  for my $expr (@{atoms($ast)}) {
    my ($name,$args) = flat($expr);
    update_off($t,$expr);
    given ($name) {
      when ('package') {
        InContext($t,$args);
      }
      when ('func') {
        regist_func($t,$args);
      }
    }
  }
}

sub use_package {
  my ($t,$package) = @_;
  my $dirs = asplit('::',$package);
  my $path = ajoin('/',$dirs);
  my $ast_file = add($path,'.o');
  my $ast = read_file($ast_file);
  load_ast($t,$ast);
}

sub load_ast {
  my ($t,$ast) = @_;
  for my $expr (@{atoms($ast)}) {
    my ($name,$args) = flat($expr);
    update_off($t,$expr);
    given ($name) {
      when ('const') {
        regist_const($t,$args);
      }
      when ('type') {
        regist_type($t,$args);
      }
      when ('struct') {
        regist_struct($t,$args);
      }
      when ('func') {
        regist_func($t,$args);
      }
    }
  }
}

sub regist_const {
  my ($t,$args) = @_;
  my ($sym,$value) = flat($args);
  my $name = value($sym);
  my $value_type = GetAtomType($t,$value);
  set_name_value($t,$name,$value_type);
}

sub regist_type {
  my ($t,$args) = @_;
  my ($sym,$type) = flat($args);
  my $name = value($sym);
  my $value = value($type);
  set_name_value($t,$name,$value);
}

sub regist_struct {
  my ($t,$atom) = @_;
  my ($type,$fields) = flat($atom);
  my $type_value = estr('Table',$type);
  set_name_value($t,$type,$type_value);
  InContext($t,$type);
  for my $field (@{atoms($fields)}) {
    my ($name,$value) = flat($field);
    set_name_value($t,$name,$value);
  }
  OutContext($t);
}

sub regist_func {
  my ($t,$atoms) = @_;
  my ($name_args,$return) = flat($atoms);
  my $return_type = get_my_atoms_value(value($return));
  my ($name,$args) = flat($name_args);
  if (is_blank($args)) {
    set_name_value($t,$name,$return_type);
  }
  else {
    my $args_type = get_my_atoms_value($args);
    my $value = estr($args_type,$return_type);
    set_name_value($t,$name,$value);
  }
}

sub get_my_atoms_value {
  my $atoms = shift;
  my $names = [ map { value($_) } @{atoms($atoms)} ];
  return ajoin(' ',$names);
}

sub get_return_type_str {
  my $expr = shift;
  my $args = value($expr);
  my $names = [ map { value($_) } @{atoms($args)} ];
  my $types = [ map { arg_type_to_return($_) } @{$names} ];
  return ajoin(' ',$types);
}

sub arg_type_to_return {
  my $type = shift;
  given ($type) {
    when ('Str+') {
      return 'Strs';
    }
    when ('Int+') {
      return 'Ints';
    }
    when ('Str?') {
      return 'Str';
    }
    when ('Int?') {
      return 'Int';
    }
    default {
      return $type;
    }
  }
}

sub lint_my_atoms {
  my ($t,$atoms) = @_;
  for my $atom (@{atoms($atoms)}) {
    lint_my_atom($t,$atom);
  }
}

sub lint_my_atom {
  my ($t,$atom) = @_;
  my ($name,$args) = flat($atom);
  if (not($name ~~ ['package','Str','Lstr','Int','Bool','Char','->'])) {
    update_off($t,$atom);
    given ($name) {
      when ('use') {
        use_package($t,$args);
      }
      when ('const') {
        regist_const($t,$args);
      }
      when ('type') {
        regist_type($t,$args);
      }
      when ('struct') {
        regist_struct($t,$args);
      }
      when ('Array') {
        lint_my_atoms($t,$args);
      }
      when ('Aindex') {
        lint_my_atoms($t,$args);
      }
      when ('Arange') {
        lint_my_atoms($t,$args);
      }
      when ('func') {
        lint_my_func($t,$args);
      }
      when (':ocall') {
        lint_my_ocall($t,$args);
      }
      when ('return') {
        lint_my_return($t,$args);
      }
      when ('my') {
        lint_my_my($t,$args);
      }
      when ('our') {
        lint_my_our($t,$args);
      }
      when ('set') {
        lint_my_set($t,$args);
      }
      when ('Sym') {
        lint_my_sym($t,$args);
      }
      when ('for') {
        lint_my_for($t,$args);
      }
      when ('while') {
        lint_my_exprs($t,$args);
      }
      when ('given') {
        lint_my_exprs($t,$args);
      }
      when ('when') {
        lint_my_exprs($t,$args);
      }
      when ('if') {
        lint_my_exprs($t,$args);
      }
      when ('elif') {
        lint_my_exprs($t,$args);
      }
      when ('then') {
        lint_my_block($t,$args);
      }
      when ('else') {
        lint_my_block($t,$args);
      }
      when ('Hash') {
        lint_my_hash($t,$args);
      }
      when ('String') {
        lint_my_string($t,$args);
      }
      default {
        lint_my_call($t,$name,$args);
      }
    }
  }
}

sub lint_my_string {
  my ($t,$strs) = @_;
  for my $name (@{atoms($strs)}) {
    if (start_with($name,'$')) {
      next if IsDefine($t,$name);
      Report($t,"undefine Variable: |$name|");
    }
  }
}

sub lint_my_hash {
  my ($t,$pairs) = @_;
  for my $pair (@{atoms($pairs)}) {
    lint_my_atom($t,value($pair));
  }
}

sub lint_my_exprs {
  my ($t,$atoms) = @_;
  my ($cond_atom,$exprs) = match($atoms);
  lint_my_atom($t,$cond_atom);
  lint_my_block($t,$exprs);
}

sub lint_my_block {
  my ($t,$exprs) = @_;
  InBlock($t);
  lint_my_atoms($t,$exprs);
  OutBlock($t);
}

sub lint_my_func {
  my ($t,$args) = @_;
  my ($name_args,$rest) = match($args);
  my ($return,$atoms) = match($rest);
  my $return_type_str = get_return_type_str($return);
  $t->{'ret'} = $return_type_str;
  my ($call,$func_args) = flat($name_args);
  InFunc($t,$call);
  for my $arg (@{atoms($func_args)}) {
    my ($name,$type) = flat($arg);
    $type = arg_type_to_return($type);
    set_name_value($t,$name,$type);
  }
  lint_my_atoms($t,$atoms);
  OutBlock($t);
}

sub lint_my_return {
  my ($t,$args) = @_;
  my $return_type = $t->{'ret'};
  my $args_type_str = get_args_type_str($t,$args);
  if ($return_type ne $args_type_str) {
    my $args_pat = pat_to_type_rule($t,$args_type_str);
    lint_my_atoms($t,$args);
    if (not(match_type($t,$args_pat,$return_type))) {
      say "|$args_type_str| != |$return_type|";
      Report($t,"return type != declare type|");
    }
  }
}

sub get_args_type_str {
  my ($t,$atoms) = @_;
  my $types = [];
  for my $atom (@{atoms($atoms)}) {
    apush($types,GetAtomType($t,$atom));
  }
  return ajoin(' ',$types);
}

sub lint_my_my {
  my ($t,$args) = @_;
  my ($sym,$value) = flat($args);
  lint_my_atom($t,$value);
  my $type = GetAtomType($t,$value);
  my $name = value($sym);
  if (is_str($type)) {
    set_name_value($t,$name,$type);
  }
  else {
    Report($t,"one sym accept more assign");
  }
}

sub lint_my_our {
  my ($t,$args) = @_;
  my ($array,$value) = flat($args);
  lint_my_atom($t,$value);
  my $type = GetAtomType($t,$value);
  my $types = asplit(' ',$type);
  my $syms = value($array);
  my ($a,$b) = flat($syms);
  if (len($types) != 2) {
    Report($t,"my return value not two");
  }
  my $a_name = value($a);
  my $b_name = value($b);
  my $a_type = $types->[0];
  my $b_type = $types->[1];
  set_name_value($t,$a_name,$a_type);
  set_name_value($t,$b_name,$b_type);
}

sub lint_my_ocall {
  my ($t,$ocall) = @_;
  my ($sym,$call) = flat($ocall);
  my $type = get_name_value($t,$sym);
  my $tree = $t->{'tree'};
  if (not(exists $tree->{$type}{$call})) {
    Report($t,"ocall |$call| not define!");
  }
}

sub lint_my_call {
  my ($t,$name,$args) = @_;
  my $value = get_name_value($t,$name);
  if (is_blank($args)) {
    if (not(is_str($value))) {
      Report($t,"call |$name| less argument");
    }
  }
  else {
    if (is_str($value)) {
      Report($t,"call |$name| more argument");
    }
    my $call_str = name($value);
    lint_my_atoms($t,$args);
    my $args_str = get_args_type_str($t,$args);
    if ($call_str ne $args_str) {
      my $call_rule = pat_to_type_rule($t,$call_str);
      if (not(match_type($t,$call_rule,$args_str))) {
        say "|$call_str| != |$args_str|";
        Report($t,"call |$name| args type not same!");
      }
    }
  }
}

sub lint_my_for {
  my ($t,$args) = @_;
  my ($iter_expr,$exprs) = match($args);
  my ($name,$iter_atom) = flat($iter_expr);
  my $type = get_iter_type($t,$iter_atom);
  set_name_value($t,$name,$type);
  return   lint_my_block($t,$exprs);;
}

sub lint_my_set {
  my ($t,$args) = @_;
  my ($sym,$value) = flat($args);
  my $sym_type = GetAtomType($t,$sym);
  my $value_type = GetAtomType($t,$value);
  if ($sym_type ne $value_type) {
    say "|$sym_type| != |$value_type|";
    Report($t,"assign type not same with before!");
  }
}

sub lint_my_sym {
  my ($t,$name) = @_;
  if (not(IsDefine($t,$name))) {
    Report($t,"not define symbol: |$name|");
  }
}

sub GetAtomType {
  my ($t,$atom) = @_;
  my ($name,$value) = flat($atom);
  update_off($t,$atom);
  if ($name ~~ ['Int','Str','Bool','Hash']) {
    return $name;
  }
  if ($name ~~ ['Char','Lstr','String']) {
    return 'Str';
  }
  if ($name eq 'Sym') {
    return get_sym_type($t,$value);
  }
  if ($name eq ':ocall') {
    return get_ocall_type($t,$value);
  }
  if ($name eq 'Array') {
    return GetArrayType($t,$value);
  }
  if ($name eq 'Arange') {
    return get_arange_type($t,$value);
  }
  if ($name eq 'Aindex') {
    return get_aindex_type($t,$value);
  }
  return GetCallType($t,$name);
}

sub get_sym_type {
  my ($t,$name) = @_;
  my $value = get_name_value($t,$name);
  if (is_str($value)) {
    return $value;
  }
  return 'Fn';
}

sub get_ocall_type {
  my ($t,$ocall) = @_;
  my ($sym,$call) = flat($ocall);
  my $type = get_name_value($t,$sym);
  my $tree = $t->{'tree'};
  if (not(exists $tree->{$type}{$call})) {
    Report($t,"undefined call: |$call|");
  }
  return $tree->{$type}{$call};
}

sub GetArrayType {
  my ($t,$args) = @_;
  if (is_blank($args)) {
    return 'Strs';
  }
  my $sub_type = GetAtomType($t,first(atoms($args)));
  if ($sub_type eq 'Int') {
    return 'Ints';
  }
  return 'Strs';
}

sub get_iter_type {
  my ($t,$atom) = @_;
  my $type = GetAtomType($t,$atom);
  if ($type eq 'Ints') {
    return 'Int';
  }
  if ($type ~~ ['Strs','Table','Str']) {
    return 'Str';
  }
  return 'Nil';
}

sub get_arange_type {
  my ($t,$args) = @_;
  my $sym = first(atoms($args));
  return GetAtomType($t,$sym);
}

sub get_aindex_type {
  my ($t,$args) = @_;
  my ($sym,$indexs) = match($args);
  my $value = GetAtomType($t,$sym);
  for my $index (@{atoms($indexs)}) {
    my $type = GetAtomType($t,$index);
    my $name = value($index);
    $value = get_index_type($t,$value,$type,$name);
  }
  return $value;
}

sub get_index_type {
  my ($t,$value,$type,$name) = @_;
  my $type_str = add($value,$type);
  given ($type_str) {
    when ('StrInt') {
      return 'Str';
    }
    when ('StrsInt') {
      return 'Str';
    }
    when ('IntsInt') {
      return 'Int';
    }
    when ('TableStr') {
      return 'Str';
    }
    when ('TreeStr') {
      return 'Table';
    }
    default {
      my $tree = $t->{'tree'};
      if (exists $tree->{$value}) {
        my $table = $tree->{$value};
        if (exists $table->{$name}) {
          return $tree->{$value}{$name};
        }
      }
    }
  }
  return 'Nil';
}

sub GetCallType {
  my ($t,$name) = @_;
  if ($name ~~ ['func','if','else','elif','given','when','then','my','use','package','const','for','while','return','struct','type']) {
    return 'Nil';
  }
  my $value = get_name_value($t,$name);
  if (is_str($value)) {
    return $value;
  }
  return value($value);
}
1;
