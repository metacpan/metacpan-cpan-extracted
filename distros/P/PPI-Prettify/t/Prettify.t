use strict;
use warnings;
use Test::More tests => 22;
use PPI::Prettify;
use PPI::Document;

read( main::DATA, my $code, 1000 );
my $doc    = PPI::Document->new( \$code );
my @tokens = $doc->tokens;

# for debugging
if ( @ARGV and $ARGV[0] == 1 ) {
    print "Dumping tokens and values ...\n";
    for ( my $i = 0 ; $i < @tokens ; $i++ ) {
        print $i . ' '
          . ref( $tokens[$i] ) . ' '
          . $tokens[$i]->content . ' '
          . PPI::Prettify::_determine_token( $tokens[$i] ) . "\n";
    }
}

eval { prettify() };
ok( $@, 'Test failure on missing code arg' );

# typical token types
ok( 'PPI::Token::Keyword' eq PPI::Prettify::_determine_token( $tokens[0] ),
    'Package keyword identified as keyword' );
ok(
    'PPI::Token::Word::Package' eq
      PPI::Prettify::_determine_token( $tokens[2] ),
    'Package name identified as package'
);
ok( 'PPI::Token::Function' eq PPI::Prettify::_determine_token( $tokens[10] ),
    'use identified as function' );
ok( 'PPI::Token::Pragma' eq PPI::Prettify::_determine_token( $tokens[12] ),
    'warnings identified as pragma' );
ok(
    'PPI::Token::KeywordFunction' eq
      PPI::Prettify::_determine_token( $tokens[28] ),
    'BEGIN identified as keyword'
);
ok( 'PPI::Token::Pragma' eq PPI::Prettify::_determine_token( $tokens[41] ),
    'base identified as pragma' );
ok( 'PPI::Token::Symbol' eq PPI::Prettify::_determine_token( $tokens[49] ),
    '@EXPORT identified as symbol' );
ok( 'PPI::Token::Comment' eq PPI::Prettify::_determine_token( $tokens[61] ),
    'comment identified' );
ok( 'PPI::Token::Pod' eq PPI::Prettify::_determine_token( $tokens[63] ),
    'Pod identified' );
ok( 'PPI::Token::Keyword' eq PPI::Prettify::_determine_token( $tokens[65] ),
    'sub identified as keyword type' );
ok( 'PPI::Token::Number' eq PPI::Prettify::_determine_token( $tokens[189] ),
    'number 1 identified as number type' );
ok(
    'PPI::Token::Separator' eq PPI::Prettify::_determine_token( $tokens[192] ),
    '__END__ identified as separator'
);

# harder cases
ok(
    'PPI::Token::Symbol' eq PPI::Prettify::_determine_token( $tokens[89] ),
    'length identified as method call (symbol) not built-in'
);
ok(
    'PPI::Token::QuoteLike::Words' eq
      PPI::Prettify::_determine_token( $tokens[109] ),
    'quote whitespace identified'
);
ok( 'PPI::Token::Symbol' eq PPI::Prettify::_determine_token( $tokens[123] ),
    'STDOUT identified as symbol' );
ok( 'PPI::Token::Function' eq PPI::Prettify::_determine_token( $tokens[136] ),
    'length identified as function inside brackets' );
ok( 'PPI::Token::Function' eq PPI::Prettify::_determine_token( $tokens[147] ),
    'length identified as function inside brackets' );
ok( 'PPI::Token::Quote' eq PPI::Prettify::_determine_token( $tokens[157] ),
    'length identified as quote inside brackets' );
ok( 'PPI::Token::Function' eq PPI::Prettify::_determine_token( $tokens[165] ),
    'first length identified as function inside brackets' );
ok( 'PPI::Token::Function' eq PPI::Prettify::_determine_token( $tokens[167] ),
    'second length identified as function inside brackets' );
ok( 'PPI::Token::Quote' eq PPI::Prettify::_determine_token( $tokens[177] ),
    'length identified as quote not built-in' );

__DATA__
package Test::Package;
use strict;
use warnings;
use feature 'say';
use Example::Module;

BEGIN {
    require Exporter;
    use base qw(Exporter);
    our @EXPORT = ('example_sub');
}

# this is a comment

=head2 example_sub

example_sub is an example sub the subroutine markup;

=cut

sub do_something {
    my ($self, $args) = shift;
    $self->length;
    return $self->do_something;
}

my @array = qw/1 2 3/;
my $scalar = 'some text';
print STDOUT $scalar;

my %hash;
$hash{length($scalar)}; # built in
$hash{length @array};   # built in
$hash{length};          # string
$hash{length length}    # built ins

do_something({ length => 5 }); # hash key
1;
__END__
