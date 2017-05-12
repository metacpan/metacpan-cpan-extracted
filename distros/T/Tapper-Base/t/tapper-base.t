#!/usr/bin/env perl

use warnings;
use strict;
use Log::Log4perl;
use File::Temp;
use English '-no_match_vars';

my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


use Test::More;

package Foo::Test;
use Moose;

use Tapper::Base;
extends 'Tapper::Base';

# want to test OO interface thus we need a separate class since Moose doesn't
# offer it's tricks to main
sub test_log_and_exec
{
        my ($self, @cmd) = @_;
        return $self->log_and_exec(@cmd);
}

package main;

my $test   = Foo::Test->new();
SKIP: {
        skip "qx testing requires a knows executable. We work with /bin/sh which has to exist on all POSIX platforms. Win does not have it." if $OSNAME =~ /MS/;
        my $retval = $test->test_log_and_exec('true');
        is($retval, 0, 'Log_and_exec in scalar context');

        my $ft = File::Temp->new();
        my $filename = $ft->filename;

        $test = Tapper::Base->new();

        local $SIG{CHLD} = 'IGNORE';

}

done_testing();
