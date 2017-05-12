
=for Explanation:
     Check whether after blessing works as expected

=cut

BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

# be as strict and verbose
use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    $ENV{OOB_DEBUG} = 1;
    $SIG{__WARN__}  = sub { 1 }; # not interested in debug info, just "dump"
}    #BEGIN
use OOB qw( Attribute );

my $value = int rand 1000;

{
    my $foo;
    OOB->Attribute( \$foo, $value );
    is( OOB->Attribute( \$foo ), $value, 'check Attribute set' );

    bless \$foo, 'Foo';
    is( OOB->Attribute( \$foo ), $value, 'check Attribute set blessed Foo' );

    bless \$foo, 'Bar';
    is( OOB->Attribute( \$foo ), $value, 'check Attribute set blessed Bar' );
}

{
    my $foo;
    ok( !defined OOB->Attribute( \$foo ), 'check new foo not set' );
}

is( scalar( map { keys %{$_} } values %{ OOB::dump() } ), 0,
  "cleanup correct" );
