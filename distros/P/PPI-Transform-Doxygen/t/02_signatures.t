use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use Fcntl qw(:seek);


BEGIN {
    unshift @INC, "$Bin/../lib";
    for my $mod ('PPI', 'PPI::Transform::Doxygen') {
        use_ok($mod, "load $mod") or BAIL_OUT("cannot load $mod");
    }
};

my $tr = new_ok('PPI::Transform::Doxygen');

open(my $out, '>', \my $buf);

$tr->file("$Bin/TestSigs.txt" => $out);

my $fhead = quotemeta('/** @file TestSigs.txt');
my($fcontent) = $buf =~ m!$fhead\n(.+?)\*/!s;

unlike($fcontent, qr/\w/, 'file section');

my $hhead = quotemeta('** @class My::TestSigs');
my($hcontent) = $buf =~ m!$hhead\n(.+?)\*/!s;

isnt($hcontent, undef, 'class header section');

like($hcontent, qr!\@section TestSigs_NAME NAME\n<p>TestSigs - PPI::Transform::Doxygen Test Input</p>!, 'NAME');

like($hcontent, qr!\@section TestSigs_DESCRIPTION DESCRIPTION\n<p>Test input for subroutine signatures and inline comments</p>!, 'DESCRIPTION');

my $chead = quotemeta('class TestSigs: public {');
my($ccontent) = $buf =~ m!$chead\n(.+)\};!s;

isnt($ccontent, undef, 'class section');

my %content;
@content{qw(public private)} = $ccontent =~ m!public:(.+)private:(.+)$!s;

isnt($content{public},  undef, 'public section');
isnt($content{private}, undef, 'private section');

my %test = (
    public => [
        {
            head => '** @fn void method1()',
            text => 'Undocumented Function',
        },
        {
            head => '** @fn void method2()',
            text => 'Undocumented Function',
        },
        {
            head => '** @fn $self method3(scalar self, scalar bla3)',
            text => 'around method3',
        },
        {
            head => '** @fn void attr1()',
            text => 'Undocumented Function',
        },
        {
            head => '** @fn void attr2()',
            text => 'Undocumented Function',
        },
        {
            head => '** @fn void attr3()',
            text => 'Undocumented Function',
        },
        {
            head => '** @fn void attr4()',
            text => 'Undocumented Function',
        },
        {
            head => '** @fn void attr5()',
            text => 'Undocumented Function',
        },
        {
            head => '** @fn void attr6()',
            text => 'Undocumented Function',
        },
        {
            head => '** @fn void attr7()',
            text => 'Undocumented Function',
        },
        {
            head => '** @fn static $self new(scalar class, hash args)',
            text => 'static new',
            wipe => 1,
        },
        {
            head => '** @fn static $ok test1(scalar first, scalar second, array rest)',
            text => 'static test1',
            wipe => 1,
            default => [
                q(Default value for $second is 'default'.),
            ],
        },
        {
            head => '** @fn $self test2(scalar self, scalar first, scalar second, hash args)',
            text => 'method test2',
            wipe => 1,
            default => [
                q(Default value for $first is 'default'.),
                q(Default value for $second is [].),
            ],
        },
        {
            head => '** @fn $self test3(scalar self, scalar xxx)',
            text => 'method test3 head2',
            wipe => 0,
        },
    ],
    private => [
    ],
);

for my $type ( qw(public private) ) {
    #warn $content{$type};
    for my $test ( @{ $test{$type} } ) {
        my $head = quotemeta($test->{head});
        (my $inner) = $content{$type} =~ m!/$head(.+?)\*/!s;
        isnt($inner, undef, $test->{text} . ' exists');
        my $text = quotemeta($test->{text});
        like($inner, qr!<p>$text</p>!s, $test->{text} . ' description');
        my $def = $test->{default} // [];
        unlike($inner, qr/\r?\n=for/, $test->{text} . ' wiped =for')
            if $test->{wipe};
        like($inner, qr/\r?\n=for/, $test->{text} . ' not wiped =for')
            if defined $test->{wipe} && !$test->{wipe};
        for my $d ( @$def ) {
            my $dtxt = quotemeta($d);
            like($inner, qr!<p>$dtxt</p>!s, 'default description');
        }
    }
}

done_testing();
