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

$tr->file("$Bin/../Makefile.PL" => $out);

like($buf, qr/class\ Makefile_main:\ public/, 'no pod');

seek($out, 0, SEEK_SET);

#diag $buf;

$tr->file($0 => $out);

#diag($buf);

my $fhead = quotemeta('/** @file 01_basic.t');
my($fcontent) = $buf =~ m!$fhead\n(.+?)\*/!s;

like($fcontent, qr!\@section 01_basic_DESCRIPTION DESCRIPTION\n<p>txt1</p>!, 'head1');

my $chead = quotemeta('class 01_basic_main: public {');
my($ccontent) = $buf =~ m!$chead\n(.+?)\};!s;

isnt($ccontent, undef, 'class section');

my %content;
@content{qw(public private)} = $ccontent =~ m!public:(.+)private:(.+)$!s;

isnt($content{public},  undef, 'public section');
isnt($content{private}, undef, 'private section');

my %test = (
    public => [
        {
            head => '** @fn virtual void a_func()',
            text => 'virtual a_func',
        },
        {
            head => '** @fn static $obj new(hash args)',
            text => 'static new',
        },
        {
            head => '** @fn $self method1(array_ref aref)',
            text => 'method method1',
        },
        {
            head => '** @fn $self method2(hash_ref href)',
            text => 'method method2',
        },
        {
            head => '** @fn function func1(array args)',
            text => 'function func1',
        },
    ],
    private => [
        {
            head => '** @fn static $out _convert(scalar in)',
            text => 'private static _convert',
        },
        {
            head => '** @fn $out _private(scalar in)',
            text => 'private method _private',
        },
    ],
);

for my $type ( qw(public private) ) {
    for my $test ( @{ $test{$type} } ) {
        my $head = quotemeta($test->{head});
        (my $inner) = $content{$type} =~ m!/$head(.+?)\*/!s;
        isnt($inner, undef, $test->{text} . ' exists');
        like($inner, qr!<p>$test->{text}</p>!s, $test->{text} . ' description');
    }
}

done_testing();

=head2 class_method $obj new(%args)

static new

=cut
sub new {
    my($class, %args) = @_;
    return bless(\%args, $class);
}

=head2 $self method1(@$aref)

method method1

=cut
sub method1 {
    my($self, $aref) = @_;
    return $self;
}

=head2 method $self method2(%$href)

method method2

=cut
sub method2 {
    my($self, $href) = @_;
    return $self;
}

=head2 function func1(@args)

function func1

=cut
sub func1 {
    my(@args) = @_;
    return;
}

=head2 function $out _convert($in)

private static _convert

=cut
sub _convert { return uc($_[0]) }

=head2 $out _private($in)

private method _private

=cut
sub _private { return $_[0]->method1() }

__END__

=pod

=head1 DESCRIPTION

txt1

=cut

=head2 a_func()

virtual a_func

=cut

=head2 A real Header2

some text C<embedded_func>

    Verbatim text
    is here

=cut

