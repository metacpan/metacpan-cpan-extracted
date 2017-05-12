use strict;
use warnings;

use Test::More;

use Pod::2::DocBook;

BEGIN {
    eval "require XML::LibXML" or plan skip_all => 'test requires XML::LibXML';
    plan tests => 2;
    use_ok 'Pod::2::DocBook';
}

my $parser = Pod::2::DocBook->new ( title => 'My Article', doctype => 'refentry', );

my $output;
open my $output_fh, '>', \$output;
my $input = join '', <DATA>;
open my $input_fh, '<', \$input;;

$parser->parse_from_filehandle( $input_fh, $output_fh );

eval { XML::LibXML->new->parse_string( $output ) };
ok !$@, 'refentry output is valid xml' 
    or diag $@;

__DATA__

=head1 NAME

    Hi there!

This is some very simple pod

=cut


