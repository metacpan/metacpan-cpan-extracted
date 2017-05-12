# -*- perl -*-

# Testing of Pod::Compiler
# Author: PodMaster

$| = 1;

use Test::More tests => 13;

BEGIN { use_ok( 'Pod::Compiler' ); }


my $p = Pod::Compiler->new(-warnings=>0,-errors=>0);
isa_ok ($p, 'Pod::Compiler');
$p->parse_from_filehandle(\*DATA);
ok( $p->root(), "got root");

# these really belong in Pod::Compiler's test suite, but i need them too
my $collection = $p->root()->nodes();
ok( $collection, "got collection");
ok( 3 == @$collection, "collection got 3 nodes");
ok( $collection->get_by_text('target one'), "->get_by_text('target one')");
ok( $collection->get_by_text('hello target item'), "->get_by_text('hello target item')");
ok( $collection->get_by_text('target X'), "->get_by_text('target X')");
ok( $collection->get_by_id('target_x'), "->get_by_id('target_x')");

my @links;
$p->root()->walk_down( {
    callback => sub {
        my( $link ) = @_;
        return 1 unless $link->isa('Pod::link');
        push @links,$link;
        return 1;
    },
});

is( scalar @links, 3 , "ensure two links");
is( $links[0]->type, 'url', "ensure type is url");
is( $links[1]->type, 'url', "ensure type is url");
is( $links[2]->type, 'man', "ensure type is man");

__DATA__

=pod

=head1 target one

=over 4

=item hello target item

=back

X<target X>
Hello target B<X>

L<http://www.perl.org/>
L<Perly|http://www.perl.org/>
L<crontab(5)/"DESCRIPTION">

=cut
