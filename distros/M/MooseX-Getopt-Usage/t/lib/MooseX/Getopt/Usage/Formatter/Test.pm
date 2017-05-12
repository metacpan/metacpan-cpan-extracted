package MooseX::Getopt::Usage::Formatter::Test;

use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Test::Exception;
use MooseX::Getopt::Usage::Formatter;
use Basic;
use PodUsage;

sub constructor : Test(2) {
    my $self = shift;

    my $tclass = "MooseX::Getopt::Usage::Formatter";
    throws_ok { $tclass->new() } qr/Attribute \(getopt_class\) is required/,
        "No args fails (need getopt_class)";

    lives_ok {
        $tclass->new( getopt_class => 'MooseX::Getopt::Usage::Formatter::Test' )
    } "Only getopt_class";
}

sub format : Test(2) {
    my $self = shift;

    my $fmtr = MooseX::Getopt::Usage::Formatter->new( getopt_class => 'Basic' );
    is $fmtr->format, "%c [OPTIONS]", "Default when no POD";

    $fmtr = MooseX::Getopt::Usage::Formatter->new( getopt_class => 'PodUsage' );
    is $fmtr->format, " hello\$ %c [OPTIONS] [FILE]\n", "Reads from POD";
}

1;
