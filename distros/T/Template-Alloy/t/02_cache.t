# -*- Mode: Perl; -*-

=head1 NAME

02_cache.t - Test caching features

=cut

use 5.006;
use vars qw($n_tests $has_encode);
BEGIN {
    if (eval { require Encode; require utf8 }) {
        $has_encode = 1;
    }

    $n_tests = 193;
    $n_tests += 12 if $has_encode;
};

use strict;
use Test::More tests => $n_tests;
use constant test_taint => 0 && eval { require Taint::Runtime };

if (! eval { require File::Path }) {
    SKIP: {
        skip("File::Path not installed, skipping tests", $n_tests);
    };
    exit;
}

my $module = 'Template::Alloy';
use_ok($module);

Taint::Runtime::taint_start() if test_taint;

my $name = "bar.tt";

### find a place to allow for testing
my $test_dir = $0 .'.test_dir';
END { if($test_dir){ flush_dir($test_dir); rmdir($test_dir)  || die "Couldn't rmdir $test_dir: $!"} }
mkdir $test_dir, 0755;
ok(-d $test_dir, "Got a test dir up and running");

### find a place to allow for testing
my $test_dir2 = $0 .'.test_dir2';
END { if($test_dir2){flush_dir($test_dir2); rmdir $test_dir2  || die "Couldn't rmdir $test_dir2: $!"} }
mkdir $test_dir2, 0755;
ok(-d $test_dir2, "Got a test dir up and running");

###----------------------------------------------------------------###

sub process_ok { # process the value and say if it was ok
    my $str  = shift;
    my $test = shift;
    my $vars = shift || {};
    my $conf = local $vars->{'tt_config'} = $vars->{'tt_config'} || [];
    push @$conf, (INCLUDE_PATH => $test_dir);
    my $obj  = shift || $module->new(@$conf); # new object each time
    my $out  = '';
    my $line = (caller)[2];
    delete $vars->{'tt_config'};

    Taint::Runtime::taint(\$str) if test_taint;

    $obj->process_simple($str, $vars, \$out);
    my $ok = ref($test) ? $out =~ $test : $out eq $test;
    if ($ok) {
        ok(1, "Line $line   \"".(ref($str) ? $$str : $str)."\" => \"$out\"");
        return $obj;
    } else {
        ok(0, "Line $line   \"".(ref($str) ? $$str : $str));
        warn "# Was:\n$out\n# Should've been:\n$test\n";
        print $obj->error if $obj->can('error');
        print $obj->dump_parse_tree(\$str) if $obj->can('dump_parse_tree');
#        exit;
    }
}

sub pristine {
    my $contents = shift || "[% blue %]BAR";
    my $encoding = shift;

    if ($encoding) {
        $contents = Encode::encode( $encoding, $contents );
    }

    $Template::Alloy::GLOBAL_CACHE = {};
    flush_dir($test_dir);
    flush_dir($test_dir2);

    if (! ref $name) {
        my $fh;
        open($fh, ">$test_dir/$name") || die "Couldn't open $name in $test_dir: $!";
        print $fh $contents;
        close $fh;
    }
}

sub flush_dir {
    my $dir = shift;
    opendir(my $dh, $dir) || die "Couldn't open $dir: $!";
    my @files = map { "$dir/$_"} grep {! /^\.\.?$/} readdir $dh;
#    print "Unlinking (@files) in $dir\n";
    File::Path::rmtree($_) foreach @files;
}

sub test_cache {
    my ($file, $pkg, $line) = caller;

    my $not_ok;
    foreach my $i (0 .. $#_) {
        my $ref = $_[$i] || return;
        my $_line = $line + $i;
        my ($dir, $name, $exists) = @$ref;
        if ($exists) {
            my $ok = -e "$dir/$name";
            ok($ok, "Line $_line: Found $name in $dir");
            $not_ok++ if ! $ok;
        } else {
            my $ok = ! -e "$dir/$name";
            ok($ok, "Line $_line: Didn't find $name in $dir");
            $not_ok++ if ! $ok;
        }
    }

    if ($not_ok) {
        print "#-------------------------\n";
        print `find $test_dir $test_dir2 -type f`;
        print "#-------------------------\n";
    }
}

###----------------------------------------------------------------###

pristine();

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok(! $Template::Alloy::GLOBAL_CACHE->{$name}, "Not in GLOBAL_CACHE");


###----------------------------------------------------------------###
print "### COMPILE_PERL => 0 ################################################\n";

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue'});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok(! $Template::Alloy::GLOBAL_CACHE->{$name}, "Not in GLOBAL_CACHE");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [GLOBAL_CACHE => 1]});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok($Template::Alloy::GLOBAL_CACHE->{$name}, "Is in GLOBAL_CACHE");

###----------------------------------------------------------------###

pristine();

my $cache = {};
process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [GLOBAL_CACHE => $cache]});
ok($cache->{$name}, "Is in CACHE");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_EXT => '.ttc']});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           );

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_DIR => $test_dir2]});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir,  "$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           );

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_DIR => $test_dir2, COMPILE_EXT => '.ttc']});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir,  "$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok(! $Template::Alloy::GLOBAL_CACHE->{$name}, "Is in GLOBAL_CACHE");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_DIR => $test_dir2, COMPILE_EXT => '.ttc', GLOBAL_CACHE => 1]});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir,  "$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok($Template::Alloy::GLOBAL_CACHE->{$name}, "Is in GLOBAL_CACHE");
ok(! $Template::Alloy::GLOBAL_CACHE->{$name}->{'_perl'}, "Doesn't Have perl");

###----------------------------------------------------------------###

if ($has_encode) {
    my $encoding = 'UTF-8';
    my $template = "[% blue %]BAR ¥";

    pristine($template, $encoding);

    my $in  = 'fü';
    my $out = 'füBAR ¥';

    process_ok($name => $out, {blue => $in, tt_config => [ENCODING => $encoding, COMPILE_EXT => '.ttc']});

    test_cache([$test_dir,  $name, 1],
               [$test_dir2, $name, 0],
               [$test_dir,  "$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
               [$test_dir,  "$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
               );

    process_ok($name => $out, {blue => $in, tt_config => [ENCODING => $encoding, COMPILE_EXT => '.ttc']});

    my $tt = $module->new(ENCODING => 'UTF8');
    $template = "\x{200b}";
    my $fail;
    $out = '';
    $tt->process(\$template, {}, \ $out) or $fail = $@;
    ok(!$fail, 'lives ok') || diag $fail;
}

###----------------------------------------------------------------###
print "### COMPILE_PERL => 1 ################################################\n";

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_PERL => 1]});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok(! $Template::Alloy::GLOBAL_CACHE->{$name}, "Not in GLOBAL_CACHE");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_PERL => 1, GLOBAL_CACHE => 1]});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok($Template::Alloy::GLOBAL_CACHE->{$name}, "Is in GLOBAL_CACHE");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_PERL => 1, COMPILE_EXT => '.ttc']});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  1],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           );

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_PERL => 1, COMPILE_DIR => $test_dir2]});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir,  "$name$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name$Template::Alloy::PERL_COMPILE_EXT",  1],
           );

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_PERL => 1, COMPILE_DIR => $test_dir2, COMPILE_EXT => '.ttc']});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir,  "$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  1],
           );
ok(! $Template::Alloy::GLOBAL_CACHE->{$name}, "Is in GLOBAL_CACHE");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_PERL => 1, COMPILE_DIR => $test_dir2, COMPILE_EXT => '.ttc', GLOBAL_CACHE => 1]});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir,  "$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           [$test_dir2, "$test_dir/$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  1],
           );
ok($Template::Alloy::GLOBAL_CACHE->{$name}, "Is in GLOBAL_CACHE");
ok($Template::Alloy::GLOBAL_CACHE->{$name}->{'_perl'}, "Has perl");

###----------------------------------------------------------------###

if ($has_encode) {
    my $encoding = 'UTF-8';
    my $template = "[% blue %]BAR ¥";

    pristine($template, $encoding);

    my $in  = 'fü';
    my $out = 'füBAR ¥';

    process_ok($name => $out, {blue => $in, tt_config => [ENCODING => $encoding, COMPILE_PERL => 1, COMPILE_EXT => '.ttc']});

    test_cache([$test_dir,  $name, 1],
               [$test_dir2, $name, 0],
               [$test_dir,  "$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
               [$test_dir,  "$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  1],
               );

    process_ok($name => $out, {blue => $in, tt_config => [ENCODING => $encoding, COMPILE_PERL => 1, COMPILE_EXT => '.ttc']});
}

###----------------------------------------------------------------###
print "### COMPILE_PERL => 2 ################################################\n";

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_PERL => 2, COMPILE_EXT => '.ttc', GLOBAL_CACHE => 1]});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir,  "$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok($Template::Alloy::GLOBAL_CACHE->{$name}, "Is in GLOBAL_CACHE");
ok(! $Template::Alloy::GLOBAL_CACHE->{$name}->{'_perl'}, "Doesn't Have perl");

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_PERL => 2, COMPILE_EXT => '.ttc', GLOBAL_CACHE => 1]});

test_cache([$test_dir,  $name, 1],
           [$test_dir2, $name, 0],
           [$test_dir,  "$name.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir,  "$name.ttc$Template::Alloy::PERL_COMPILE_EXT",  1],
           );
ok($Template::Alloy::GLOBAL_CACHE->{$name}, "Is in GLOBAL_CACHE");
ok($Template::Alloy::GLOBAL_CACHE->{$name}->{'_perl'}, "Has perl");

###----------------------------------------------------------------###
print "### STRING_REF #######################################################\n";

$name = \ "[% blue %]BAR";
my $file = Template::Alloy->string_id($name);

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue'});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir,  "$file$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$file$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok(! $Template::Alloy::GLOBAL_CACHE->{$file}, "Not in GLOBAL_CACHE");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [GLOBAL_CACHE => 1]});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir,  "$file$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$file$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok($Template::Alloy::GLOBAL_CACHE->{$file}, "Is in GLOBAL_CACHE");
ok(! $Template::Alloy::GLOBAL_CACHE->{$file}->{'_perl'}, "Doesn't Have perl");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [GLOBAL_CACHE => 1, CACHE_STR_REFS => 0]});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir,  "$file$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$file$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok(! $Template::Alloy::GLOBAL_CACHE->{$file}, "Not in GLOBAL_CACHE");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [GLOBAL_CACHE => 1, CACHE_STR_REFS => 0, COMPILE_PERL => 1]});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir,  "$file$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$file$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok(! $Template::Alloy::GLOBAL_CACHE->{$file}, "Not in GLOBAL_CACHE");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [GLOBAL_CACHE => 1, CACHE_STR_REFS => 0, COMPILE_PERL => 1, FORCE_STR_REF_PERL => 1]});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir,  "$file$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$file$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok(! $Template::Alloy::GLOBAL_CACHE->{$file}, "Not in GLOBAL_CACHE");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [GLOBAL_CACHE => 1, COMPILE_PERL => 1]});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir,  "$file$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$file$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok($Template::Alloy::GLOBAL_CACHE->{$file}, "Is in GLOBAL_CACHE");
ok($Template::Alloy::GLOBAL_CACHE->{$file}->{'_perl'}, "Has perl");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [GLOBAL_CACHE => 1, COMPILE_PERL => 2]});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir,  "$file$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$file$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok($Template::Alloy::GLOBAL_CACHE->{$file}, "Is in GLOBAL_CACHE");
ok(! $Template::Alloy::GLOBAL_CACHE->{$file}->{'_perl'}, "Doesn't Have perl");

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [GLOBAL_CACHE => 1, COMPILE_PERL => 2]});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir,  "$file$Template::Alloy::EXTRA_COMPILE_EXT", 0],
           [$test_dir,  "$file$Template::Alloy::PERL_COMPILE_EXT",  0],
           );
ok($Template::Alloy::GLOBAL_CACHE->{$file}, "Is in GLOBAL_CACHE");
ok($Template::Alloy::GLOBAL_CACHE->{$file}->{'_perl'}, "Now has perl");

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_DIR => $test_dir2]});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir2,  "$file$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir2,  "$file$Template::Alloy::PERL_COMPILE_EXT",  0],
           );

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_EXT => '.ttc']});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir,  "$file.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir,  "$file.ttc$Template::Alloy::PERL_COMPILE_EXT",  0],
           );

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_DIR => $test_dir2, COMPILE_PERL => 1]});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir2,  "$file$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir2,  "$file$Template::Alloy::PERL_COMPILE_EXT",  1],
           );

###----------------------------------------------------------------###

pristine();

process_ok($name => 'BlueBAR', {blue => 'Blue', tt_config => [COMPILE_EXT => '.ttc', COMPILE_PERL => 1]});

test_cache([$test_dir,  $file, 0],
           [$test_dir2, $file, 0],
           [$test_dir,  "$file.ttc$Template::Alloy::EXTRA_COMPILE_EXT", 1],
           [$test_dir,  "$file.ttc$Template::Alloy::PERL_COMPILE_EXT",  1],
           );

###----------------------------------------------------------------###
print "### DONE #############################################################\n";
