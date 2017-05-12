# -*- Mode: Perl; -*-

=head1 NAME

11_tt_input_output.t - Test the plethora of ways TT takes files in and out

=cut

use vars qw($module $is_tt);
BEGIN {
    $module = 'Template::Alloy';
    if (grep {/tt/i} @ARGV) {
        $module = 'Template';
    }
    $is_tt = $module eq 'Template';
};

use strict;
use Test::More tests => (! $is_tt) ? 21 : 18;

use_ok($module);

### find a place to allow for testing
(my $test_dir = $0) =~ s/\.t$/.dir/;
my $test_file_short = "inout.txt";
my $test_file = "$test_dir/$test_file_short";
sub delete_file { unlink $test_file }
END { delete_file(); rmdir $test_dir }
if (! -d $test_dir) { mkdir($test_dir, 0755) || die "Couldn't mkdir $test_dir: $!" }
ok(-d $test_dir, "Got a test dir up and running");

sub get_file {
    my $txt = '';
    if (open my $fh, "<", $test_file) {
        read $fh, $txt, -s $test_file;
    }
    return $txt;
}

sub set_file {
    open(my $fh, ">", $test_file) || die "Couldn't open file $test_file: $!";
    print $fh @_;
}

###----------------------------------------------------------------###

my $obj = $module->new(INCLUDE_PATH => $test_dir);
my $out;

print "### INPUT ###########################################\n";

$out = '';
$obj->process(\ "hi [% 1 + 2 %]", {}, \$out);
is($out, "hi 3", 'process(\$in, {}, \$out)') || diag $obj->error;

$out = '';
set_file("hi [% 1 + 2 %]");
$obj->process($test_file_short , {}, \$out);
is($out, "hi 3", 'process($filename, {}, \$out)') || diag $obj->error;

if (! $is_tt) { # tt is supposed to handle this - it doesn't
    $out = '';
    $obj->process(sub { "hi [% 1 + 2 %]" } , {}, \$out);
    is($out, "hi 3", 'process(\&code, {}, \$out)') || diag $obj->error;
}

if (! $is_tt) {
    $out = '';
    my $doc = $obj->load_template(\ "hi [% 1 + 2 %]");
    $obj->process($doc, {}, \$out);
    is($out, "hi 3", 'process($obj->load_template($filename), {}, \$out)') || diag $obj->error;
}

$out = '';
set_file("hi [% 1 + 2 %]");
open(IO_TEST_IN, "<", $test_file) || die "Couldn't open $test_file for reading: $!";
$obj->process(\*IO_TEST_IN, {}, \$out);
is($out, "hi 3", 'process(\*FH, {}, \$out)') || diag $obj->error;

$out = '';
set_file("hi [% 1 + 2 %]");
open(my $fh, "<", $test_file) || die "Couldn't open $test_file for reading: $!";
$obj->process($fh , {}, \$out);
is($out, "hi 3", 'process($fh, {}, \$out)') || diag $obj->error;

###----------------------------------------------------------------###
print "### OUTPUT ##########################################\n";

{
    $out = '';
    local $obj->{'OUTPUT'} = \$out;
    $obj->process(\ "hi [% 1 + 2 %]");
    is($out, "hi 3", 'new(OUTPUT=>\$out)->process(\$str)');
}

$out = '';
$obj->process(\ "hi [% 1 + 2 %]", {}, sub { $out = shift });
is($out, "hi 3", 'process(\$str, {}, \&code)');

{
    package IO_TEST_PRINT;
    our $out = '';
    sub print { my $self = shift; $out = shift }
}
$obj->process(\ "hi [% 1 + 2 %]", {}, bless {}, 'IO_TEST_PRINT');
is($IO_TEST_PRINT::out, "hi 3", 'process(\$str, {}, $obj) - where $obj->can("print")');

$out = '';
$obj->process(\ "hi [% 1 + 2 %]", {}, \$out);
is($out, "hi 3", 'process(\$str, {}, \$out)');

my @out = ("foo");
$obj->process(\ "hi [% 1 + 2 %]", {}, \@out);
is($out[-1], "hi 3", 'process(\$str, {}, \@out)');


set_file("");
open(IO_TEST_OUT, ">", $test_file) || die "Couldn't open $test_file for writing: $!";
$obj->process(\ "hi [% 1 + 2 %]", {}, \*IO_TEST_OUT);
close(IO_TEST_OUT);
is(get_file(), "hi 3", 'process(\$str, {}, \*FH)') || diag $obj->error;

set_file("");
open($fh, ">", $test_file) || die "Couldn't open $test_file for writing: $!";
$obj->process(\ "hi [% 1 + 2 %]", {}, $fh);
close($fh);
is(get_file(), "hi 3", 'process(\$str, {}, $fh)') || diag $obj->error;

if (! $is_tt && $test_file =~ m{ ^/ }x) {
    set_file("");
    eval { $obj->process(\ "hi [% 1 + 2 %]", {}, $test_file) };
    is(get_file(), "", 'process(\$str, {}, $filename) - with ABSOLUTE error') || diag $obj->error;
    ok($obj->error =~ /ABSOLUTE/, "Right ABSOLUTE error");

    local $obj->{'ABSOLUTE'} = 1;
    $obj->process(\ "hi [% 1 + 2 %]", {}, $test_file);
    is(get_file(), "hi 3", 'process(\$str, {}, $filename) - with ABSOLUTE file') || diag $obj->error;

} elsif (! $is_tt && $test_file =~ m{ ^\.\.?/ }x) {
    set_file("");
    eval { $obj->process(\ "hi [% 1 + 2 %]", {}, $test_file) };
    is(get_file(), "", 'process(\$str, {}, $filename) - with RELATIVE error') || diag $obj->error;
    ok($obj->error =~ /RELATIVE/, "Right RELATIVE error");

    local $obj->{'RELATIVE'} = 1;
    $obj->process(\ "hi [% 1 + 2 %]", {}, $test_file);
    is(get_file(), "hi 3", 'process(\$str, {}, $filename) - with RELATIVE file') || diag $obj->error;
} else {
    ok(1, "Skip ABSOLUTE/RELATIVE output tests") for 1 .. 3; # without calling skip()
}

{
    set_file("");
    local $obj->{'OUTPUT_PATH'} = $test_dir;
    $obj->process(\ "hi [% 1 + 2 %]", {}, $test_file_short);
    is(get_file(), "hi 3", 'process(\$str, {}, $filename) - with OUTPUT_PATH') || diag $obj->error;

    set_file("");
    local $obj->{'OUTPUT_PATH'} = $test_dir;
    $obj->process(\ "hi [% 1 + 2 %]", {}, $test_file_short, {binmode => 1});
    is(get_file(), "hi 3", 'process(\$str, {}, $filename) - with binmode') || diag $obj->error;
}


if (! $is_tt) {
    {
        package tt_input_output_handle;
        sub TIEHANDLE {
            my ($class, $out_ref) = @_;
            return bless [$out_ref], $class;
        }
        sub PRINT {
            my $self = shift;
            ${ $self->[0] } .= $_ for grep {defined && length} @_;
            return 1;
        }
    }
    $out = '';
    local *IO_OUT;
    tie *IO_OUT, 'tt_input_output_handle', \$out;
    my $old_fh = select IO_OUT;
    $obj->process(\ "hi [% 1 + 2 %]");
    is($out, "hi 3", 'process(\$str)');
    select $old_fh;
}




###----------------------------------------------------------------###
print "### DONE ############################################\n";
