package Mylisp::ToPerl;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(ast_to_perl ast_to_perl_repl tidy_perl);

use YAML::XS qw(Dump);
use Perl::Tidy;
use Spp::Builtin;
use Spp::Core;
use Mylisp::Core;

sub ast_to_perl {
  my $exprs      = shift;
  my $head_str   = get_perl_head_str($exprs);
  my $exprs_strs = atoms_to_perl($exprs);
  my $exprs_str  = join_exprs($exprs_strs);
  my $perl_str   = $head_str . $exprs_str;
  return tidy_perl($perl_str);
}

sub atom_to_perl {
  my $atom = shift;
  # say Dump($atom);
  my ($name, $args) = @{$atom};
  given ($name) {
    when ('Oper')   { oper_to_perl($args) }
    when ('Call')   { call_to_perl($args) }
    when ('Ocall')  { ocall_to_perl($args) }
    when ('Aindex') { aindex_to_perl($args) }
    when ('Hkey')   { hkey_to_perl($args) }
    when ('Arange') { arange_to_perl($args) }
    when ('exprs')  { exprs_to_perl($args) }
    when ('while')  { while_to_perl($args) }
    when ('for')    { for_to_perl($args) }
    when ('in')     { iter_to_perl($args) }
    when ('given')  { given_to_perl($args) }
    when ('when')   { when_to_perl($args) }
    when ('then')   { then_to_perl($args) }
    when ('if')     { if_to_perl($args) }
    when ('elif')   { elif_to_perl($args) }
    when ('else')   { else_to_perl($args) }
    when ('func')   { func_to_perl($args) }
    when ('my')     { my_to_perl($args) }
    when ('use')    { use_to_perl($args) }
    when ('import') { import_to_perl($args) }
    when ('return') { return_to_perl($args) }
    when ('Sym')    { sym_to_perl($args) }
    when ('Lstr')   { lstr_to_perl($args) }
    when ('Str')    { str_to_perl($args) }
    when ('Char')   { char_to_perl($args) }
    when ('String') { string_to_perl($args) }
    when ('Array')  { array_to_perl($args) }
    when ('Hash')   { hash_to_perl($args) }
    when ('Pair')   { pair_to_perl($args) }
    when ('List')   { list_to_perl($args) }
    when ('Slist')  { slist_to_perl($args) }
    when ('Bool')   { bool_to_perl($args) }
    when ('set')    { set_to_perl($args) }
    when ('not')    { not_to_perl($args) }
    when ('Int')    { return $args }
    when ('Ns')     { return $args }
    when ('module') { return '' }
    when ('class')  { return '' }
    when ('end')    { return '1;' }
    when ('type')   { return '' }
    default {
      say to_json([$atom]);
      error("miss action: to perl!");
    }
  }
}

sub char_to_perl {
  my $args      = shift;
  my $last_char = tail($args);
  given ($last_char) {
    when ('b') { return "''" }
    when ('n') { return '"\n"' }
    when ('t') { return '"\t"' }
    when ('r') { return '"\r"' }
    when ('s') { return "' '" }
    when ('\\') { return '"\\\\"' }
    default    { return "'$last_char'" }
  }
}

sub oper_to_perl {
  my $atoms = shift;
  my ($name, $args) = @{$atoms};
  my $strs = atoms_to_perl($args);
  given ($name) {
    when ('>>') {
      my ($elem, $array) = @{$strs};
      return "eunshift($elem, $array)";
    }
    when ('<<') {
      my ($array, $elem) = @{$strs};
      return "epush($array, $elem)";
    }
    default {
      my $expr_str = join(" $name ", @{$strs});
      return "($expr_str)";
    }
  }
}

sub call_to_perl {
  my $atom = shift;
  my ($action, $args) = @{$atom};
  my $strs = atoms_to_perl($args);
  my $str = join ', ', @{$strs};
  given ($action) {
    when ('exists')  { return "exists $str" }
    when ('say')     { return "say $str" }
    when ('print')   { return "print $str" }
    when ('delete')  { return "delete $str" }
    when ('return')  { return "return $str" }
    when ('chop')    { return "Chop($str)" }
    when ('inc')     { return "$str++" }
    when ('dec')     { return "$str--" }
    when ('shift')   { return "shift \@{$str};" }
    when ('split')   { return "[split $str]" }
    when ('nextif')  { return "next if $str" }
    when ('exitif')  { return "exit() if $str" }
    when ('stdin')   { return '<STDIN>' }
    when ('add')     { add_to_perl($strs) }
    when ('map')     { map_to_perl($strs) }
    when ('grep')    { grep_to_perl($strs) }
    when ('join')    { join_to_perl($strs) }
    when ('push')    { push_to_perl($strs) }
    when ('unshift') { unshift_to_perl($strs) }
    default {
      my $name = sym_to_perl($action);
      return "$name($str)"
    }
  }
}

sub add_to_perl {
  my $strs = shift;
  my $str = join ' . ', @{$strs};
  return "($str)";
}

sub map_to_perl {
  my $strs = shift;
  my ($fn, $array) = @{$strs};
  return "[ map { $fn(\$_) } \@{$array} ]";
}

sub grep_to_perl {
  my $strs = shift;
  my ($fn, $array) = @{$strs};
  return "[ grep { $fn(\$_) } \@{$array} ]";
}

sub join_to_perl {
  my $strs = shift;
  my ($char, $array) = @{$strs};
  return "join $char, \@{$array}; ";
}

sub push_to_perl {
  my $strs = shift;
  my ($array, $elem) = @{$strs};
  return "push \@{$array}, $elem;";
}

sub unshift_to_perl {
  my $strs = shift;
  my ($array, $elem) = @{$strs};
  return "unshift \@{$array}, $elem;";
}

sub ocall_to_perl {
  my $args = shift;
  my ($call, $args) = @{$args};
  my $call_name = sym_to_perl($call);
  my $strs      = atoms_to_perl($args);
  my $args_str  = join ', ', @{$strs};
  return "$call_name($args_str)";
}

sub aindex_to_perl {
  my $args       = shift;
  my $strs       = atoms_to_perl($args);
  my $name       = $strs->[0];
  my $indexs     = rest($strs);
  my $indexs_str = join '][', @{$indexs};
  return "$name\->[$indexs_str]";
}

sub hkey_to_perl {
  my $args     = shift;
  my $strs     = atoms_to_perl($args);
  my $name     = $strs->[0];
  my $keys     = rest($strs);
  my $keys_str = join '}{', @{$keys};
  return "$name\->{$keys_str} ";
}

sub arange_to_perl {
  my $args = shift;
  my ($sym,  $range) = @{$args};
  my ($from, $to)    = @{$range};
  my $name = atom_to_perl($sym);
  if ($to == 0) {
    return "subarray($sym, $from)";
  }
  return "subarray($sym, $from, $to)";
}

sub exprs_to_perl {
  my $exprs      = shift;
  my $exprs_strs = atoms_to_perl($exprs);
  my $str        = join_exprs($exprs_strs);
  return "{ $str }";
}

sub while_to_perl {
  my $args = shift;
  my $str  = cond_exprs_to_perl($args);
  return "while $str";
}

sub for_to_perl {
  my $args = shift;
  my $strs = atoms_to_perl($args);
  my $str  = join ' ', @{$strs};
  return "for $str";
}

sub iter_to_perl {
  my $args      = shift;
  my $iter_name = $args->[1][1];
  my $flip      = first($iter_name);
  my $strs      = atoms_to_perl($args);
  my ($loop, $iter) = @{$strs};
  given ($flip) {
    when ('$') {
      return "my $loop (split '', $iter)";
    }
    when ('%') {
      return "my $loop (keys %{$iter})";
    }
    default {
      if ($iter_name eq '@args') {
        return "my $loop ($iter)";
      }
      return "my $loop (\@{$iter})";
    }
  }
}

sub given_to_perl {
  my $args = shift;
  my $strs = atoms_to_perl($args);
  my ($sym, $given_exprs) = @{$strs};
  return "given ($sym) $given_exprs";
}

sub when_to_perl {
  my $args = shift;
  my $str  = cond_exprs_to_perl($args);
  return "when $str";
}

sub then_to_perl {
  my $args = shift;
  my $str  = atom_to_perl($args);
  return "default $str";
}

sub if_to_perl {
  my $exprs = shift;
  my $str   = cond_exprs_to_perl($exprs);
  return "if $str";
}

sub elif_to_perl {
  my $exprs = shift;
  my $str   = cond_exprs_to_perl($exprs);
  return "elsif $str";
}

sub else_to_perl {
  my $exprs = shift;
  my $str   = atom_to_perl($exprs);
  return "else $str";
}

sub func_to_perl {
  my $atoms = shift;
  my ($args, $rest)      = match($atoms);
  my ($name, $func_args) = @{$args};
  my $args_str   = get_args_str($func_args);
  my ($return, $exprs)  = match($rest);
  my $exprs_strs = atoms_to_perl($exprs);
  if (first($return) ne '->') {
    $exprs_strs = atoms_to_perl($rest);
  } 
  my $exprs_str  = join_exprs($exprs_strs);
  $name = sym_to_perl($name);
  return "sub $name { $args_str $exprs_str }";
}

sub get_args_str {
  my $args = shift;
  if (len($args) == 0) { return "" }
  my $strs = [map { sym_to_perl($_->[0]) } @{$args}];
  my $str = join(',', @{$strs});
  if (len($args) == 1) {
    if (start_with($str, '@')) {
      return "my $str = \@_;";
    }
    return "my $str = shift;";
  }
  else {
    return "my ($str) = \@_;";
  }
}

sub my_to_perl {
  my $args = shift;
  my $sym  = $args->[0];
  my $strs = atoms_to_perl($args);
  my ($sym_name, $value_str) = @{$strs};
  return "my $sym_name = $value_str";
}

sub list_to_perl {
  my $list = shift;
  my $strs = atoms_to_perl($list);
  my $str  = join ', ', @{$strs};
  return "($str)";
}

sub return_to_perl {
  my $args = shift;
  my $strs = atoms_to_perl($args);
  my $str  = join ', ', @{$strs};
  return "return $str";
}

sub use_to_perl {
  my $ns = shift;
  return "use $ns;";
}

sub import_to_perl {
  my $args = shift;
  my $strs = atoms_to_perl($args);
  my $str  = join ' ', @{$strs};
  return "use $str;";
}

sub slist_to_perl {
  my $list = shift;
  my $strs = atoms_to_perl($list);
  my $str  = join ' ', @{$strs};
  return "qw($str)";
}

sub sym_to_perl {
  my $name  = shift;
  my @chars = ();
  return $name if $name eq '@args';
  for my $char (split '', $name) {
    given ($char) {
      when ('-') { push @chars, '_' }
      when ('@') { push @chars, '$' }
      when ('%') { push @chars, '$' }
      default    { push @chars, $char }
    }
  }
  return join('', @chars);
}

sub lstr_to_perl {
  my $str = shift;
  return "<<'EOF'\n${str}\nEOF\n";
}

sub str_to_perl {
  my $str = shift;
  return qq('$str');
}

sub string_to_perl {
  my $atoms = shift;
  my $strs  = [];
  for my $atom (@{$atoms}) {
    my ($type, $value) = @{$atom};
    given ($type) {
      when ('Sym') {
        my $name = sym_to_perl($value);
        push @{$strs}, $name;
      }
      default { push @{$strs}, $value }
    }
  }
  my $str = join('', @{$strs});
  return qq("$str");
}

sub array_to_perl {
  my $array     = shift;
  my $atoms     = atoms_to_perl($array);
  my $atoms_str = join ',', @{$atoms};
  return "[$atoms_str]";
}

sub hash_to_perl {
  my $pairs = shift;
  my $strs  = atoms_to_perl($pairs);
  my $str   = join(', ', @{$strs});

  # add trail space to distinguish with block
  return "{$str} ";
}

sub pair_to_perl {
  my $pair = shift;
  my $strs = atoms_to_perl($pair);
  return join(' => ', @{$strs});
}

sub bool_to_perl {
  my $bool = shift;
  return '1' if $bool eq 'true';
  return '0';
}

sub set_to_perl {
  my $args = shift;
  my $strs = atoms_to_perl($args);
  my $str  = join ' = ', @{$strs};
  return "$str";
}

sub not_to_perl {
  my $expr = shift;
  my ($call, $args) = @{$expr};
  my $name = '!' . sym_to_perl($call);
  my $strs = atoms_to_perl($args);
  my $str  = join(',', @{$strs});
  return "$name($str)";
}

## ===========================================
## Common Function
## ===========================================

sub ast_to_perl_repl {
  my $exprs      = shift;
  my $exprs_strs = atoms_to_perl($exprs);
  my $exprs_str  = join_exprs($exprs_strs);
  return $exprs_str;
}

sub atoms_to_perl {
  my $atoms = shift;
  return [map { atom_to_perl($_) } @{$atoms}];
}

sub join_exprs {
  my $exprs    = shift;
  my $strs     = [];
  my $end_char = ';';
  for my $expr (@{$exprs}) {
    if ($end_char ~~ [';', '}']) {
      push @{$strs}, $expr;
    }
    else {
      push @{$strs}, ';';
      push @{$strs}, $expr;
    }
    $end_char = substr($expr, -1);
  }
  return join(' ', @{$strs});
}

sub cond_exprs_to_perl {
  my $args = shift;
  my $strs = atoms_to_perl($args);
  my ($cond, $exprs_str) = @{$strs};
  if (first($cond) eq '(') {
    return "$cond $exprs_str";
  }
  return "($cond) $exprs_str";
}

sub get_perl_head_str {
  my $exprs      = shift;
  my $func_names = [];
  my $head_str   = '';
  my $flag       = 0;
  for my $expr (@{$exprs}) {
    my ($name, $value, $pos) = @{$expr};
    given ($name) {
      when ('func') {

        # say to_json($value->[0]); exit();
        push @{$func_names}, $value->[0][0];
      }
      when ('module') {
        $head_str = ns_to_perl($name, $value);
        $flag = 1;
      }
      when ('class') {
        $head_str = ns_to_perl($name, $value);
        $flag = 2;
      }
    }
  }
  if ($flag == 1) {
    my $export_str = get_export_str($func_names);
    return $head_str . $export_str;
  }
  if ($flag == 2) {
    return $head_str;
  }
  return <<'EOF';
#!/usr/bin/perl

use 5.012;
no warnings "experimental";

EOF
}

sub ns_to_perl {
  my ($name, $ns) = @_;
  return <<EOF;
package $ns;

use 5.012;
no warnings "experimental";

EOF
}

sub get_export_str {
  my $names = shift;
  my @names = grep { first($_) ne '_' } @{$names};
  my $str   = join ' ', map { sym_to_perl($_) } @names;
  return <<"EOF";
use Exporter;
our \@ISA = qw(Exporter);
our \@EXPORT = qw($str);

EOF
}

sub tidy_perl {
  my $source_string = shift;
  my $dest_string;
  my $stderr_string;
  my $errorfile_string;
  my $argv  = "-i=2 -l=60 -vt=2 -pt=2 -bt=1 -sbt=2 -bbt=1";
  my $error = Perl::Tidy::perltidy(
    argv        => $argv,
    source      => \$source_string,
    destination => \$dest_string,
    stderr      => \$stderr_string,
    errorfile   => \$errorfile_string,
  );

  if ($error) {
    print "<<STDERR>>\n$stderr_string\n";
  }
  return $dest_string;
}

1;
