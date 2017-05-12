use strict;
use warnings;

use Exporter qw(import);
use File::Temp;

our @EXPORT_OK = qw(
    slurp
    spurt
    write_pod
);

sub slurp {
    my ($file) = @_;

    # http://www.perl.com/pub/2003/11/21/slurp.html
    return $file
        ? do { local ( @ARGV, $/ ) = $file; <> }
        : do { local $/; <STDIN> };
}

sub spurt {
    my ( $content, $file, %options ) = @_;
    my $write_mode = $options{append} ? '>>' : '>';
    open( my $handle, $write_mode, $file )
        || croak("unable to open [$file]: $!");
    print( $handle $content );
    close($handle);
}

sub pod_string {
    my ($pod) = @_;

    my @lines = split( /\n/, $pod );
    shift(@lines) while ( @lines && $lines[0] =~ /^\s*$/ );
    if ( $lines[0] =~ /^(\s+)/ ) {
        my $padding = length($1);
        @lines =
            map { length($_) >= $padding ? substr( $_, $padding ) : '' } @lines;
    }

    return join( "\n", @lines );
}

sub write_pod {
    my ( $pod, %options ) = @_;

    my $file = $options{file} || File::Temp->new();

    spurt( pod_string($pod), $file, %options );

    return $file;
}
