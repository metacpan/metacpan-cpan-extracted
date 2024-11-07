#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use Nice::Try;
};

use strict;
use warnings;
our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;

sub foo
{
    my $rv = '';
    try
    {
        $rv .= $_ while( <DATA> );
    }
    catch( $e )
    {
        $rv = 'failed';
    }
    return( $rv );
}

my $expect = <<EOT;
Mignonne, allons voir si la rose
Qui ce matin avoit desclose
Sa robe de pourpre au Soleil,
A point perdu ceste vesprée
Les plis de sa robe pourprée,
Et son teint au vostre pareil.

EOT

is( &foo, $expect, '__DATA__' );

done_testing();

__DATA__
Mignonne, allons voir si la rose
Qui ce matin avoit desclose
Sa robe de pourpre au Soleil,
A point perdu ceste vesprée
Les plis de sa robe pourprée,
Et son teint au vostre pareil.
