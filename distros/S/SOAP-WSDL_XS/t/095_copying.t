use strict;
use warnings;
use Test::More;
use File::Find;
if ( not $ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

require Test::Pod::Content;
import Test::Pod::Content;

my $dir = 'blib/lib';
if (-d '../t') {
    $dir = '../lib';
}

my @filelist = ();
find( \&filelist, $dir);

sub filelist {
    my $name = $_;
    return if (-d $name);
    return if $File::Find::name =~m{\.svn}x;
    return if $File::Find::name !~m{\.p(?:m|od)$}x;

    # skip builtin XSD types - they contain no pod
    return if $File::Find::name =~m{SOAP/WSDL/Expat/MessageParser_XS\.pm}xms;

    push @filelist, $File::Find::name;
}

plan tests => scalar @filelist;

for my $file (sort @filelist) {
    pod_section_like( $file, 'LICENSE AND COPYRIGHT', qr{ This \s file \s is \s part \s of
        \s SOAP-WSDL_XS\. \s You \s may \s distribute/modify \s it \s under \s
        the \s same \s terms \s as \s perl \s itself
    }xms, "$file License notice");
}
