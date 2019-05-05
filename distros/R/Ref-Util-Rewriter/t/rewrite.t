use strict;
use warnings;
use Test::More tests => 16;

BEGIN {
    use_ok('Ref::Util::Rewriter');
}

can_ok(
    Ref::Util::Rewriter::,
    qw<rewrite_doc rewrite_string rewrite_file>,
);

my @tests = (
    q{ref $foo eq 'ARRAY';}        => q{is_arrayref($foo);},
    q{ref $foo eq 'CODE';}        => q{is_coderef($foo);},
    q{ref $foo eq 'CODE' && ref $foo eq 'ARRAY';}        => q{is_coderef($foo) && is_arrayref($foo);},
    q{ref($foo) eq 'ARRAY';}       => q{is_arrayref($foo);},
    q{ref  ($foo) eq 'ARRAY';}     => q{is_arrayref($foo);},
    q{ref($foo) or}                => q{is_ref($foo) or},
    q!if (ref($foo) eq 'ARRAY') {! => q!if (is_arrayref($foo)) {!,
    q{ref($foo) eq 'ARRAY' or}     => q{is_arrayref($foo) or},

    # a few edge cases
    q!sub { my $is_arrayref = ref $self eq 'ARRAY'; }! => q!sub { my $is_arrayref = is_arrayref($self); }!,
    q!sub { my $is_arrayref = ref $self eq 'ARRAY' && $x == 42; }! => q!sub { my $is_arrayref = is_arrayref($self) && $x == 42; }!,
    q!sub {return ref($self) eq 'CODE'; }! => q!sub {return is_coderef($self); }!,

    # Eval tests
    q[eval q{ref $foo eq 'ARRAY'}] => q[eval q{is_arrayref($foo)}],
    q[eval q/ref $foo eq 'ARRAY'/] => q[eval q/is_arrayref($foo)/],
    q[eval "ref $foo eq 'ARRAY'"]  => q[eval "is_arrayref($foo)"],

    # not supported (yet?)
    #qq{ref(\$foo) # comment\nor}   => q{is_ref($foo) or # comment},
);

while ( my ( $input, $expect ) = splice @tests, 0, 2 ) {
    my $test_name = $input;
    my $output    = Ref::Util::Rewriter::rewrite_string($input);
    is( $output, $expect, $test_name, );    # or diag main::dump($output);

}

sub dump {
    my $s = shift or return;

    require PPI::Dumper;
    require PPI::Document;
    my $str = eval {
        my $doc  = PPI::Document->new( \$s );
        my $dump = PPI::Dumper->new($doc);
        $dump->string;
    };

    return 'ERROR' unless defined $str;
    return $str;

}
