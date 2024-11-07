#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use Nice::Try;
#     use Nice::Try debug => 5, debug_code => 1, debug_dump => 1;
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

is( &foo, $expect, '__DATA__ mixed with POD' );

done_testing();

__DATA__
Mignonne, allons voir si la rose
Qui ce matin avoit desclose
Sa robe de pourpre au Soleil,
A point perdu ceste vesprée
Les plis de sa robe pourprée,
Et son teint au vostre pareil.

=encoding utf-8

=head1 NAME

Nice::Try::Testing - Testing Nice::Try DATA token

=head1 DESCRIPTION

This test is designed to recognise the data stored in the __DATA__ or __END__ section, while making a distinction between POD data and other data.

This POD, for example, will not be available in the C<DATA> IO.

So, if you do:

    print while( <DATA> );

You will get:

    Mignonne, allons voir si la rose
    Qui ce matin avoit desclose
    Sa robe de pourpre au Soleil,
    A point perdu ceste vesprée
    Les plis de sa robe pourprée,
    Et son teint au vostre pareil.

But, you will not get this POD data.

=cut
