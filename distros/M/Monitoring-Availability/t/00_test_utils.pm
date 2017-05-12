#!/usr/bin/env perl

package TestUtils;

#########################
# Test Utils
#########################

use strict;
use Exporter;
use Data::Dumper;
use Test::More;

use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw ($logger);

#########################
# create a logger object if we have log4perl installed
our $logger;
eval {
    if(defined $ENV{'TEST_LOG'}) {
        require Log::Log4perl;
        Log::Log4perl->import(qw(:easy));
        Log::Log4perl->init(\ q{
            log4perl.logger                    = DEBUG, Screen
            log4perl.appender.Screen           = Log::Log4perl::Appender::ScreenColoredLevels
            log4perl.appender.Screen.stderr    = 1
            log4perl.appender.Screen.Threshold = DEBUG
            log4perl.appender.Screen.layout    = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.Screen.layout.ConversionPattern = [%d] %m%n
        });
        $logger = get_logger();
    }
};



#########################
sub check_array_one_by_one {
    my $exp  = shift;
    my $got  = shift;
    my $name = shift;

    for(my $x = 0; $x <= scalar @{$exp}; $x++) {
        Test::More::is_deeply($got->[$x], $exp->[$x], $name.' '.$x) or Test::More::diag("got:\n".Dumper($got->[$x])."\nbut expected:\n".Dumper($exp->[$x]));
    }
    return 1;
}
#########################
sub parse_logs {
    my $text = shift;
    print "my \$expected_log = [\n";
    for my $line (split/\n/, $text) {
        my($start,$end,$duration,$type,$plugin_output) = split/\t/, $line;
        print "    { 'start' => '".$start."', 'end' => '".$end."', 'duration' => '".$duration."', 'type' => '".$type."', 'plugin_output' => '".$plugin_output."' }, \n";
    }
    print "];\n";
}

1;

__END__
