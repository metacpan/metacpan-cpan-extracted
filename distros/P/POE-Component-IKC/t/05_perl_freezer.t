#!/usr/bin/perl -w
use strict;

use Test::More tests => 8;

use POE::Component::IKC::Freezer qw(freeze thaw dclone);

pass( "Loaded" );

######################### End of black magic.

my $data={foo=>"bar", biff=>[qw(hello world)]};


my $str=freeze($data);
ok( $str, "freeze" );

my $data2=thaw($str);
ok( $data2, "thaw" );
is_deeply( $data, $data2, "Round trip" );


$data2=dclone($data);
is_deeply($data, $data2, "dclone");


$data->{biffle}=$data->{biff};
$data2=dclone($data);
is( $data->{biffle}, $data->{biff}, "Both" );
is_deeply($data, $data2, "dclone");


# circular reference
$data->{flap}=$data->{biffle};
push @{$data->{biffle}}, $data->{flap};
$data2=dclone($data);

is( $data->{biffle}[-1], $data->{biffle}, "Deeply" );
