use strict;
use warnings;

# Provide a simple server that can be used to test the various bits.
package TestServer;
use base qw/Test::HTTP::Server::Simple HTTP::Server::Simple::CGI/;

use Time::HiRes qw(sleep time);
use Data::Dumper;
use LWP::UserAgent;
use File::Slurp;

sub handle_request {
    my ( $self, $cgi ) = @_;
    my $params      = $cgi->Vars;
    my $request_uri = $ENV{REQUEST_URI};

    my $file = "t/templates" . $request_uri;

    my $content               #
        = -e $file            #
        ? read_file($file)    #
        : '';

    my $status = $content ? 200 : 404;

    print $cgi->header(
        -status => $status,
        -nph    => 1,
    );
    print $content;
    
    # warn "PWD: ". `pwd`;
    # warn "SERVER: $file: $status - $content";

    # # Flush the output so that it goes straight away. Needed for the timeout
    # # trickle tests.
    # $self->stdout_handle->autoflush(1);
    #
    #  # warn "START REQUEST - " . time;
    #  # warn Dumper($params);
    #
    # # Do the right thing depending on what is asked of us.
    # if ( exists $params->{redirect} ) {
    #     my $num = $params->{redirect} || 0;
    #     $num--;
    #
    #     if ( $num > 0 ) {
    #         print $cgi->redirect( -uri => "?redirect=$num", -nph => 1, );
    #         print "You are being redirected...";
    #     }
    #     else {
    #         print $cgi->header( -nph => 1 );
    #         print "No longer redirecting";
    #     }
    # }
    #
    # elsif ( exists $params->{delay} ) {
    #     sleep( $params->{delay} );
    #     print $cgi->header( -nph => 1 );
    #     print "Delayed for '$params->{delay}'.\n";
    # }
    #
    # elsif ( exists $params->{trickle} ) {
    #
    #     print $cgi->header( -nph => 1 );
    #
    #     my $trickle_for = $params->{trickle};
    #     my $finish_at   = time + $trickle_for;
    #
    #     local $| = 1;
    #
    #     while ( time <= $finish_at ) {
    #         print time . " trickle $$\n";
    #         sleep 0.1;
    #     }
    #
    #     print "Trickled for '$trickle_for'.\n";
    # }
    #
    # elsif ( exists $params->{bad_header} ) {
    #     my $headers = $cgi->header( -nph => 1, );
    #
    #     # trim trailing whitspace to single newline.
    #     $headers =~ s{ \s* \z }{\n}xms;
    #
    #     # Add a bad header:
    #     $headers .= "Bad header: BANG!\n";
    #
    #     print $headers . "\n\n";
    #     print "Produced some bad headers.";
    # }
    #
    # elsif ( my $when = $params->{break_connection} ) {
    #
    #     for (1) {
    #         last if $when eq 'before_headers';
    #         print $cgi->header( -nph => 1 );
    #
    #         last if $when eq 'before_content';
    #         print "content\n";
    #     }
    # }
    #
    # elsif ( my $id = $params->{set_time} ) {
    #     my $now = time;
    #     print $cgi->header( -nph => 1 );
    #     print "$id\n$now\n";
    # }
    #
    # elsif ( exists $params->{not_modified} ) {
    #     my $last_modified = HTTP::Date::time2str( time - 60 * 60 * 24 );
    #     print $cgi->header(
    #         -status         => '304',
    #         -nph            => 1,
    #         'Last-Modified' => $last_modified,
    #     );
    #     print "content\n";
    # }
    #
    # else {
    #     warn "DON'T KNOW WHAT TO DO: " . Dumper $params;
    # }
    #
    # # warn "STOP REQUEST  - " . time;

}

1;
