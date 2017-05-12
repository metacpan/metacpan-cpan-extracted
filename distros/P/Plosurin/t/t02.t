#===============================================================================
#
#  DESCRIPTION:  Test soy syntax
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================

package main;
use strict;
use warnings;

use Test::More tests => 15;    # last test to print
use Data::Dumper;
use v5.10;
use Regexp::Grammars;
use Plosurin::Grammar;
use Plosurin::SoyTree;

my $q = qr{
     <extends: Plosurin::Grammar>
    <debug:step>
    \A  <[content]>* \Z
}xms;

my @t;
my $STOP_TREE = 0;

# Looks like you failed 1 test of 1.
@t = ();

@t = (
    '<test>
    {foreach $o in $s }1
    {ifempty} olo
    {/foreach}
{print $a}'
);
@t = ();

my @grammars = (
    "<h1>test</h2>", [
        {
            'Soy::raw_text' => {}
        }
    ], 'raw text',
    '{$acr}', [ {
            'Soy::command_print' => {}
        } ], undef,

    "{print 2}", [
        {
            'Soy::command_print' => {}
        }
    ], 'print',

    "{if 2} {/if}",
    [
        {
            'Soy::command_if' => {
                'if' => {
                    'expression' => {},
                    'childs'     => [ { 'Soy::raw_text' => {} } ]
                }
            }
        }
    ],
    "{if}..{/if}",

    '{if 2} raw text {elseif 34}  asdasd{else} none {/if}',
    [
        {
            'Soy::command_if' => {
                'else' => {
                    'Soy::command_else' =>
                      { 'childs' => [ { 'Soy::raw_text' => {} } ] }
                },
                'elseif' => [
                    {
                        'Soy::command_elseif' => {
                            'expression' => {},
                            'childs'     => [ { 'Soy::raw_text' => {} } ]
                        }
                    }
                ],
                'if' => {
                    'expression' => {},
                    'childs'     => [ { 'Soy::raw_text' => {} } ]
                }
            }
        }
    ],
    "{if}..{elseif}..{/if}",

    "{if 2} raw text {else} none {/if}",
    [
        {
            'Soy::command_if' => {
                'else' => {
                    'Soy::command_else' =>
                      { 'childs' => [ { 'Soy::raw_text' => {} } ] }
                },
                'if' => {
                    'expression' => {},
                    'childs'     => [ { 'Soy::raw_text' => {} } ]
                }
            }
        }
    ],
    '{if}..{else}..{if}',

    "{if 2} raw text   
     {elseif 3}   1     
     {elseif 4}   3     
     {else} none  
     {/if}",
    [
        {
            'Soy::command_if' => {
                'else' => {
                    'Soy::command_else' =>
                      { 'childs' => [ { 'Soy::raw_text' => {} } ] }
                },
                'elseif' => [
                    {
                        'Soy::command_elseif' => {
                            'expression' => {},
                            'childs'     => [ { 'Soy::raw_text' => {} } ]
                        }
                    },
                    {
                        'Soy::command_elseif' => {
                            'expression' => {},
                            'childs'     => [ { 'Soy::raw_text' => {} } ]
                        }
                    }
                ],
                'if' => {
                    'expression' => {},
                    'childs'     => [ { 'Soy::raw_text' => {} } ]
                }
            }
        }
    ],
    '{if}..{elseif}..{elseif}..{else}..{if}',

    "{if 2} raw text
     {elseif 4}
         3 {print 4}   2{else}
         1
    {/if}",
    [
        {
            'Soy::command_if' => {
                'else' => {
                    'Soy::command_else' =>
                      { 'childs' => [ { 'Soy::raw_text' => {} } ] }
                },
                'elseif' => [
                    {
                        'Soy::command_elseif' => {
                            'expression' => {},
                            'childs'     => [
                                { 'Soy::raw_text'      => {} },
                                { 'Soy::command_print' => {} },
                                { 'Soy::raw_text'      => {} }
                            ]
                        }
                    }
                ],
                'if' => {
                    'expression' => {},
                    'childs'     => [ { 'Soy::raw_text' => {} } ]
                }
            }
        }
    ],
    "{if}..{elseif}..{print}..{else}..{/if}",

    #{call}
    '{call .test_template data="all"/}',
    [
        {
            'Soy::command_call_self' => {
                'attrs'    => { 'data' => 'all' },
                'template' => '.test_template'
            }
        }
    ],
    '{call../}',
    '{call .test }{param test : 1 /}{param data}text{/param}{/call}',
    [
        {
            'Soy::command_call' => {
                'template' => '.test',
                'childs'   => [
                    {
                        'Soy::command_param_self' => {
                            'value' => '1',
                            'name'  => 'test'
                        }
                    },
                    {
                        'Soy::command_param' => {
                            'name'   => 'data',
                            'childs' => [ { 'Soy::raw_text' => {} } ]
                        }
                    }
                ]
            }
        }
    ],
    undef,

    '{call test.ok}{param t }<br/>{/param}{param d : 1 /}{/call}',
    [
        {
            'Soy::command_call' => {
                'template' => 'test.ok',
                'childs'   => [
                    {
                        'Soy::command_param' => {
                            'name'   => 't',
                            'childs' => [ { 'Soy::raw_text' => {} } ]
                        }
                    },
                    {
                        'Soy::command_param_self' => {
                            'value' => '1',
                            'name'  => 'd'
                        }
                    }
                ]
            }
        }
    ],
    undef,

    '{import file="test.pod6" /}',
    [ { 'Soy::command_import' => { 'attrs' => { 'file' => 'test.pod6' } } } ],
    undef,

    '{import file="test.pod6" rule=":include" /}',
    [
        {
            'Soy::command_import' => {
                'attrs' => {
                    'file' => 'test.pod6',
                    'rule' => ':include'
                }
            }
        }
    ],
    undef,

    '{foreach $o in $s }1{/foreach}',
    [
        {
            'Soy::command_foreach' =>
              { 'childs' => [ { 'Soy::raw_text' => {} } ] }
        }
    ],
    '{foreach ...}...{/foreach}',

    '{foreach $o in $s }1{ifempty}2{/foreach}',
    [
        {
            'Soy::command_foreach' => {
                'ifempty' => { 'childs' => [ { 'Soy::raw_text' => {} } ] },
                'childs' => [ { 'Soy::raw_text' => {} } ]
            }
        }
    ],
    '{foreach ...}...{ifempty}...{/foreach}'

);

@grammars = @t if scalar(@t);
while ( my ( $src, $extree, $name ) = splice( @grammars, 0, 3 ) ) {
    $name //= $src;
    my $plo = Plosurin::SoyTree->new( src => $src );
    unless ( ref($plo) ) { fail($name) }

    #setup lines and files
    use Plosurin::Utl::SetLinePos;
    my $line_num_visiter = new Plosurin::Utl::SetLinePos::
      offset  => 0,
      srcfile => 'tests';

    #    if ($STOP_TREE) { say Dumper( $plo->raw_tree ); exit; }
    my $dtree = $line_num_visiter->visit( $plo->raw_tree->{content} );

    if ($STOP_TREE) { say Dumper( $plo->raw_tree ); exit; }
    my $tree     = $plo->reduced_tree($dtree);
    my $res_tree = $plo->dump_tree($tree);
    is_deeply( $res_tree, $extree, $name )
      || do { say "fail Deeeple" . Dumper( $res_tree, $extree, ); exit; };

}

