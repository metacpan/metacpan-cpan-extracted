#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib ../lib );
use Pod::POM::Test;
#$Pod::POM::View::DEBUG = 1;
#$Pod::POM::Node::DEBUG = 1;

##------------------------------------------------------------------------
## NOTE: this test doesn't do much (yet)
##------------------------------------------------------------------------

my $DEBUG = 1;

ntests(5);

my $parser = Pod::POM->new();
my $pom = $parser->parse_file(\*DATA);
assert( defined $pom );

my $head1 = $pom->head1->[0];
assert( defined $head1 );

my $head2 = $head1->head2->[0];
assert( defined $head2 );

my $list = $head2->over->[0];
assert( defined $list );

my $text = $head2->text->[0];
assert( defined $text );

{ 
    no warnings 'once';  # $Pod::POM::ERROR is only used once
    Pod::POM->default_view('Pod::POM::View::Text')
	|| die "$Pod::POM::ERROR\n";
}

# uncomment this to see the results
#print $pom;


__DATA__
=head1 Outer

This is the outer block following a =head1 a b c d e f g h i j k l m n
o p q r s t u v w x y z.

=head2 Inner Block for which I am obliged to provide a long an arduous title to ensure that it is correctly wrapped

This is the inner block following a =head2 a b c d e f g h i j k l m n
o p q r s t u v w x y z.

=over 4

This is the list block following an =over 4 a b c d e f g h i j k l m
n o p q r s t u v w x y z.

=item Wiz

This paragraph wraps onto several lines and hopefully will be
correctly formatted thanks to the Text::Wrap module.

=item Wiz Waz Woz Wuz Biz Baz Boz Buz Diz Daz Doz Duz Liz Laz Loz Luz Fiz Faz Foz Fuz

This paragraph wraps onto several lines and hopefully will be
correctly formatted thanks to the Text::Wrap module.

=back

