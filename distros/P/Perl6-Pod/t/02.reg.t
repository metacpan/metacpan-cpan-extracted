#########################
# Test pod blocks
#
package Perl6::Pod::To::Dump;
use base 'Perl6::Pod::Utl::AbstractVisiter';
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
    $self;
}

sub _dump_ {
    my $self = shift;
    my $el   = shift;
    ( my $type = ref($el) ) =~ s/.*:://;
    my %dump = ( class => $type );
    unless ( UNIVERSAL::isa( $el, 'Perl6::Pod::Lex::Block' )
        || ref($el) eq 'HASH' )
    {
        use Data::Dumper;
        die "NOT VALIDE" . Dumper($el);
    }
    $dump{name}        = $el->{name}        if exists $el->{name};
    $dump{block_name}  = $el->{block_name}  if exists $el->{block_name};
    $dump{encode_name} = $el->{encode_name} if exists $el->{encode_name};
    $dump{alias_name}  = $el->{alias_name}  if exists $el->{alias_name};
    $dump{level}  = $el->{level}  if exists $el->{level};

    if ( my $attr = $el->{attr} ) {

        #        my @attr_dump = map { $_->dump() } @$attr;
        my @attr_dump = map {
            my $value = $_->{items};
            if ( $_->{type} eq 'hash' ) {
                my %hash = ();
                foreach my $item ( @{$value} ) {
                    $hash{ $item->{key} } = $item->{value};
                }
                $value = \%hash;
            }
            {
                name  => $_->{name},
                value => $value
            }

        } @$attr;
        if (@attr_dump) {
            $dump{attr} = \@attr_dump;
        }
    }
    unless ( UNIVERSAL::can( $el, 'childs' ) ) {
        use Data::Dumper;
        die 'bad element: ' . Dumper($el);
    }
    if ( my $content = $el->childs ) {
        warn Dumper($el) unless ref($content) eq 'ARRAY';

        $dump{content} = [
            map {
                    ref($_) ? $self->_dump_($_)
                  : $_ =~ /^\s+/ ? 'CODE'
                  : 'TEXT'

              } @{ $el->childs }
        ];

    }
    \%dump;
}

sub __default_method {
    my $self = shift;
    my $n    = shift;
    if ( ref($n) and ( ref($n) eq 'ARRAY' ) ) {
        return [ map { $self->_dump_($_) } @{$n} ];
    }
    return $self->_dump_($n);
}

1;

package main;
use strict;
use warnings;

use Test::More tests => 13;    # last test to print
use Perl6::Pod::Utl;
use Perl6::Pod::Lex;
use v5.10;
use Data::Dumper;

my $r = do {
    use Regexp::Grammars;
    use Perl6::Pod::Grammars;
    qr{
       <extends: Perl6::Pod::Grammar::Blocks>
       <matchline>
#       <debug:step>
        \A <File> \Z
    }xms;
};

my @t;
my $STOP_TREE = 1;

@t = ( '
text

=begin pod
=for Test :1
bracket sequence. For example:
=end pod
'
);

package main;
$STOP_TREE = 2;
$STOP_TREE = 0;

@t = ();
my @grammars = (
    '=begin pod
=for item
  dd  d
sdsdsd


=end pod
',
    [
        {
            'content' => [
                {
                    'content' => ['TEXT'],
                    'name'    => 'item',
                    'class'   => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block'
        }
    ],
    '=pod + text',

    '=begin pod
=begin para
=end para
=end pod
',
    [
        {
            'content' => [
                {
                    'name'  => 'para',
                    'class' => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block'
        }
    ],
    'para insite =pod',

    '=begin pod
=begin para
=begin para
text
=end para
=end para
=end pod
',
    [
        {
            'content' => [
                {
                    'content' => [
                        {
                            'content' => ['TEXT'],
                            'name'    => 'para',
                            'class'   => 'Block'
                        }
                    ],
                    'name'  => 'para',
                    'class' => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block'
        }
    ],
    'para inside para',

    '=begin pod
        =begin Sode
                asd
        =end Sode
    =begin code
      asd
    =end code

asdasd
=end pod
',
    [
        {
            'content' => [
                {
                    'content' => ['CODE'],
                    'name'    => 'Sode',
                    'class'   => 'Block'
                },
                {
                    'content' => ['CODE'],
                    'name'    => 'code',
                    'class'   => 'Block'
                },
                {
                    'content' => ['TEXT'],
                    'name'    => 'para',
                    'class'   => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block'
        }
    ],
    'raw content',
    '=begin pod
=for Para
asd
   =for code
   sd
=for para
re
=end pod
',
    [
        {
            'content' => [
                {
                    'content' => ['TEXT'],
                    'name'    => 'Para',
                    'class'   => 'Block'
                },
                {
                    'content' => ['TEXT'],
                    'name'    => 'code',
                    'class'   => 'Block'
                },
                {
                    'content' => ['TEXT'],
                    'name'    => 'para',
                    'class'   => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block'
        }
    ],
    'paragraph_block (with text and raw)',

    '=begin pod  :test
= :t :r[1,2, "r"] :s<1 2 3322>
= :!t
d
=end pod
',
    [
        {
            'content' => [
                {
                    'content' => ['TEXT'],
                    'name'    => 'para',
                    'class'   => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block',
            'attr'  => [
                {
                    'value' => 1,
                    'name'  => 'test'
                },
                {
                    'value' => 1,
                    'name'  => 't'
                },
                {
                    'value' => [ '1', '2', 'r' ],
                    'name'  => 'r'
                },
                {
                    'value' => [ '1', '2', '3322' ],
                    'name'  => 's'
                },
                {
                    'value' => 0,
                    'name'  => 't'
                }
            ]
        }
    ],
    'attributes',
    '=begin pod :r<test> :name{ t=>1, t2=>1}
s
=end pod
',
    [
        {
            'content' => [
                {
                    'content' => ['TEXT'],
                    'name'    => 'para',
                    'class'   => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block',
            'attr'  => [
                {
                    'value' => 'test',
                    'name'  => 'r'
                },
                {
                    'value' => {
                        't2' => '1',
                        't'  => '1'
                    },
                    'name' => 'name'
                }
            ]
        }
    ],
    'attrs: hash',

    '=begin pod
   =begin OO
     ed
   =end OO
sdsd

 d
sdsdsds

=end pod
',
    [
        {
            'content' => [
                {
                    'content' => [
                        {
                            'content' => [ 'CODE' ],
                            'name'    => 'code',
                            'class'   => 'Block'
                        }
                    ],
                    'name'  => 'OO',
                    'class' => 'Block'
                },
                {
                    'content' => [ 'TEXT' ],
                    'name'    => 'para',
                    'class'   => 'Block'
                },
                {
                    'content' => [ 'CODE' ],
                    'name'    => 'code',
                    'class'   => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block'
        }
    ],
    'text and verbatim blocks',
    'some parar
parapar
=begin pod
asdasd
=end pod
',
    [
        {
            'content' => [
                {
                    'content' => ['TEXT'],
                    'name'    => 'para',
                    'class'   => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block'
        }
    ],
    'ambient text',
    '=begin pod
=begin para
=config name :like<head1>
= :t
=end para
=end pod
',
    [
        {
            'content' => [
                {
                    'content' => [
                        {
                            'block_name' => 'name',

                            'name'  => 'config',
                            'class' => 'Block',
                            'attr'  => [
                                {
                                    'value' => 'head1',
                                    'name'  => 'like'
                                },
                                {
                                    'value' => 1,
                                    'name'  => 't'
                                }
                            ]
                        }
                    ],
                    'name'  => 'para',
                    'class' => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block'
        }
    ],
    '=config directive',
    '=begin pod
=encoding Macintosh
=encoding KOI8-R
=end pod
',
    [
        {
            'content' => [
                {
                    'encode_name' => 'Macintosh',
                    'name'        => 'encoding',
                    'class'       => 'Block'
                },
                {
                    'encode_name' => 'KOI8-R',
                    'name'        => 'encoding',
                    'class'       => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block'
        }
    ],
    '=encoding directive',
    '=begin pod
=alias PROGNAME    Earl Irradiatem Eventually
=                  =item  Also text
=end pod
',
[
            {
                'content' => [
                    {
                        'alias_name' => 'PROGNAME',
                        'name'       => 'alias',
                        'class'      => 'Block'
                    }
                ],
                'name'  => 'pod',
                'class' => 'Block'
            }
        ],
    '=alias directive'

);

@grammars = @t if scalar(@t);
while ( my ( $src, $extree, $name ) = splice( @grammars, 0, 3 ) ) {
    $name //= $src;
    my $dump;

    if ( $src =~ $r ) {
        my $tree = Perl6::Pod::Lex->new->make_tree( $/{File} );
        if ( $STOP_TREE == 2 ) { say Dumper($tree); exit; }
        $dump = Perl6::Pod::To::Dump->new->visit($tree);
    }
    else {
        fail($name);
        die "Can't parse: \n" . $src;

    }
    if ( $STOP_TREE == 1 ) { say Dumper($dump); exit; }

    is_deeply( $dump, $extree, $name )
      || do { say "fail deeply" . Dumper( $dump, $extree, ); exit; };

}

#check not ambient
@grammars = (
    'para texxt
=begin pod
text
=end pod

 codesd
',
    [
        {
            'content' => ['TEXT'],
            'name'    => 'para',
            'class'   => 'Block'
        },
        {
            'content' => [
                {
                    'content' => ['TEXT'],
                    'name'    => 'para',
                    'class'   => 'Block'
                }
            ],
            'name'  => 'pod',
            'class' => 'Block'
        },
        {
            'content' => ['CODE'],
            'name'    => 'code',
            'class'   => 'Block'
        }
    ],
    'check default pod content'

);

while ( my ( $src, $extree, $name ) = splice( @grammars, 0, 3 ) ) {
    $name //= $src;
    my $dump;
    
    if ( $src =~ $r ) {
        my $tree = Perl6::Pod::Lex->new(default_pod=>1)->make_tree( $/{File} );
        if ( $STOP_TREE == 2 ) { say Dumper($tree); exit; }
        $dump = Perl6::Pod::To::Dump->new->visit($tree);
    }
    else {
        fail($name);
        die "Can't parse: \n" . $src;

    }
    if ( $STOP_TREE == 1 ) { say Dumper($dump); exit; }

    is_deeply( $dump, $extree, $name )
      || do { say "fail deeply" . Dumper( $dump, $extree, ); exit; };

}

