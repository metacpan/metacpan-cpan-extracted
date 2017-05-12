package Pod::Readme::Test;

use Exporter qw/ import /;
use IO::String;

require Test::More;

our $out;
our $io = IO::String->new($out);
our $prf;

our @EXPORT    = qw/ $prf $out $io filter_lines reset_out /;
our @EXPORT_OK = @EXPORT;

sub filter_lines {
    my @lines = @_;
    foreach my $line (@lines) {
        Test::More::note $line if $line =~ /^=(?:\w+)/;
        $prf->filter_line( $line . "\n" );
    }
}

sub reset_out {
    $io->close;
    $out = '';
    $io->open($out);
}

1;
