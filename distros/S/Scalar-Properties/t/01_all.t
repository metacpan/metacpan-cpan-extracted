# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
BEGIN { $| = 1; print "1..151\n"; }
END { print "not ok 1\n" unless $loaded; }
use Scalar::Properties;
$loaded = 1;
print "ok 1\n";
######################### End of black magic.
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
our $testcount = 1;    # compensate for 'ok' above

sub true {
    my $ok = shift;
    our $testcount;
    $testcount++;
    print 'not ' unless $ok;
    print "ok $testcount " . ($_[0] ? $_[0] : '') . "\n";
}
sub false { true(!$_[0]) }
my $pkg = 'Scalar::Properties';
{    # test added by DCANTRELL to tickle the binary-op operand re-ordering bug
    true(time - 300 > 0, "binary-op operand re-ordering bug");
}
{    # test added by DCANTRELL to test for rt.cpan.org bug 4312
    my $test = 0;
    true(
        $test 
          . "\$test"
          . "\\$test"
          . "\\\$test"
          . "\\\\$test" eq '0$test\0\$test\\\\0',
        "variable interpolation bug"
    );
}

# die;
false(0);
true(1);
false(0->is_true);
true(0->is_false);
false(1->is_false);
true(1->is_true);
{
    my $foo = 0->true;
    true($foo->value == 0->{_value});
    true($foo);
    $foo += 7;
    true(ref $foo eq $pkg);
    true($foo);
    true($foo == 7);
    true($foo->{_value} == 7);
}
{
    my $bar = 42->times(3);
    true($bar == 126);
    true($bar);
    $bar->false;
    false($bar);
    true($bar == 126);
    true($bar->times(4) == 504);

    # set a property; note that the '1' itself becomes overloaded.
    $bar->approximate(1);
    true($bar->approximate);
    true($bar->is_approximate);
    true($bar->has_approximate);
    $bar->approximate(0);
    false($bar->approximate);
    false($bar->is_approximate);
    false($bar->has_approximate);
}
{
    my $val = 0->true;
    true($val && $val == 0);
}
{
    my $quux = 37->prime(1);
    true($quux);
    true($quux == 37);
    true($quux->is_prime);
}
{
    my $baza = 42->value;
    my $bazb = 42;
    true(ref $baza eq '');
    true($baza == $bazb);
}
{
    my $h = 'hello world';
    true($h);
    true($h eq 'hello world');
    $h->greeting(1);
    true($h->is_greeting);
    my @blah;
    push @blah => $h;
    push @blah => 'forget it';
    push @blah => 'hi there'->greeting(1);
    my @greets = grep { $_->is_greeting } @blah;
    true(@greets == 2);
    true($greets[0] eq 'hello world');
    true($greets[1] eq 'hi there');
}
{
    false('');
    true(''->true);
    false(''->false);
    true('x');
    true('x'->true);
    false('x'->false);
}
{
    my $len = 'hello world'->length;
    true(ref $len eq $pkg);
    true($len == 11);
    my $rev = 'hello world'->reverse;
    true(ref $rev eq $pkg);
    true($rev eq 'dlrow olleh');
    true(1234->length == 4);
    true(1234->size == 1234->length);
    true(1234->reverse == 4321);
}
{
    my $t = 'hello cruel world';
    my @s;
    @s = $t->split;
    true(@s == 3);
    true($s[0] eq 'hello');
    true($s[1] eq 'cruel');
    true($s[2] eq 'world');
    @s = $t->split(qr/ll/);
    true(@s == 2);
    true($s[0] eq 'he');
    true($s[1] eq 'o cruel world');
    @s = $t->split(qr/\s+/, 2);
    true(@s == 2);
    true($s[0] eq 'hello');
    true($s[1] eq 'cruel world');

    # There was a bug with split(), so we try it again to be
    # sure it works
    @s = $t->split(qr/ll/);
    true(@s == 2);
    true($s[0] eq 'he');
    true($s[1] eq 'o cruel world');
}
{
    true('hello world'->uc      eq 'HELLO WORLD');
    true('hello world'->ucfirst eq 'Hello world');
    true('HELLO WORLD'->lc      eq 'hello world');
    true('HELLO WORLD'->lcfirst eq 'hELLO WORLD');
    my $s = 'hello world';
    true(ref $s->uc      eq $pkg);
    true(ref $s->ucfirst eq $pkg);
    true(ref $s->lc      eq $pkg);
    true(ref $s->lcfirst eq $pkg);
}
{
    true('0xAf'->hex == 175);
    true('aF'->hex == 175);
    true(123->hex == 291);
    true(777->oct == 511);
    true(123->oct == 83);
    my $h = '0xffffff';
    true(ref $h->hex eq $pkg);
    true(ref $h->oct eq $pkg);
}
{
    true('hello'->concat(' world')     eq 'hello world');
    true(ref 'hello'->concat(' world') eq $pkg);
    true(ref 'hello'->append(' world') eq $pkg);
}
{
    my $s = 'Hello World';
    true($s->swapcase, 'hELLO wORLD');
}
{
    my $s1 = 'aaa';
    my $s2 = 'bbb';
    true($s1 eq $s1);
    true($s1->eq($s1));
    true($s1 ne $s2);
    true($s1->ne($s2));
    true($s1 lt $s2);
    true($s1->lt($s2));
    true($s2 gt $s1);
    true($s2->gt($s1));
    true($s1 le $s1);
    true($s1 le $s2);
    true($s1->le($s1));
    true($s1->le($s2));
    true($s2 ge $s1);
    true($s2 ge $s2);
    true($s2->ge($s1));
    true($s2->ge($s2));
    true(ref $s1->eq($s1) eq $pkg);
    true(ref $s1->ne($s1) eq $pkg);
    true(ref $s1->lt($s1) eq $pkg);
    true(ref $s1->gt($s1) eq $pkg);
    true(ref $s1->le($s1) eq $pkg);
    true(ref $s1->ge($s1) eq $pkg);
}
{
    my $s1 = 'aaa';
    my $s2 = 'BBB';
    true($s1->eqi($s1));
    true($s1->nei($s2));
    true($s1->lti($s2));
    true($s2->gti($s1));
    true($s1->lei($s1));
    true($s1->lei($s2));
    true($s2->gei($s1));
    true($s2->gei($s2));
    true(ref $s1->eqi($s1) eq $pkg);
    true(ref $s1->nei($s1) eq $pkg);
    true(ref $s1->lti($s1) eq $pkg);
    true(ref $s1->gti($s1) eq $pkg);
    true(ref $s1->lei($s1) eq $pkg);
    true(ref $s1->gei($s1) eq $pkg);
}
{
    my $out;
    3->times_do(sub { $out .= 'Hello' });
    true($out eq 'HelloHelloHello');
    $out = '';
    5->times_do(sub { $out .= shift });
    true($out == 12345);
    my $sub = sub { $out .= "$_[0].. " };
    $out = '';
    1->do_upto(5 => $sub);
    true($out eq '1.. 2.. 3.. 4.. 5.. ');
    $out = '';
    1->do_upto_step(5, 2, $sub);
    true($out eq '1.. 3.. 5.. ');
    $out = '';
    5->do_upto(1 => $sub);
    true($out eq '');
    $out = '';
    5->do_downto(3 => $sub);
    true($out eq '5.. 4.. 3.. ');
    $out = '';
    5->do_downto_step(2, 2, $sub);
    true($out eq '5.. 3.. ');
    $out = '';
    3->do_downto(5 => $sub);
    true($out eq '');
}
{
    true((-1942)->abs() == 1942);
    true(0->abs == 0);
    true(773->abs == 773);
    true(0->zero);
    false(1->zero);
    my $foo = 27;
    false($foo->zero);
    $foo -= 27;
    true($foo->zero);
}
{
    pass_on('approximate');
    true(get_pass_on == 1);
    true(passed_on('approximate'));
}
{
    my $foo = 1;
    $foo->history(1);
    my $pi  = 3->approximate(1);
    my $bar = $foo + $pi;
    true($bar->is_approximate);
    false($bar->has_history);
}
{
    my $h1 = 'hi world'->approximate(1);
    my $h2 = $h1->uc;
    my @h3 = $h1->split;
    true($_->approximate) for $h1, $h2, @h3;
}
{
    my $ship = 1701->class('galaxy');
    $ship->quadrant('alpha');
    $ship->crew(1017);
    my @props = $ship->get_props;
    true(@props == 3);
    true(grep /^$_$/ => @props) for qw/class quadrant crew/;
    $ship->crew(0);
    true($ship->get_props == 3);
    $ship->del_prop('crew');
    @props = $ship->get_props;
    true(@props == 2);
    true(grep /^$_$/ => @props) for qw/class quadrant/;
    $ship->del_all_props;
    @props = $ship->get_props;
    true(@props == 0);
}
