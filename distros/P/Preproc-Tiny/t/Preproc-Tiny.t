#!perl

use strict;
use warnings;
use Test::More;
use Capture::Tiny ':all';
use Path::Tiny;
use Test::Differences;

BEGIN { use_ok('Preproc::Tiny') };

my @in_files;
my @out_files;
my @pl_files;
for (1..2) {
	push @in_files,  "test.$_.c.pp";
	push @out_files, "test.$_.c";
	push @pl_files,  "test.$_.c.pl";
}

sub write_input {
	my($in) = @_;
	for (@in_files) {
		path($_)->spew($in);
	}
}

sub check_output {
	my($out) = @_;
	for (@out_files) {
		ok -f $_;
		eq_or_diff path($_)->slurp, $out;
	}
}

sub test {
	my($in, $out) = @_;
	
	write_input($in);
	
	ok 1, "line ".(caller)[2]." - call script";
	unlink @out_files;
	ok 0 == system $^X, 'blib/bin/pp.pl', @in_files;
	check_output($out);
	
	ok 1, "line ".(caller)[2]." - call module";
	unlink @out_files;
	ok 0 == system $^X, 'blib/lib/Preproc/Tiny.pm', @in_files;
	check_output($out);
	
	ok 1, "line ".(caller)[2]." - use module";
	unlink @out_files;
	pp(@in_files);
	check_output($out);
	
	unlink @in_files, @out_files;
}

test(<<'IN', <<'OUT');
@@sub dup {
@@	$_[0]*2;
@@}
@@$name = "John Doe";
Hello [@> $name @]!
Hi there [@> $name -@]

!
Howdy [@> $name @]
.
[@ for (1..4) { -@]
	[@> dup($_) @] [@ 
} @]
[@ $OUT .= "xx\n"; @]
IN
Hello John Doe!
Hi there John Doe!
Howdy John Doe
.
2 4 6 8 
xx

OUT


test(<<'IN', <<'OUT');
int main() { return 0; }
IN
int main() { return 0; }
OUT


test(<<'IN', <<'OUT');
@@ $ret = 0;
int main() { 
  return @@ $OUT .= $ret.";";
}
IN
int main() { 
  return 0;
}
OUT


test(<<'IN', <<'OUT');
[@ 
  use strict;
  use warnings;
  my $ret = 0;
@]
int main() { 
  return [@ $OUT .= $ret @];
}
IN

int main() { 
  return 0;
}
OUT


test(<<'IN', <<'OUT');
[@ 
  use strict;
  use warnings;
  my $ret = 0;
-@]
int main() { 
  return [@ $OUT .= $ret @];
}
IN
int main() { 
  return 0;
}
OUT


test(<<'IN', <<'OUT');
[@ 
  use strict;
  use warnings;
  my $ret = 0;
-@]
int main() { 
  return [@> $ret @];
}
IN
int main() { 
  return 0;
}
OUT


test(<<'IN', <<'OUT');
int main() {
  return 0;  // comment
}
@@ $OUT =~ s!//.*!!g;
IN
int main() {
  return 0;  
}
OUT


test(<<'IN', <<'OUT');
@@ $ok = 1;
int main() {
  return [@ if ($ok) { @] 0 [@ } else { @] 1 [@ } @];
}
IN
int main() {
  return  0 ;
}
OUT


write_input(<<'IN');
@@ ok=1
IN


my($stderr, $result) = capture_stderr { system $^X, 'blib/bin/pp.pl' };
ok $result != 0;
like $stderr, qr/Usage: pp\.pl file\.pp\.\.\./;

($stderr, $result) = capture_stderr { system $^X, 'blib/bin/pp.pl', $in_files[0] };
ok $result != 0;
like $stderr, qr/Can't modify constant item in scalar assignment at test.1.c.pl line/;
like $stderr, qr/$in_files[0]: parse error/;


unlink @in_files, @out_files, @pl_files;
done_testing;
