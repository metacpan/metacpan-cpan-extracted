  use strict;
  use Data::Dumper;
  use Parse::IASLog;

  while (<>) {
        chomp;
        my $record = parse_ias( $_ );
        next unless $record;
        print Dumper( $record );
  }
