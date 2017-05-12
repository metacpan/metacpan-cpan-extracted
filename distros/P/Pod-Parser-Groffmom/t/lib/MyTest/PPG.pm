package MyTest::PPG;

use strict;
use warnings;
use Carp 'croak';
use Pod::Parser::Groffmom;

use base 'Exporter';
our @EXPORT = qw(
  head
  body
  get_mom
);
our %EXPORT_TAGS = ( all => \@EXPORT );

sub head {
    my ( $data, $lines ) = @_;
    $lines ||= 1;
    $lines--;
    my @lines = split "\n" => $data;
    return @lines[ 0 .. $lines ];
}

sub body {
    my $data = shift;
    $data =~ s/^.*\n.START//s;
    return $data;
}

sub get_mom {
    my $pod = shift;
    open my $fh, '<', \$pod
        or croak("Could not create filehandle from ($pod)");
    my $parser = Pod::Parser::Groffmom->new;
    $parser->parse_from_filehandle($fh);
    return $parser->mom;
}

1;
