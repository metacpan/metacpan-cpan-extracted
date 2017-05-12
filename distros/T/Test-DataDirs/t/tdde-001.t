#!/usr/bin/perl 
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin qw($Bin);
use lib "$Bin/../lib";

my $bin = $Bin;

sub pkgvar {
    my $name = shift;
    my $caller = caller;
    no strict 'refs';
    
    return ${ *{"${caller}::$name"} };
}

sub path { [File::Spec->splitdir(shift),@_] } # Convenience function

{
    package A;
    use Test::More;

    # Simplest usage, with not parameters, should export
    # $data_dir and $temp_dir, check for $data_dir and create $temp_dir
    use Test::DataDirs::Exporter;

    is_deeply ::path($data_dir), ::path($bin, qw(data tdde-001)),
        "\$data_dir is set correctly";
    ok -d $data_dir, "$data_dir exists and is a directory";
    
    is_deeply ::path($temp_dir), ::path($bin, qw(temp tdde-001)),
        "\$temp_dir is set correctly";
    ok -d $temp_dir, "$temp_dir exists and is a directory";
}

{
    package B;
    use Test::More;

    # More prescriptive case, where variable names are mapped to
    # directories.  Should export variables $ip, $op, $oo and $ee to
    # map to directories 'hip', 'hop' below temp/tdde-001/' and
    # 'mee'. 'moo' below data/tdde-001/.
    use Test::DataDirs::Exporter (
        temp => [ip => 'hip', op => 'hop'],
        data => [oo => 'moo', ee => 'mee'],
    );

    is_deeply ::path($data_dir), ::path($bin, qw(data tdde-001)),
        "\$data_dir is set correctly";
    ok -d $data_dir, "$data_dir exists and is a directory";
    
    is_deeply ::path($temp_dir), ::path($bin, qw(temp tdde-001)),
        "\$temp_dir is set correctly";
    ok -d $temp_dir, "$temp_dir exists and is a directory";

    for (qw(oo ee)) {
        is_deeply ::path(::pkgvar($_)), ::path($bin, qw(data tdde-001), "m$_"),
            "\$$_ is set correctly";
        ok -d ::pkgvar($_), ::pkgvar($_ )." exists and is a directory";
    }

    for (qw(ip op)) {
        is_deeply ::path(::pkgvar($_)), ::path($bin, qw(temp tdde-001), "h$_"),
            "\$$_ is set correctly";
        ok -d ::pkgvar($_), ::pkgvar($_)." exists and is a directory";
    }
}

{
    package C;
    use Test::More;

    # Most prescriptive case, as above but s/tdde-001/zoon/
    use Test::DataDirs::Exporter (
        base => 'zoon',
        temp => [ip => 'hip', op => 'hop'],
        data => [oo => 'moo', ee => 'mee'],
    );

    is_deeply ::path($data_dir), ::path($bin, qw(data zoon)),
        "\$data_dir is set correctly";
    ok -d $data_dir, "$data_dir exists and is a directory";
    
    is_deeply ::path($temp_dir), ::path($bin, qw(temp zoon)),
        "\$temp_dir is set correctly";
    ok -d $temp_dir, "$temp_dir exists and is a directory";

    for (qw(oo ee)) {
        is_deeply ::path(::pkgvar($_)), ::path($bin, qw(data zoon), "m$_"),
            "\$$_ is set correctly";
        ok -d ::pkgvar($_), ::pkgvar($_ )." exists and is a directory";
    }

    for (qw(ip op)) {
        is_deeply ::path(::pkgvar($_)), ::path($bin, qw(temp zoon), "h$_"),
            "\$$_ is set correctly";
        ok -d ::pkgvar($_), ::pkgvar($_)." exists and is a directory";
    }
}


done_testing;
