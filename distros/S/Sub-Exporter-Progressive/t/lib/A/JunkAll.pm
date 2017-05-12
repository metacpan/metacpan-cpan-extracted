package A::JunkAll;

use Sub::Exporter::Progressive -setup => {
  exports => [qw(junk1 junk2)],
  groups => {
     default => [ -all ],
  },
};

sub junk1 { 1 }
sub junk2 { 1 }

1;
