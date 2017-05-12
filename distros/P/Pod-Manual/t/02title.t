use strict;
use warnings;

use Test::More tests => 3;                      # last test to print

use Pod::Manual;

my $foobar_pod = <<'END_POD';
=head1 NAME

Foo::Bar - Bazzles the Frob

=head1 Description

yadah yadah yadah

END_POD

my $other_pod = <<'END_POD';
=head1 NAME

Something::Else - Not that important

=head1 Description

yadah yadah yadah

END_POD

my $manual = Pod::Manual->new;

$manual->add_chapter( $foobar_pod );
$manual->add_chapter( $other_pod );

like manual_title( $manual ),
    qr/Foo::Bar/,
    "no explicit title, first chapter's title is used";

$manual = Pod::Manual->new( title => "From the object's creation" );

$manual->add_chapter( $foobar_pod );

like manual_title( $manual ), qr/From the object's creation/,
    "explicit title";

$manual = Pod::Manual->new;

$manual->add_chapter( $foobar_pod );
$manual->add_chapter( $other_pod, { set_title => 1 } );

like manual_title( $manual ), qr/Something::Else/,
    "set_title in add_chapter";


### utility functions #############################

sub manual_title {
    my $manual = shift;
    return $manual->as_dom->find( '/book/bookinfo/title/text()' );
}

