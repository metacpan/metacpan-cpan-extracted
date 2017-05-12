package RRDTool::Rawish::Test;
use utf8;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(rrd_stub_new);

use RRDTool::Rawish;

our $RRDTOOL_PATH = '/usr/local/bin/rrdtool';

sub rrd_stub_new {
    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    return bless {
        command  => $RRDTOOL_PATH,
        remote   => $args{remote},
        rrdfile  => $args{rrdfile},
        rrderror => "",
    }, "RRDTool::Rawish";
}

1;
__END__
