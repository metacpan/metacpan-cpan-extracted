# -*- mode: cperl; -*-
use Test::Base;
use Net::SSL::ExpireDate;
use FindBin;

plan tests => 2 * blocks;

run {
    my $block = shift;
    my $ed = Net::SSL::ExpireDate->new( $block->type => $block->target );

    is $ed->type,   $block->type,   $block->name.': type';
    is $ed->target, $block->target, $block->name.': target';
}

__END__
=== rt.cpan.org
--- type: ssl
--- target: rt.cpan.org
=== cert.pem
--- type: file
--- target eval
"$FindBin::Bin/cert.pem";
