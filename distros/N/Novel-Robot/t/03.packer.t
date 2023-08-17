#!/usr/bin/perl
use Test::More;
use Novel::Robot;

my $packer = Novel::Robot::Packer->new(type => 'html');


my $book_ref = {
    writer => 'xxx',
    book => 'yyy',
    item_list => [
        { id=>1, title=>'aaa', content=> '<p>kkk</p>' },
        { id=>2, title=>'bbb', content=> '<p>jjj</p>' },
    ], 
};

my $ret = $packer->main($book_ref, { with_toc => 1, output_scalar => 1 } );

is($$ret=~/<meta property="opf.authors" content="xxx">/s, 1, 'packer html');

done_testing;
