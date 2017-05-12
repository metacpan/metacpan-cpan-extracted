use strict;
use warnings;
use Test::More qw/tests 29/;
#use Test::More qw/no_plan/;

BEGIN { use_ok('TX') };

my @list;
sub capture_list {
  push @list, $_[0] if length $_[0];
}

my $T=TX->new(delimiters=>[qw/<% %>/], path=>[qw!t/tmpl!], evalcache=>1);
my $v='keep';

is $T->include( 't1', {OUTPUT=>''}, v=>$v ), <<"EOF", 'output as string';
=========
  ${v}
=========
  [t1]${v}[/t1]
=========
  [m1]${v}[/m1]
=========
  [m2]${v}[/m2]
=========
EOF

cmp_ok \&TX::include, '==', \&TX::__::include, 'TX::__::include defined';

SKIP: {
  eval 'use Test::Output';
  $@ and skip 'Test::Output not installed', 1;

  stdout_is( sub {$T->include( 't1', v=>$v )}, <<"EOF", 'default output' );
=========
  ${v}
=========
  [t1]${v}[/t1]
=========
  [m1]${v}[/m1]
=========
  [m2]${v}[/m2]
=========
EOF
}

@list=();
$T->include( 't1', {OUTPUT=>\&capture_list}, v=>$v );
#use Data::Dumper; $Data::Dumper::Useqq=1; warn Dumper \@list;

my $expected=[
	      "=========\n  ",
	      $v,
	      "\n=========\n",
	      "  [t1]",
	      $v,
	      "[/t1]\n",
	      "=========\n",
	      "  [m1]".$v."[/m1]\n",
	      "=========\n",
	      "  [m2]",
	      $v,
	      "[/m2]\n",
	      "=========\n"
	     ];
is_deeply \@list, $expected, 'output to function';

$T->output=\&capture_list;
@list=();
$T->include( 't1', v=>$v );
is_deeply \@list, $expected, 'default output to function';

@list=();
$T->include( 't1', {PACKAGE=>'__DUMMY__'}, v=>$v );
is_deeply \@list, $expected, 'using PACKAGE=>__DUMMY__';
cmp_ok \&TX::include, '==', \&__DUMMY__::include, '__DUMMY__::include defined';

$T->export_include=0;
@list=();
eval {
  local $SIG{__WARN__}=sub{};
  $T->include( 't1', {PACKAGE=>'__DUMMY2__'}, v=>$v );
};
is_deeply \@list, [
		   "=========\n  ",
		   $v,
		   "\n=========\n",
		   "  [t1]",
		   $v,
		   "[/t1]\n",
		   "=========\n",
		   "  [m1]".$v."[/m1]\n",
		   "=========\n"
		  ], 'export_include=0';
like $@, qr/syntax error\b.+?\binclude\b/s, 'got syntax error';

cmp_ok ref($T->evalcache), 'eq', 'HASH', 'evalcache is a HASH';
cmp_ok scalar keys %{$T->evalcache}, '>', 0, 'and has entries';

$T->prepend='OUT 1/0;';
@list=();
eval {$T->include( 't1', {OUTPUT=>\&capture_list}, v=>$v )};
is_deeply \@list, $expected, 'after setting prepend to 1/0';
cmp_ok $@, 'eq', '', 'no exception';

$T->clear_cache;

@list=();
eval {$T->include( 't1', {OUTPUT=>\&capture_list}, v=>$v )};
is_deeply \@list, ["=========\n  "], 'after clearing cache';
like $@, qr/division by zero/, 'got exception';


# ADD_V NEW_V #####################################################
$T->prepend='';
$T->clear_cache;

$v='add';
is $T->include( 't1', {OUTPUT=>''}, v=>$v ), <<"EOF", 'ADD_V';
=========
  ${v}
=========
  [t1]${v}w[/t1]
=========
  [m1]${v}w[/m1]
=========
  [m2]${v}w[/m2]
=========
EOF

$v='new';
is $T->include( 't1', {OUTPUT=>''}, v=>$v ), <<"EOF", 'NEW_V';
=========
  ${v}
=========
  [t1]w[/t1]
=========
  [m1]w[/m1]
=========
  [m2]w[/m2]
=========
EOF

@list=();
$T->include( 't1', {OUTPUT=>\&capture_list}, v=>$v );
#use Data::Dumper; $Data::Dumper::Useqq=1; warn Dumper \@list;

$expected=[
	   "=========\n  ",
	   $v,
	   "\n=========\n",
	   "  [t1]",
	   "w",
	   "[/t1]\n",
	   "=========\n",
	   "  [m1]w[/m1]\n",
	   "=========\n",
	   "  [m2]",
	   "w",
	   "[/m2]\n",
	   "=========\n"
	  ];
is_deeply \@list, $expected, 'NEW_V: output to function';

cmp_ok @{$T->Fstack}+@{$T->Vstack}+@{$T->Ostack}+@{$T->Lstack}, '==', 0,
  'stacks cleared';

# auto reload #####################################################
$T->auto_reload_templates=1;
my @cachel=@{$T->cache->{t1}};

$v='keep';
$T->include( 't1', {OUTPUT=>''}, v=>$v );
is_deeply $T->cache->{t1}, \@cachel, 'template not reloaded';

rename 't/tmpl/t1.tmpl', 't/tmpl/t1.tmpl.old' or
  die "Cannot rename t/tmpl/t1.tmpl to t/tmpl/t1.tmpl.old: $!";
open my $fh, '>', 't/tmpl/t1.tmpl' or
  die "Cannot open t/tmpl/t1.tmpl for writing: $!";
print $fh do{local @ARGV=('t/tmpl/t1.tmpl.old'); <>} or
  die "Cannot write to t/tmpl/t1.tmpl: $!";
close $fh or
  die "Cannot write to t/tmpl/t1.tmpl: $!";

$T->output='';
is $T->include( 't1', v=>$v ), <<"EOF", 't1 still yields the same result';
=========
  ${v}
=========
  [t1]${v}[/t1]
=========
  [m1]${v}[/m1]
=========
  [m2]${v}[/m2]
=========
EOF

isnt $T->cache->{t1}->[0], $cachel[0], 'but it has been reloaded';

# binmode=utf8 ####################################################
$T->output='';
my $string=$T->include
  ( {filename=>'huhu',
     template=>">>>\n<% OUT include 'lib#m3', {VMODE=>'KEEP'} %><<<\n"}, v=>$v );
cmp_ok length($string), '==', 30, 'length should be 28 but is 30 (expected)';

$T->clear_cache('!li');
$T->binmode=':utf8';

$string=$T->include
  ( {filename=>'huhu',
     template=>">>>\n<% OUT include 'lib#m3', {VMODE=>'KEEP'} %><<<\n"}, v=>$v );
cmp_ok length($string), '==', 28, 'length is now 28 (due to utf8 input mode)';

# exception objects ###############################################
$T->clear_cache;
undef $T->binmode;
undef $string;

$string=eval {
  $T->include
    ( {filename=>'huhu',
       template=>"###\n<% OUT include 'lib#m3', {VMODE=>'KEEP'}; die 'error' %>%%%\n"}, v=>$v );
};

ok !defined($string), 'undef result on error';
is $@, "Template Error in huhu(2): error at huhu line 2.\n",
   'error reported at line 2 in file "huhu"';

$T->clear_cache;
$string=eval {
  $T->include
    ( {filename=>'huhu',
       template=>"###\n<% OUT 'huhu'; include 'lib#m3', {VMODE=>'KEEP'}; die ['error'] %>%%%\n"}, v=>$v );
};

ok !defined($string), 'undef result on error';
ok ref($@) && $@->[0] eq 'error',
   'exception object passed down correctly';

# Local Variables:
# mode: cperl
# End:
