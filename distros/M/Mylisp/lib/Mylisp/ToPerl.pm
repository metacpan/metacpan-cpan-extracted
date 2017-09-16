package Mylisp::ToPerl;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(ast_to_perl ast_to_perl_repl tidy_perl);

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
   my ($name, $args) = @{$atom};
   given ($name) {
      when ('Oper')   { oper_to_perl($args)  }
      when ('Call')   { call_to_perl($args)  }
      when ('exprs')  { exprs_to_perl($args) }
      when ('while')  { while_to_perl($args) }
      when ('for')    { for_to_perl($args)   }
      when ('given')  { given_to_perl($args) }
      when ('when')   { when_to_perl($args)  }
      when ('then')   { then_to_perl($args)  }
      when ('case')   { case_to_perl($args)  }
      when ('if')     { if_to_perl($args)    }
      when ('elif')   { if_to_perl($args)    }
      when ('else')   { else_to_perl($args)  }
      when ('ifelse') { ifelse_to_perl($args)}
      when ('func')   { func_to_perl($args)  }
      when ('def')    { func_to_perl($args)  }
      when ('fn')     { fn_to_perl($args)    }
      when ('set')    { set_to_perl($args)   }
      when ('my')     { my_to_perl($args)    }
      when ('const')  { const_to_perl($args) }
      when ('use')    { use_to_perl($args)   }
      when ('Aindex') { aindex_to_perl($args)}
      when ('Hkey')   { hkey_to_perl($args)  }
      when ('Arange') { arange_to_perl($args)}
      when ('Sym')    { sym_to_perl($args)   }
      when ('Ocall')  { ocall_to_perl($args) }
      when ('Onew')   { onew_to_perl($args)  }
      when ('Str')    { str_to_perl($args)   }
      when ('Array')  { array_to_perl($args) }
      when ('Hash')   { hash_to_perl($args)  }
      when ('List')   { list_to_perl($args)  }
      when ('Slist')  { slist_to_perl($args) }
      when ('return') { return_to_perl($args)}
      when ('Int')    { return $args }
      when ('Ns')     { return $args }
      when ('Bool')   { return $args }
      when ('ns')     { return '' }
      when ('class')  { return '' }
      when ('end')    { return '1;'}
      default {
         say to_json([$atom]);
         error("miss action: to perl!");
      }
   }
}

sub oper_to_perl {
   my $atoms = shift;
   my ($name, $args) = @{$atoms};
   my $strs = atoms_to_perl($args);
   given ($name) {
      when ('>>') {
         my ($elem, $array) = @{$strs};
         return "unshift \@{$array}, $elem;";
      }
      when ('<<') {
         my ($array, $elem) = @{$strs};
         return "unshift \@{$array}, $elem;";
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
   my $str  = join ', ', @{$strs};
   given ($action) {
      when ('exists')   { return "exists $str"}
      when ('say')      { return "say $str"}
      when ('print')    { return "print $str"}
      when ('delete')   { return "delete $str" }
      when ('return')   { return "return $str"}
      when ('inc')      { return "$str++" }
      when ('shift')    { return "shift \@{$str};"}
      when ('split')    { return "[split $str]"}
      when ('next-if')  { return "next if $str"}
      when ('exit-if')  { return "exit() if $str"}
      when ('STDIN')    { return '<STDIN>' }
      when ('concat')   { concat_to_perl($strs) }
      when ('map')      { map_to_perl($strs) }
      when ('all')      { all_to_perl($strs) }
      when ('any')      { any_to_perl($strs) }
      when ('join')     { join_to_perl($strs) }
      when ('push')     { push_to_perl($strs) }
      when ('unshift')  { unshift_to_perl($strs) }
      default {
         my $name = sym_to_perl($action);
         return "$name($str)"
      }
   }
}

sub concat_to_perl {
   my $strs = shift;
   return join '.', @{$strs};
}

sub map_to_perl {
   my $strs = shift;
   my ($fn, $array) = @{$strs};
   return "[map {$fn(\$_)} \@{$array}]";
}

sub all_to_perl {
   my $strs = shift;
   my ($fn, $array) = @{$strs};
   return "all {$fn(\$_)} \@{$array} ";
}

sub any_to_perl {
   my $strs = shift;
   my ($fn, $array) = @{$strs};
   return "any {$fn(\$_)} \@{$array} ";
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

sub exprs_to_perl {
   my $exprs      = shift;
   my $exprs_strs = atoms_to_perl($exprs);
   my $str        = join_exprs($exprs_strs);
   return "{ $str }";
}

sub while_to_perl {
   my $args = shift;
   my $str   = cond_exprs_to_perl($args);
   return "while $str";
}

sub for_to_perl {
   my $args = shift;
   my $iter_atom = $args->[1];
   my $strs = atoms_to_perl($args);
   my ($loop, $iter, $exprs_str) = @{$strs};
   if (is_atom_sym($iter_atom)) {
      given (first($iter_atom->[1])) {
         when ('$') {
            return "for my $loop (split('',$iter)) $exprs_str";
         }
         when ('%') { 
            return "for my $loop (keys %{$iter}) $exprs_str";
         }
         when ('@') {
            return "for my $loop (\@{$iter}) $exprs_str";
         }
      }
   }
   return "for my $loop (\@{$iter}) $exprs_str";
}

sub given_to_perl {
   my $args      = shift;
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
   my $str   = exprs_to_perl($args);
   return "default $str";
}

sub case_to_perl {
   my $args = shift;
   my $strs = atoms_to_perl($args);
   return join ' ', @{$strs};
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
   my $str   = exprs_to_perl($exprs);
   return "else $str";
}

sub ifelse_to_perl {
   my $args   = shift;
   my $strs  = atoms_to_perl($args);
   my ($cond, $if_str, $else_str) = @{$strs};
   if (start_with($cond, '(')) {
      return "if $cond $if_str else $else_str";
   }
   return "if ($cond) $if_str else $else_str";
}

sub func_to_perl {
   my $args = shift;
   my $name_args = $args->[0];
   my ($name, $func_args) = @{$name_args};
   my $args_str = get_args_str($func_args);
   my $exprs = rest($args);
   my $exprs_strs = atoms_to_perl($exprs);
   my $exprs_str  = join_exprs($exprs_strs);
   $name = sym_to_perl($name);
   return "sub $name { $args_str $exprs_str }";
}

sub fn_to_perl {
   my $args = shift;
   my $fn_args = $args->[0][1];
   my $exprs =  rest($args);
   my $args_str = get_args_str($fn_args);
   my $exprs_strs = atoms_to_perl($exprs);
   my $exprs_str  = join_exprs($exprs_strs);
   return "sub { $args_str $exprs_str }";
}

sub get_args_str {
   my $args = shift;
   if (len($args) == 0) { return "" }
   my $args_strs = atoms_to_perl($args);
   my $args_str = join(',', @{$args_strs});
   if (len($args) == 1) {
      return "my $args_str = shift;";
   } else {
      return "my ($args_str) = \@_;";
   }
}

sub set_to_perl {
   my $args = shift;
   my $strs = atoms_to_perl($args);
   my $str  = join(' = ', @{$strs});
   return "$str";
}

## ================================
sub my_to_perl {
   my $args = shift;
   my $sym = $args->[0];
   my $strs = atoms_to_perl($args);
   my ($sym_name, $value_str) = @{$strs};
   if (is_atom_name($sym, 'List')) {
      return "my $sym_name = \@\{$value_str\};";
   }
   return "my $sym_name = $value_str";
}

sub list_to_perl {
   my $list = shift;
   my $strs = atoms_to_perl($list);
   my $str = join ', ', @{$strs};
   return "($str)";
}

## =================================

sub return_to_perl {
   my $args = shift;
   my $strs = atoms_to_perl($args);
   my $str = join ', ', @{$strs};
   return "return [$str]";
}

sub const_to_perl {
   my $args = shift;
   my ($name, $value) = @{ atoms_to_perl($args) };
   return "our $name = $value";
}

sub use_to_perl {
   my $args = shift;
   my $strs = atoms_to_perl($args);
   my $str   = join ' ', @{$strs};
   return "use $str;";
}

sub slist_to_perl {
   my $list = shift;
   my $strs = atoms_to_perl($list);
   my $str = join ' ', @{$strs};
   return "qw($str)";
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

sub sym_to_perl {
   my $name  = shift;
   my @chars = ();
   for my $char (split '', $name) {
      given ($char) {
         when ('-') { push @chars, '_' }
         when ('?') { push @chars, '_is' }
         when ('@') { push @chars, '$' }
         when ('%') { push @chars, '$' }
         default    { push @chars, $char }
      }
   }
   return join('', @chars);
}

sub ocall_to_perl {
   my $args = shift;
   my ($method, $args) = @{$args};
   my $method_name = sym_to_perl($method);
   my $strs = atoms_to_perl($args);
   my $object = shift @{$strs};
   my $args_str = join ', ', @{$strs};
   return "$object\->$method_name($args_str)";
}

sub onew_to_perl {
   my $args = shift;
   my ($method, $args) = @{$args};
   my $method_name = sym_to_perl($method);
   my $strs = atoms_to_perl($args);
   my $class = shift @{$strs};
   my $args_str = join ', ', @{$strs};
   return "$class\->$method_name($args_str)";
}

sub str_to_perl {
   my $str     = shift;
   if (is_str($str)) {
      if (index($str, "\n") > -1) {
         return "<<'EOFF';${str}EOFF\n";
      }
      return qq('$str');
   }
   if (is_atom($str)) { 
      my $char = $str->[1];
      return qq("$char");
   }
   return string_to_perl($str);
}

sub string_to_perl {
   my $atoms = shift;
   my $strs  = [];
   for my $atom (@{$atoms}) {
      my ($type, $value) = @{$atom};
      given ($type) {
         when ('Scalar') {
            my $name = sym_to_perl($value);
            push @{$strs}, $name;
         }
         default { push @{$strs}, $value }
      }
   }
   my $str = join('', @{$strs});
   if (index($str, "\n") > -1) {
      return "<<EOFF;\n$str\nEOFF\n";
   }
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
   my @strs = ();
   for my $pair (@{$pairs}) {
      my ($key, $value) = @{$pair};
      my $value_str = atom_to_perl($value);
      push @strs, "$key => $value_str";
   }
   my $pairs_str = join ', ', @strs;
   return "{$pairs_str} ";
}

## ===========================================
## Common Function
## ===========================================

sub ast_to_perl_repl {
   my $exprs = shift;
   my $exprs_strs = atoms_to_perl($exprs);
   my $exprs_str = join_exprs($exprs_strs);
   return $exprs_str;
}

sub atoms_to_perl {
   my $atoms = shift;
   return [ map { atom_to_perl($_) } @{$atoms} ];
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
   my $exprs     = shift;
   my $def_names = [];
   my $head_str  = '';
   my $flag      = 0;
   for my $expr (@{$exprs}) {
      my ($name, $value, $pos) = @{$expr};
      given ($name) {
         when ('def') {
            push @{$def_names}, $value->[0][0];
         }
         when ('ns') {
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
      my $export_str = get_export_str($def_names);
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
   my $names     = shift;
   my $names_str = join ' ',
     map { sym_to_perl($_) } @{$names};
   return <<"EOF";
use Exporter;
our \@ISA = qw(Exporter);
our \@EXPORT = qw($names_str);

EOF
}

sub tidy_perl {
   my $source_string = shift;
   my $dest_string;
   my $stderr_string;
   my $errorfile_string;
   my $argv = "-i=3 -l=60 -vt=2 -pt=2 -bt=1 -sbt=2 -bbt=1";
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
