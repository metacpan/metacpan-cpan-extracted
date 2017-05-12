package TestPHP;
use IPC::Open2;
use base qw( Exporter );

our @EXPORT = qw( read_php find_php );
our @EXPORT_OK = qw( );

sub find_php
{
    my $bin = '/www/php/bin/php';
    return -f $bin ? $bin : undef;
}

sub read_php
{
    my ( $code ) = @_;

    open2( my $read, my $write, find_php() ) or die $!;
    print $write $code or die $!;
    close $write or die $!;
    my $php = do { local $/; <$read> };
    close $read or die $!;

    return $php;
}


1;
