package Mojolicious::Plugin::DigestAuth::Util;

use strict;
use warnings;

use Mojo::Util qw{md5_sum unquote};
use base 'Exporter';

our @EXPORT_OK = qw{checksum parse_header};

sub checksum
{
  md5_sum join ':', grep(defined, @_);
}

sub parse_header
{
    my $header = shift;
    my $parsed;

    # TODO: I think there's a browser with a quoting issue that might affect this
    if($header && $header =~ s/^Digest\s//) {
        while($header =~ /([a-zA-Z]+)=(".*?"|[^,]+)/g){
	  $parsed->{$1} = unquote($2);
        }
    }

    $parsed;
}


1;
