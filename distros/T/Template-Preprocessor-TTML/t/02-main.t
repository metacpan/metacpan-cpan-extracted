#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use File::Spec;
use Template::Preprocessor::TTML;

sub slurp
{
    my $filename = shift;
    return do { local $/; local *I; open I, "<", $filename; <I>};
}

sub trap
{
    my $callback = shift;
    local (*SAVEOUT, *ALTOUT);
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";
    local (*SAVEERR, *ALTERR);
    open ALTERR, ">", "alterr.txt";
    open SAVEERR, ">&STDERR";
    open STDERR, ">&ALTERR";
    my @ret;
    eval
    {
        @ret = $callback->();
    };
    my $except = $@;
    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);
    open STDERR, ">&SAVEERR";
    close(SAVEERR);
    close(ALTERR);
    if ($except)
    {
        die $except;
    }
    my $out = slurp("altout.txt");
    my $error = slurp("alterr.txt");
    return
    {
        'out' => $out, 'err' => $error, 'ret' => \@ret
    };
}

my $t_dir = File::Spec->catdir( File::Spec->curdir, "t" );
my $data_dir = File::Spec->catdir( $t_dir, "data" );
my $input_dir = File::Spec->catdir( $data_dir, "input" );
my $include_dir = File::Spec->catdir( $data_dir, "include" );
my $inc1_dir = File::Spec->catdir( $include_dir, "dir1" );
my $inc2_dir = File::Spec->catdir( $include_dir, "dir2" );

my $simple_ttml = File::Spec->catfile( $input_dir, "simple.ttml" );
my $hello_ttml = File::Spec->catfile( $input_dir, "hello.ttml" );
my $two_params_ttml = File::Spec->catfile( $input_dir, "two-params.ttml" );
my $explicit_includes_ttml = File::Spec->catfile( $input_dir, "explicit-includes.ttml" );
my $implicit_includes_ttml = File::Spec->catfile( $input_dir, "implicit-includes.ttml" );
my $invalid_ttml = File::Spec->catfile( $input_dir, "invalid.ttml" );


{
    my $pp = Template::Preprocessor::TTML->new('argv' => [$simple_ttml]);
    my $ret = trap(sub { $pp->run(); });
    # TEST
    is ($ret->{'out'}, "1+1=2\n", "Simple Non parameterized.");
}

{
    my $pp = Template::Preprocessor::TTML->new('argv' => ["-Dmyvar=World", $hello_ttml]);
    my $ret = trap(sub { $pp->run(); });
    # TEST
    is ($ret->{'out'}, "Hello World!\n", "Parameterized Output");
}

{
    my $pp = Template::Preprocessor::TTML->new('argv' => ["-Dmyvar=Shlomi", $hello_ttml]);
    my $ret = trap(sub { $pp->run(); });
    # TEST
    is ($ret->{'out'}, "Hello Shlomi!\n", "Parameterized Output");
}

{
    my $pp = Template::Preprocessor::TTML->new('argv' => ["-Da=18", "--define", "b=6", $two_params_ttml]);
    my $ret = trap(sub { $pp->run(); });
    # TEST
    is ($ret->{'out'}, "18+6=24\n", "Two Params");
}

{
    unlink("myout.txt");
    my $pp = Template::Preprocessor::TTML->new('argv' => ["-Da=18", "--define", "b=6", "-o", "myout.txt", $two_params_ttml]);
    my $ret = trap(sub { $pp->run(); });
    # TEST
    is ($ret->{'out'}, "", "Output is Empty on -o");
    # TEST
    is (slurp("myout.txt"), "18+6=24\n", "Two Params");
}

{
    my $pp = Template::Preprocessor::TTML->new('argv' => ["--include", $inc1_dir, "-I".$inc2_dir, $explicit_includes_ttml]);
    my $ret = trap(sub { $pp->run(); });
    # TEST
    like ($ret->{'out'}, qr{posix is smith}, "Includes");
}

{
    my $pp = Template::Preprocessor::TTML->new(
        'argv' =>
        [
            "--include", $inc1_dir, "-I".$inc2_dir,
            "--includefile", "header.tt2", "--includefile=inc2.tt2",
            $implicit_includes_ttml
        ]);
    my $ret = trap(sub { $pp->run(); });
    # TEST
    like ($ret->{'out'}, qr{posix is smith}, "Implicit Includes");
}

{
    my $pp = Template::Preprocessor::TTML->new(
        'argv' => ["--help"],
    );
    my $ret = trap(sub { $pp->run(); });
    # TEST
    like ($ret->{'out'}, qr{--help}, "Help #1");
    # TEST
    like ($ret->{'out'}, qr{--include}, "Help #2");
    # TEST
    like ($ret->{'out'}, qr{-D}, "Help #3");
}

{
    my $pp = Template::Preprocessor::TTML->new(
        'argv' => ["-V"],
    );
    my $ret = trap(sub { $pp->run(); });
    # TEST
    like ($ret->{'out'}, qr{This is TTML version}, "Help #1");
}

{
    my $pp = Template::Preprocessor::TTML->new('argv' => [$invalid_ttml]);
    my $ret;
    eval {
        $ret = trap(sub { $pp->run(); });
    };
    # TEST
    ok ($@, "Throws an excpetion on invalid input.");
}
