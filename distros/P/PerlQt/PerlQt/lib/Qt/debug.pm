package Qt::debug;
use Qt;

our %channel = (
    'ambiguous' => 0x01,
    'autoload' => 0x02,
    'calls' => 0x04,
    'gc' => 0x08,
    'virtual' => 0x10,
    'verbose' => 0x20,
    'all' => 0xffff
);

sub import {
    shift;
    my $db = (@_)? 0x0000 : (0x01|0x20);
    my $usage = 0;
    for my $ch(@_) {
        if( exists $channel{$ch}) {
             $db |= $channel{$ch};
        } else {
             warn "Unknown debugging channel: $ch\n";
             $usage++;
        }
    }
    Qt::_internal::setDebug($db);    
    print "Available channels: \n\t".
          join("\n\t", sort keys %channel).
          "\n" if $usage;
}

sub unimport {
    Qt::_internal::setDebug(0);    
}

1;