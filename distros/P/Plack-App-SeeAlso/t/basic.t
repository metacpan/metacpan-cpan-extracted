use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::App::SeeAlso;

use feature ':5.10';

my $app = Plack::App::SeeAlso->new(
    Query => sub {
        my $id = shift;
        return unless $id =~ /:/;
        push_seealso [ uc($id) ], "1:$id", "2:$id", "3:$id";
    },
#    Stylesheet => 1,
);

sub read_file { do { local( @ARGV, $/ ) = $_[0] ; <> } }

test_psgi $app, sub {
    my $cb  = shift;

    my $res = $cb->(GET "/?id=a:b&format=seealso");
    is( $res->code, 200, 'found');
    is( $res->content, '["A:B",["1:a:b"],["2:a:b"],["3:a:b"]]', 'found' );

    $res = $cb->(GET "/?id=ab&format=seealso");
    is( $res->code, 200, 'not found, but 200');
    is( $res->content, '["ab",[],[],[]]',, 'not found, but response' );

    $res = $cb->(GET "/?id=ab");
    my $content = $res->content;
    chomp $content; $content .= "\n";
    $content =~ s/<\?seealso-query-base.*\?>//m;
    is( $content, read_file('t/unapi1.xml'), 'unAPI format list' );
};

done_testing;
