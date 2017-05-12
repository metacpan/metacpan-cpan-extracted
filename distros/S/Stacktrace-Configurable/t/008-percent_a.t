#!perl

use strict;
use warnings;
use Test::More;
use Stacktrace::Configurable;
use utf8;

my $trace = Stacktrace::Configurable->new;
my $res;

my $l1_line = __LINE__;
sub l1 {$res = $trace->get_trace->as_string}

delete $ENV{STACKTRACE_CONFIG};

{
    $trace->format='y%ax';
    l1;

    my $exp=<<"EOF"; chomp $exp;
y()x
EOF

    is $res, $exp, '%a w/o parameters';
}

{
    $trace->format='y%ax';
    l1 (1, "a\n\303\0b", "äö", "бля", $trace,
        my $arr=[], my $hash={}, my $sub=sub{19});

    my $exp=<<"EOF"; chomp $exp;
y(1, "a\\n\\303\\0b", "\\x{e4}\\x{f6}", "\\x{431}\\x{43b}\\x{44f}", $trace, $arr, $hash, $sub)x
EOF

    is $res, $exp, '%a w/ parameters';
}

{
    $trace->format='y%[dump]ax';
    l1 (my $obj=Stacktrace::Configurable->new(format=>'%l'),
        my $arr=[43], my $hash={p=>101}, my $sub=sub{19});

    my $exp=<<"EOF"; chomp $exp;
y(bless( {"format" => "%l"}, 'Stacktrace::Configurable' ), [43], {"p" => 101}, sub { "DUMMY" })x
EOF

    is $res, $exp, '%[dump]a';
}

{
    $trace->format='y%[dump,deparse]ax';
    l1 (my $obj=Stacktrace::Configurable->new(format=>'%l'),
        my $arr=[43], my $hash={p=>101}, my $sub=do {no strict;
                                                     sub{19}});

    my $deparse = Data::Dumper->new([$sub])->Useqq(1)->Deparse(1)
                              ->Terse(2)->Indent(0)->Dump;

    my $exp=<<"EOF"; chomp $exp;
y(bless( {"format" => "%l"}, 'Stacktrace::Configurable' ), [43], {"p" => 101}, $deparse)x
EOF

    is $res, $exp, '%[dump,deparse]a';
}

{
    local $ENV{DUMP};
    $trace->format='y%[env=DUMP]ax';
    l1 (my $obj=Stacktrace::Configurable->new(format=>'%l'),
        my $arr=[43], my $hash={p=>101}, my $sub=sub{19});

    my $exp=<<"EOF"; chomp $exp;
y($obj, $arr, $hash, $sub)x
EOF

    is $res, $exp, '%[env=DUMP]a -- DUMP not set';
}

{
    local $ENV{DUMP}='dump';
    $trace->format='y%[env=DUMP]ax';
    l1 (my $obj=Stacktrace::Configurable->new(format=>'%l'),
        my $arr=[43], my $hash={p=>101}, my $sub=sub{19});

    my $exp=<<"EOF"; chomp $exp;
y(bless( {"format" => "%l"}, 'Stacktrace::Configurable' ), [43], {"p" => 101}, sub { "DUMMY" })x
EOF

    is $res, $exp, '%[env=DUMP]a -- DUMP=dump';
}

{
    local $ENV{DUMP}='dump=ARRAY, dump=CODE';
    $trace->format='y%[env=DUMP]ax';
    l1 (my $obj=Stacktrace::Configurable->new(format=>'%l'),
        my $arr=[43], my $hash={p=>101}, my $sub=sub{19});

    my $exp=<<"EOF"; chomp $exp;
y($obj, [43], $hash, sub { "DUMMY" })x
EOF

    is $res, $exp, '%[env=DUMP]a -- DUMP=\'dump=ARRAY, dump=CODE\'';
}

{
    local $ENV{DUMP}='dump=/trace/, dump=CODE';
    $trace->format='y%[env=DUMP]ax';
    l1 (my $obj=Stacktrace::Configurable->new(format=>'%l'),
        my $arr=[43], my $hash={p=>101}, my $sub=sub{19});

    my $exp=<<"EOF"; chomp $exp;
y(bless( {"format" => "%l"}, 'Stacktrace::Configurable' ), $arr, $hash, sub { "DUMMY" })x
EOF

    is $res, $exp, '%[env=DUMP]a -- DUMP=\'dump=/trace/, dump=CODE\'';
}


{
    $trace->format='y%[multiline]ax';
    l1 (my $obj=Stacktrace::Configurable->new(format=>'%l'),
        my $arr=[43], my $hash={p=>101}, my $sub=sub{19});

    my $exp=<<"EOF"; chomp $exp;
y(
        $obj,
        $arr,
        $hash,
        $sub
    )x
EOF

    is $res, $exp, '%[multiline]a';
}

{
    $trace->format='y%[multiline=6]ax';
    l1 (my $obj=Stacktrace::Configurable->new(format=>'%l'),
        my $arr=[43], my $hash={p=>101}, my $sub=sub{19});

    my $exp=<<"EOF"; chomp $exp;
y(
          $obj,
          $arr,
          $hash,
          $sub
      )x
EOF

    is $res, $exp, '%[multiline=6]a';
}

{
    $trace->format='%s %[multiline=6.2]ax';
    l1 (my $obj=Stacktrace::Configurable->new(format=>'%l'),
        my $arr=[43], my $hash={p=>101}, my $sub=sub{19});

    my $exp=<<"EOF"; chomp $exp;
main::l1 (
        $obj,
        $arr,
        $hash,
        $sub
      )x
EOF

    is $res, $exp, '%[multiline=6.2]a';
}

done_testing;
