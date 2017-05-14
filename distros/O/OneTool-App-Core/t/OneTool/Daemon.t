#!/usr/bin/perl

=head1 NAME

t/OneTool/Daemon.t

=head1 DESCRIPTION

Tests for OneTool::Daemon module

=cut

use strict;
use warnings;

use FindBin;
use Test::More;

use lib "$FindBin::Bin/../../lib/";

require_ok('Log::Log4perl');
require_ok('OneTool::Daemon');

Log::Log4perl->easy_init();

my %api = (
    '/api/test' => {
        method => 'GET',
        action => sub {
            my ($self) = @_;
            return (to_json('key' => 'value'));
            }
    }
);

my %conf = (
    ip     => '127.0.0.1',
    port   => '7777',
    api    => \%api,
    logger => Log::Log4perl->get_logger()
);

my $daemon = OneTool::Daemon->new(\%conf);

#$daemon->Listener();

$daemon->Log('invalid_level', 'test');
$daemon->Log('INFO',          'test');

done_testing(2);

=head1 AUTHOR

Sebastien Thebert <contact@onetool.pm>

=cut
