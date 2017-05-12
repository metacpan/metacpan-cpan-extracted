use strict;
use warnings;
use Test::More tests => 47;
use Test::Exception;

use Perl6::Signature;

# Signature values and pretty-printing
# L<S06/"Parameters and arguments">
{
    # let's start with valid signatures whose canonical stringy form looks
    # just like their source. I incidentally use different sigils, can't
    # throw in the complete cartesian product here...
    my @sigs =
        ( ':()',                  'empty signature',
        , ':($x)',                'single required positional'
        , ':($x:)',               'invocant only'
        , ':(@x, $y)',            'two required positionals'
        , ':($x, %y?)',           'required and optional positionals'
        , ':($x is rw is ref is lazy is moose)', # note order matters :/
                                  'traits (including user defined)'
        , ':($x where { $x->isa("Moose") })',
                                  'constraint',
        , ':($x where { $x->isa("Moose") } where { $x->does("Gimble") })',
                                  'two constraints',
        , ':(Int $x)',            'typed parameter',
        , ':(Int $x, Str $y)',    'two typed parameter',
        , ':($x, $y, :$z)',       'positional and named'
        , ':($x, $y?, :$z)',      'optional positional and named'
        , ':(:$x)',               'optional named'
        , ':(:$x!)',              'required named'
        , ':(:short($long))',     'long named'
        , ':(:short($long)!)',    'required long named'
        , ':($: %x)',             'dummy invocant'
        , ':($x :($y))',          'unpacking(1)'
        , ':($x :($y: $z))',      'unpacking(2)'
        , ':($x = 42)',           'positional with default'
        , ':(@x = (1, 2))',       'positional array with default'
        , ':(%x = (1 => 2))',     'positional hash with default'
        , ':(:$x = 42)',          'named with default'
        , ':(:@x = (1, 2))',      'named array with default'
        , ':(:%x = (1 => 2))',    'named hash with default'
        , ':(:x($y) = 42)',       'longnamed with default'
        , ':(:x(@y) = (1, 2))',   'longnamed array with default'
        , ':(:x(%y) = (1 => 2))', 'longnamed hash with default'
        , ':(Int|Str $x)',        'type constraint alternative'
        );
    while (my ($sig, $desc) = splice @sigs, 0, 2) {
        lives_and { is(Perl6::Signature->parse($sig)->to_string, $sig) } "$desc - $sig";
    }

    # alternate whitespace/formatting tests
    @sigs =
        ( ':( )',                 ':()',                  'empty signature',
        , ':($x!)',               ':($x)',                'required positional, explicit "!"'
        , ':($x )',               ':($x)',                'single required positional'
        , ':($x: )',              ':($x:)',               'invocant only'
        , ':($x : )',             ':($x:)',               'invocant only, 2'
        , ':(@x,$y)',             ':(@x, $y)',            'two required positionals'
        , ':(@x,$y )',            ':(@x, $y)',            'two required positionals, 2'
        , ':($x,%y?)',            ':($x, %y?)',           'required and optional positionals'
        , ':(:$x?)',              ':(:$x)',               'optional short named, explicit "?"'
        , ':(:short($long)?)',    ':(:short($long))',     'optional long named, explicit "?"'
        , ':(*@x, $y)',           ':($y, *@x)',           'slurpy array and positional'
        , ':(*%x, $y)',           ':($y, *%x)',           'slurpy hash and positional'
        , ':(*%x, $y, *@x)',      ':($y, *@x, *%x)',      'slurpy hash and positional'
        , ':(Int | Str $x)',      ':(Int|Str $x)',        'type constraint alternative with whitespce'
        );
    while (my ($sig, $canonical, $desc) = splice @sigs, 0, 3) {
        lives_and { is(Perl6::Signature->parse($sig)->to_string, $canonical) } "(altspace) $desc";
    }

    my @badsigs =
        ( ':($x?:)',              'optional invocant'
        , ':($x?, $y)',           'required positional after optional one'
        , ':(Int| $x)',           'invalid type alternation',
        , ':(|Int $x)',           'invalid type alternation',
        );
    while (my ($badsig, $desc) = splice @badsigs, 0, 2) {
        dies_ok { Perl6::Signature->parse($badsig) } "(badsig) $desc";
    }
}

# vim:ft=perl:
