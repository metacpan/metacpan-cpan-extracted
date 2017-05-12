#!/usr/bin/perl -w

=head1 NAME

bench_template.pl - Test relative performance of Template::Alloy to Template::Toolkit

=cut

use strict;
use Benchmark qw(cmpthese timethese);
use POSIX qw(tmpnam);
use File::Path qw(rmtree);
use Template::Alloy;
use CGI::Ex::Dump qw(debug);
use Template;
use constant test_taint => 0 && eval { require Taint::Runtime }; # s/0/1/ to check tainting

Taint::Runtime::taint_start() if test_taint;

my $tt_cache_dir = tmpnam;
END { rmtree $tt_cache_dir };
mkdir $tt_cache_dir, 0755;

my $swap = {
    one   => "ONE",
    a_var => "a",
    foo   => '[% bar %]',
    bar   => "baz",
    hash  => {a => 1, b => 2, c => { d => [{hee => ["hmm"]}] }},
    array => [qw(A B C D E a A)],
    code  => sub {"(@_)"},
    filt  => sub {sub {$_[0]x2}},
};

use Template::Stash;;
my $s = Template::Stash->new($swap);
#use Template::Stash::XS;
#$s = Template::Stash::XS->new($swap);

###----------------------------------------------------------------###
### get objects ready

my @config1 = (STASH => $s, ABSOLUTE => 1, CONSTANTS => {simple => 'var'}, EVAL_PERL => 1, INCLUDE_PATH => $tt_cache_dir);
#push @config1, (INTERPOLATE => 1);
my @config2 = (@config1, COMPILE_EXT => '.ttc');

my $tt1 = Template->new(@config1);
my $tap = Template::Alloy->new(@config1, COMPILE_PERL => 1);

#use Template::Alloy::XS;
#my $tt1 = Template::Alloy::XS->new(@config1);
#my $tap = Template::Alloy::XS->new(@config1, COMPILE_PERL => 1);

#$swap->{$_} = $_ for (1 .. 1000); # swap size affects benchmark speed

###----------------------------------------------------------------###
### write out some file to be used later

my $fh;
my $bar_template = "$tt_cache_dir/bar.tt";
END { unlink $bar_template };
open($fh, ">$bar_template") || die "Couldn't open $bar_template: $!";
print $fh "BAR";
close $fh;

my $baz_template = "$tt_cache_dir/baz.tt";
END { unlink $baz_template };
open($fh, ">$baz_template") || die "Couldn't open $baz_template: $!";
print $fh "[% SET baz = 42 %][% baz %][% bing %]";
close $fh;

my $longer_template = "[% INCLUDE bar.tt %]"
    ."[% array.join('|') %]"
    .("123"x200)
    ."[% FOREACH a IN array %]foobar[% IF a == 'A' %][% INCLUDE baz.tt %][% END %]bazbing[% END %]"
    .("456"x200)
    ."[% IF foo ; bar ; ELSIF baz ; bing ; ELSE ; bong ; END %]"
    .("789"x200)
    ."[% IF foo ; bar ; ELSIF baz ; bing ; ELSE ; bong ; END %]"
    .("012"x200)
    ."[% IF foo ; bar ; ELSIF baz ; bing ; ELSE ; bong ; END %]"
    ."[% array.join('|') %]"
    ."[% PROCESS bar.tt %]";

my $hello2000 = "<html><head><title>[% title %]</title></head><body>
[% array = [ \"Hello\", \"World\", \"2000\", \"Hello\", \"World\", \"2000\" ] %]
[% sorted = array.sort %]
[% multi = [ sorted, sorted, sorted, sorted, sorted ] %]
<table>
[% FOREACH row = multi %]
  <tr bgcolor=\"[% loop.count % 2 ? 'gray' : 'white' %]\">
  [% FOREACH col = row %]
    <td align=\"center\"><font size=\"+1\">[% col %]</font></td>
  [% END %]
  </tr>
[% END %]
</table>
[% param = integer %]
[% FOREACH i = [ 1 .. 10 ] %]
  [% var = i + param %]"
  .("\n  [%var%] Hello World Hello World Hello World Hello World Hello World Hello World Hello World Hello World Hello World Hello World <br/>"x20)."
[% END %]
</body></html>
";

###----------------------------------------------------------------###
### set a few globals that will be available in our subs
my $show_list = grep {$_ eq '--list'} @ARGV;
my $run_all   = grep {$_ eq '--all'}  @ARGV;
my @run = $run_all ? () : @ARGV;
my $str_ref;
my $filename;

### uncomment to run a specific test - otherwise all tests run
#@run = qw(07);

#                                                                            ### All percents are Template::Alloy vs TT2
#                                                                            ### (The percent that Alloy is faster than TT)
#                                                                               Existing object by string ref #
#                                                                      New object with CACHE_EXT set #        #
#                                                   New object each time (undef CACHE_SIZE) #        #        #
#                              This percent is compiled in memory (repeated calls) #        #        #        #
my $tests = {                                                             #        #        #        #        #
    '01_empty'     => "",                                                 #  157%  #  357%  #  318%  #  386%  # 17173.6/s #
    '02_var_sma'   => "[% one %]",                                        #  131%  #  361%  #  359%  #  709%  # 14022.8/s #
    '03_var_lar'   => "[% one %]"x100,                                    #   33%  #  238%  #   61%  #  1694%  # 1046.3/s #
    '04_set_sma'   => "[% SET one = 2 %]",                                #  142%  #  311%  #  331%  #  889%  # 14614.1/s #
    '05_set_lar'   => "[% SET one = 2 %]"x100,                            #   66%  #  172%  #   22%  #  3621%  # 1436.4/s #
    '06_set_range' => "[% SET one = [0..30] %]",                          #   72%  #  223%  #  246%  #  648%  # 9774.1/s #
    '07_chain_sm'  => "[% hash.a %]",                                     #  138%  #  376%  #  336%  #  786%  # 13001.4/s #
    '08_mixed_sma' => "".((" "x100)."[% one %]\n")x10,                    #   81%  #  333%  #  216%  #  1617%  # 6483.7/s #
    '09_mixed_med' => "".((" "x10)."[% one %]\n")x100,                    #   35%  #  306%  #   97%  #  2156%  # 1017.8/s #
    '10_str_sma'   => "".("[% \"".(" "x100)."\$one\" %]\n")x10,           #  -19%  #  1345%  #   95%  #  4956%  # 2873.3/s #
    '11_str_lar'   => "".("[% \"".(" "x10)."\$one\" %]\n")x100,           #  -50%  #  325%  #    2%  #  1218%  # 370.4/s #
    '12_num_lterl' => "[% 2 %]",                                          #  150%  #  346%  #  362%  #  755%  # 16365.4/s #
    '13_plus'      => "[% 1 + 2 %]",                                      #  100%  #  304%  #  318%  #  691%  # 13031.8/s #
    '14_chained'   => "[% c.d.0.hee.0 %]",                                #  117%  #  399%  #  314%  #  891%  # 12271.8/s #
    '15_chain_set' => "[% SET c.d.0.hee.0 = 2 %]",                        #  120%  #  327%  #  292%  #  924%  # 10048.1/s #
    '16_chain_lar' => "[% c.d.0.hee.0 %]"x100,                            #   -2%  #  379%  #   54%  #  1880%  # 520.7/s #
    '17_chain_sl'  => "[% SET c.d.0.hee.0 = 2 %]"x100,                    #   99%  #  257%  #   72%  #  1663%  # 354.2/s #
    '18_cplx_comp' => "[% t = 1 || 0 ? 0 : 1 || 2 ? 2 : 3 %][% t %]",     #   66%  #  199%  #  233%  #  1090%  # 9359.2/s #
    '19_if_sim_t'  => "[% a=1 %][% IF a %]Two[% END %]",                  #  126%  #  306%  #  299%  #  1145%  # 12739.3/s #
    '20_if_sim_f'  => "         [% IF a %]Two[% END %]",                  #  137%  #  377%  #  314%  #  935%  # 13652.8/s #
    '21_if_else'   => "[% IF a %]A[% ELSE %]B[% END %]",                  #  134%  #  383%  #  314%  #  1061%  # 13651.9/s #
    '22_if_elsif'  => "[% IF a %]A[% ELSIF b %]B[% ELSE %]C[% END %]",    #  109%  #  346%  #  276%  #  1179%  # 11572.2/s #
    '23_for_i_sml' => "[% FOREACH i = [0..10]   ; i ; END %]",            #   43%  #  156%  #  138%  #  348%  # 3258.5/s #
    '24_for_i_med' => "[% FOREACH i = [0..100]  ; i ; END %]",            #    7%  #   27%  #   12%  #   56%  # 506.4/s #
    '25_for_sml'   => "[% FOREACH [0..10]       ; i ; END %]",            #   41%  #  161%  #  142%  #  341%  # 3163.9/s #
    '26_for_med'   => "[% FOREACH [0..100]      ; i ; END %]",            #   19%  #   35%  #   18%  #   71%  # 509.1/s #
    '27_while'     => "[% f = 10 %][%WHILE f%][%f=f- 1%][%f%][% END %]",  #   14%  #  143%  #   73%  #  262%  # 1848.0/s #
    '28_whl_set_l' => "[% f = 10; WHILE (g=f) ; f = f - 1 ; f ; END %]",  #    4%  #  105%  #   58%  #  190%  # 1420.1/s #
    '29_whl_set_s' => "[% f = 1;  WHILE (g=f) ; f = f - 1 ; f ; END %]",  #   55%  #  201%  #  190%  #  891%  # 6351.0/s #
    '30_file_proc' => "[% PROCESS bar.tt %]",                             #  171%  #  345%  #  331%  #  638%  # 9388.6/s #
    '31_file_incl' => "[% INCLUDE baz.tt %]",                             #  122%  #  274%  #  238%  #  432%  # 6426.3/s #
    '32_process'   => "[% BLOCK foo %]Hi[% END %][% PROCESS foo %]",      #  118%  #  339%  #  295%  #  928%  # 9431.1/s #
    '33_include'   => "[% BLOCK foo %]Hi[% END %][% INCLUDE foo %]",      #  106%  #  322%  #  286%  #  802%  # 8298.5/s #
    '34_macro'     => "[% MACRO foo BLOCK %]Hi[% END %][% foo %]",        #   91%  #  194%  #  241%  #  793%  # 8881.4/s #
    '35_macro_arg' => "[% MACRO foo(n) BLOCK %]Hi[%n%][%END%][%foo(2)%]", #   70%  #  189%  #  223%  #  899%  # 7111.7/s #
    '36_macro_pro' => "[% MACRO foo PROCESS bar;BLOCK bar%]7[%END;foo%]", #   79%  #  211%  #  255%  #  793%  # 6189.0/s #
    '37_filter2'   => "[% n = 1 %][% n | repeat(2) %]",                   #  126%  #  317%  #  297%  #  1173%  # 11058.5/s #
    '38_filter'    => "[% n = 1 %][% n FILTER repeat(2) %]",              #   99%  #  252%  #  257%  #  995%  # 9657.4/s #
    '39_fltr_name' => "[% n=1; n FILTER echo=repeat(2); n FILTER echo%]", #   47%  #  239%  #  194%  #  912%  # 6633.8/s #
    '40_constant'  => "[% constants.simple %]",                           #  167%  #  359%  #  360%  #  1060%  # 16677.6/s #
    '41_perl'      => "[%one='ONE'%][% PERL %]print \"[%one%]\"[%END%]",  #   63%  #  297%  #  239%  #  827%  # 7242.2/s #
    '42_filtervar' => "[% 'hi' | \$filt %]",                              #   55%  #  352%  #  272%  #  607%  # 8618.4/s #
    '43_filteruri' => "[% ' ' | uri %]",                                  #   76%  #  360%  #  277%  #  689%  # 10118.0/s #
    '44_filterevl' => "[% foo | eval %]",                                 #  367%  #  319%  #  334%  #  752%  # 6482.5/s #
    '45_capture'   => "[% foo = BLOCK %]Hi[% END %][% foo %]",            #  120%  #  270%  #  260%  #  1002%  # 12199.6/s #
    '46_refs'      => "[% b = \\code(1); b(2) %]",                        #   33%  #  201%  #  175%  #  545%  # 6132.4/s #
    '47_complex'   => "$longer_template",                                 #   62%  #  194%  #  136%  #  790%  # 1302.9/s #
    '48_hello2000' => "$hello2000",                                       #   29%  #  145%  #   40%  #  303%  # 251.9/s #
    # overall                                                             #   86%  #  291%  #  214%  #  999%  #
    # With Stash::XS
    #'47_complex'   => "$longer_template",                                #   15%  #  184%  #  100%  #   12%  # 1952.5/s #
    #'48_hello2000' => "$hello2000",                                      #   28%  #  104%  #  -12%  #   29%  # 574.0/s #
    ## overall                                                            #   15%  #  277%  #  186%  #   15%  #
};

### load the code representation
my $text = {};
seek DATA, 0, 0;
my $data = do { local $/ = undef; <DATA> };
foreach my $key (keys %$tests) {
    $data =~ m/(.*\Q$key\E.*)/ || next;
    $text->{$key} = $1;
}

if ($show_list) {
    foreach my $text (sort values %$text) {
        print "$text\n";
    }
    exit;
}

my $run = join("|", @run);
@run = grep {/$run/} sort keys %$tests;

###----------------------------------------------------------------###

sub file_TT_new {
    my $out = '';
    my $t = Template->new(@config1);
    $t->process($filename, $swap, \$out);
    return $out;
}

sub str_TT_new {
    my $out = '';
    my $t = Template->new(@config1);
    $t->process($str_ref, $swap, \$out);
    return $out;
}

sub file_TT {
    my $out = '';
    $tt1->process($filename, $swap, \$out);
    return $out;
}

sub str_TT {
    my $out = '';
    $tt1->process($str_ref, $swap, \$out) || debug $tt1->error;
    return $out;
}

sub file_TT_cache_new {
    my $out = '';
    my $t = Template->new(@config2);
    $t->process($filename, $swap, \$out);
    return $out;
}

###----------------------------------------------------------------###

sub file_Alloy_new {
    my $out = '';
    my $t = Template::Alloy->new(@config1);
    $t->process($filename, $swap, \$out);
    return $out;
}

sub str_Alloy_new {
    my $out = '';
    my $t = Template::Alloy->new(@config1);
    $t->process($str_ref, $swap, \$out);
    return $out;
}

sub file_Alloy {
    my $out = '';
    $tap->process($filename, $swap, \$out);
    return $out;
}

sub str_Alloy {
    my $out = '';
    $tap->process($str_ref, $swap, \$out);
    return $out;
}

sub file_Alloy_cache_new {
    my $out = '';
    my $t = Template::Alloy->new(@config2);
    $t->process($filename, $swap, \$out);
    return $out;
}

###----------------------------------------------------------------###

@run = sort(keys %$tests) if $#run == -1;

my $output = '';
my %cumulative;
foreach my $test_name (@run) {
    die "Invalid test $test_name" if ! exists $tests->{$test_name};
    my $txt = $tests->{$test_name};
    my $sample = $text->{$test_name};
    $sample =~ s/^.+=>//;
    $sample =~ s/\#.+$//;
    print "-------------------------------------------------------------\n";
    print "Running test $test_name\n";
    print "Test text: $sample\n";

    ### set the global file types
    $str_ref = \$txt;
    $filename = $tt_cache_dir ."/$test_name.tt";
    open(my $fh, ">$filename") || die "Couldn't open $filename: $!";
    print $fh $txt;
    close $fh;

    #debug file_Alloy(), str_TT();
    #debug $tap->parse_tree($file);

    ### check output - and also allow for caching
    for (1..2) {
        if (file_Alloy() ne str_TT()) {
            debug $tap->parse_tree($str_ref);
            debug file_Alloy(), str_TT();
            die "file_Alloy didn't match";
        }
        die "file_TT didn't match "              if file_TT()        ne str_TT();
        die "str_Alloy didn't match "            if str_Alloy()      ne str_TT();
        die "file_Alloy_cache_new didn't match " if file_Alloy_cache_new() ne str_TT();
        die "file_TT_cache_new didn't match "    if file_TT_cache_new()    ne str_TT();
    }

    next if test_taint;

###----------------------------------------------------------------###

    my $r = eval { timethese (-2, {
        file_TT_n   => \&file_TT_new,
#        str_TT_n    => \&str_TT_new,
        file_TT     => \&file_TT,
        str_TT      => \&str_TT,
        file_TT_c_n => \&file_TT_cache_new,

        file_Alloy_n   => \&file_Alloy_new,
#        str_Alloy_n    => \&str_Alloy_new,
        file_Alloy     => \&file_Alloy,
        str_Alloy      => \&str_Alloy,
        file_Alloy_c_n => \&file_Alloy_cache_new,
    }) };
    if (! $r) {
        debug "$@";
        next;
    }
    eval { cmpthese $r };

    my $copy = $text->{$test_name};
    $copy =~ s/\#.+//;
    $output .= $copy;

    eval {
        my $hash = {
            '1 cached_in_memory           ' => ['file_Alloy',     'file_TT'],
            '2 new_object                 ' => ['file_Alloy_n',   'file_TT_n'],
            '3 cached_on_file (new_object)' => ['file_Alloy_c_n', 'file_TT_c_n'],
            '4 string reference           ' => ['str_Alloy',      'str_TT'],
            '5 Alloy new vs TT in mem     ' => ['file_Alloy_n',   'file_TT'],
            '6 Alloy in mem vs TT new     ' => ['file_Alloy',     'file_TT_n'],
            '7 Alloy in mem vs Alloy new  ' => ['file_Alloy',     'file_Alloy_n'],
            '8 TT in mem vs TT new        ' => ['file_TT',        'file_TT_n'],
        };
        foreach my $type (sort keys %$hash) {
            my ($key1, $key2) = @{ $hash->{$type} };
            my $ct = $r->{$key1};
            my $tt = $r->{$key2};
            my $ct_s = $ct->iters / ($ct->cpu_a || 1);
            my $tt_s = $tt->iters / ($tt->cpu_a || 1);
            my $p = int(100 * ($ct_s - $tt_s) / ($tt_s || 1));
            print "$type - Alloy is $p% faster than TT\n";

            $output .= sprintf('#  %3s%%  ', $p) if $type =~ /^[1234]/;

            ### store cumulatives
            if (abs($p) < 10000) {
                $cumulative{$type} ||= [0, 0];
                $cumulative{$type}->[0] += $p;
                $cumulative{$type}->[1] ++;
            }
        }
    };
    debug "$@"
        if $@;

    $output .= "# ".sprintf("%.1f", $r->{'file_Alloy'}->iters / ($r->{'file_Alloy'}->cpu_a || 1))."/s #\n";
#    $output .= "#\n";

    foreach my $row (values %cumulative) {
        $row->[2] = sprintf('%.1f', $row->[0] / ($row->[1]||1));
    }

    if ($#run > 0) {
        foreach (sort keys %cumulative) {
            printf "Cumulative $_: %6.1f\n", $cumulative{$_}->[2];
        }
    }

}

### add the final total row
if ($#run > 0) {
    $output .= "    # overall" . (" "x61);
    foreach my $type (sort keys %cumulative) {
        $output .= sprintf('#  %3s%%  ', int $cumulative{$type}->[2]) if $type =~ /^[1234]/;
    }
    $output .= "#\n";

}
print $output;



#print `ls -lR $tt_cache_dir`;
__DATA__
