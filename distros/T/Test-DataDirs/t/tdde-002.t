#!/usr/bin/perl 
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../ll/lib/perl5";

# Failures expected this time

{
    package A;
    use Test::Exception;

    # This should die because there is no dir data/tdde-002
    throws_ok {
        require 'Test/DataDirs/Exporter.pm';
        Test::DataDirs::Exporter->import;
    }  qr{No such data directory '.*t.data.tdde-002'},
        "No dir 'tdde-002'";

}

{
    package B;
    use Test::Exception;

    # This should die because there is no dir data/tdde-002
    throws_ok {
        require 'Test/DataDirs/Exporter.pm';
        Test::DataDirs::Exporter->import(
            temp => [ip => 'hip', op => 'hop'],
            data => [oo => 'moo', ee => 'mee'],
        );
    } qr{No such data directory '.*t.data.tdde-002'},
        "No dir 'tdde-002'";

}

{
    package C;
    use Test::Exception;

    # This should die because there is no dir data/nonesuch
    throws_ok {
        require 'Test/DataDirs/Exporter.pm';
        Test::DataDirs::Exporter->import(
            base => 'nonesuch',
            temp => [ip => 'hip', op => 'hop'],
            data => [oo => 'moo', ee => 'mee'],
        );
    } qr{No such data directory '.*t.data.nonesuch'}, 
        "No dir 'nonesuch'";
}

done_testing;
