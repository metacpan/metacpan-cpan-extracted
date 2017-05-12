package A::Junk;

use Sub::Exporter::Progressive -setup => {
  exports => [qw(junk1 junk2 junk3)],
  groups => {
     default => ['junk2'],
     other => ['junk3'],
  },
};

sub junk1 { 1 }
sub junk2 { 1 }
sub junk3 { 1 }

1;
