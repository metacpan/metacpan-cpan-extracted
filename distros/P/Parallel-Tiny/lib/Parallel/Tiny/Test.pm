package Parallel::Tiny::Test;
use strict;
use warnings;
use File::Temp qw(tempfile);

sub new {
    my ( $fh, $filename ) = tempfile();
    return bless( { tempfile => $fh, filename => $filename }, shift );
}

sub run {
    my $self = shift;
    my $file = $self->{tempfile};
    print $file 1;
    close($file);
}

1;

