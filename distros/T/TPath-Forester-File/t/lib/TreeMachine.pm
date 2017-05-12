package TreeMachine;

# makes directory tree hierarchies for testing purposes

use v5.10;
use strict;
use warnings;
use autodie;
use File::Temp ();
use File::Path qw(rmtree);
use Cwd qw(getcwd);
use Encode qw(encode);

use base 'Exporter';

our @EXPORT = qw(file_tree rmtree);

sub recursive_delete {
    my $dir = shift;
    opendir( my $dh, $dir );
    for my $f ( readdir $dh ) {
        next if $f =~ /^\.\.?$/;
        if ( -d $f ) {
            recursive_delete($f);
        }
        else {
            unlink $f;
        }
    }
    rmdir $dir;
}

sub file_tree {
    my $arg      = shift;
    my $name     = $arg->{name};
    my $subfiles = $arg->{children};
    if ($subfiles) {
        mkdir $name;
        my @subfiles = @$subfiles;
        if (@subfiles) {
            my $d = getcwd;
            chdir $name;
            file_tree($_) for @subfiles;
            chdir $d;
        }
    }
    elsif ( $arg->{binary} ) {
        make_binary($name);
    }
    else {
        make_text($arg);
    }
    chmod oct($arg->{mode}), $name if exists $arg->{mode};
}

sub make_binary {
    my $name = shift;
    open( my $fh, '>:raw', $name );
    for ( 0 .. 1 + int rand 1024 ) {
        print $fh pack( 'b', int rand 255 );
    }
    close $fh;
}

sub make_text {
    my $arg = shift;
    my ( $name, $encoding, $text ) = @$arg{qw(name encoding text)};
    $encoding //= 'UTF-8';
    open( my $fh, '>', $name );
    my $octets = encode( $encoding, $text );
    binmode $fh;
    print $fh $octets;
    close $fh;
}

1;
