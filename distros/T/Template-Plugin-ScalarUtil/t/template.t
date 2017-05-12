#!perl -T

use strict;
use warnings;

use Test::More tests => 14;
use Test::NoWarnings;

use Template;

my %setup = (
    'booleans' => {
        commands => [
             qw(
                blessed
                looks_like_number
                openhandle
                isvstring
                tainted
            )
        ],
        results => {
            TRUE => '',
            FALSE => 'not_',
        },
    },
    'custom' => {
        commands => [qw(
            dualvar
            refaddr
            reftype
        )],
        results => {
            dualvar => '12==12',
            refaddr => qr/^\d+$/,
            reftype => join(', ',
                'scalar=',
                '\\$var=SCALAR',
                'bless({},$class)=HASH',
                'bless([],$class)=ARRAY',
                '\\*STDIN=GLOB',
                '[]=ARRAY',
                '{}=HASH',
                'qr/.*/='. ( $] < 5.011 ? 'SCALAR' : 'REGEXP' ),
                'sub{"DUMMY"}=CODE',
            ),
        }
    }
);

for my $command ( @{ $setup{booleans}->{commands} } ) {
    while (my ($expected, $prefix) = each %{ $setup{booleans}->{results} } ) {
        is process_tt('boolean', $command, "$prefix$command"), $expected,
            "$command returns expected $expected";
    }
}

for my $command ( @{ $setup{custom}->{commands} } ) {
    my $expected = $setup{custom}->{results}->{$command};
    my $result = process_tt($command, $command, $command);
    if ( ref $expected ) {
        like $result, $expected,
            "$command returns expected $result";
    } else {
        is $result, $expected,
            "$command returns expected $result";
    }
}

## subs

sub process_tt {
    my $type = shift;
    my $command = shift;
    my $var = shift;

    my $tt = Template->new({
        PRE_CHOMP => 3,
        POST_CHOMP => 3,
    });
    my $template = create_template();
    my $vars = make_vars();
    my $output;

    my $args = {
        type => $type,
        command => $command,
        vars => $vars,
        var => $var,
    };

    $tt->process( \$template, $args, \$output );

    return $output;
}

sub make_vars {
    my $var = "I am a var";
    my $varref = \$var;
    my $fake_obj_hash = bless(
        {}, "My::Template::Plugin::ScalarUtil::Hash"
    );
    my $fake_obj_array = bless(
        [], "My::Template::Plugin::ScalarUtil::Array"
    );
    my $fh = \*STDIN;

    my $vars = {
        'blessed' => $fake_obj_hash,
        'not_blessed' => [],

        'looks_like_number' => 'Infinity',
        'not_looks_like_number' => 'Too many to count',

        'openhandle' => $fh,
        'not_openhandle' => "STDIN",

        'isvstring' => v49.46.48,
        'not_isvstring' => '49.46.48',

        'tainted' => $ENV{PATH},
        'not_tainted' => $var,

        'dualvar' => [5, "Hello"],

        'refaddr' => $varref,

        'reftype' => [
            'scalar' => "scalar",
            '\\$var' => \$var,
            'bless({},$class)' => $fake_obj_hash,
            'bless([],$class)' => $fake_obj_array,
            '\\*STDIN' => $fh,
            '[]' => [],
            '{}' => {},
            'qr/.*/' => qr/.*/,
            'sub{"DUMMY"}' => sub {
                sub { "DUMMY" }
            },
        ],
    };

    return $vars;
}

sub create_template {
    return <<'EOT';
[%
    USE ScalarUtil;
    PROCESS "block_$type";
%]

[% BLOCK block_boolean %]
    [% ScalarUtil.$command( vars.item(var) ) ? "TRUE" : "FALSE" %]
[% END %]

[% BLOCK block_dualvar %]
    [% SET dv_var = vars.item(var); %]
    [% SET dv = ScalarUtil.dualvar( dv_var.0, dv_var.1 ); %]
    [% SET dv_num = dv + 7 %]
    [% SET dv_string = dv _ " world!" %]
    [% dv_num %] == [% dv_string.length %]
[% END %]

[% BLOCK block_refaddr %]
    [% ScalarUtil.refaddr( vars.item(var) ) %]
[% END %]


[% BLOCK block_reftype %]
    [%
    SET idx = 0;
    SET list = vars.item(var);
    WHILE idx < list.size;
        SET type = idx;
        SET val = idx + 1;
        idx = idx + 2;
    %]
        [% list.$type %]=[% ScalarUtil.reftype(list.$val) %]
        [% IF idx < list.size %], [%+ END %]
    [% END %]
[% END %]

EOT

}

__END__

