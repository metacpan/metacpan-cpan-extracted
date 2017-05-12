# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-AWS-SES.t'
#########################
# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use Test::More tests => 25;
use MIME::Entity;
BEGIN { use_ok('Net::AWS::SES') }
SKIP: {
    skip( "Environmental variables are not set", 23 )
      unless ( $ENV{AWS_SES_ACCESS_KEY}
        && $ENV{AWS_SES_SECRET_KEY}
        && $ENV{AWS_SES_IDENTITY} );
    my $ses = Net::AWS::SES->new(
        access_key => $ENV{AWS_SES_ACCESS_KEY},
        secret_key => $ENV{AWS_SES_SECRET_KEY},
        from       => $ENV{AWS_SES_IDENTITY},
        region     => 'us-east-1'

    );
    ok( $ses && $ses->access_key && $ses->secret_key,
        "Net::AWS::SES->new" );
    ok( $ses->region && ($ses->region eq 'us-east-1'), "Region is " . $ses->region);
    my $r;
    ########## PLAIN
    $r = $ses->send(
        From      => 'sherzodr@cpan.org',
        To        => 'sherzodr@gmail.com',
        Subject   => "Hello world from AWS SES",
        Body      => "Hello again",
        Body_html => "<h1>Салом Шоҳ</h1>",
    );

    #print "send(): ", $r->result_as_json;
    ok( $r->is_error,         $r->error_message );
    ok( $r->request_id,       $r->request_id );
    ok( $r->error_type,       $r->error_type );
    ok( $r->http_code == 400, 'code: ' . $r->http_code );
    ok( $r->error_code,       $r->error_code );
    ok( !$r->message_id,      "Message ID does not exist" );
    ok( $r->result,           "Result set exists even for error" );
    ################# MIME
    my $msg = MIME::Entity->build(
        From    => $ENV{AWS_SES_IDENTITY},
        To      => $ENV{AWS_SES_IDENTITY},
        Subject => 'MIME msg from AWS SES',
        Data    => "<h1>Hello world from AWS SES</h1>",
        Type    => 'text/html'
    );
    ##### ATTACHMENTS
    $msg->attach(
        Path     => File::Spec->catfile( 't', 'image.gif' ),
        Type     => 'image/gif',
        Encoding => 'base64'
    );
    $r = $ses->send($msg);
    ok( $r->is_success,
        $r->is_success ? "send_mime() success" : $r->error_message );
    ok( $r->request_id, "Request id: " . $r->request_id );
    ok( $r->result,     "Result element found" );
    ok( $r->message_id, "Message sent successfully" );
    #
    $r = $ses->verify_email('sherzodr@gmail.com');

    #print "verify_email(): ", $r->result_as_json;
    ok( $r->is_success && $r->request_id );
    $r = $ses->list_emails();

    #print "list_emails(): ", $r->result_as_json;
    ok( $r->is_success && $r->request_id && $r->result );
    ok( @{ $r->result->{Identities} } > 2, "over two verified emails" );

    #foreach my $email (@{ $r->result->{Identities} }) {
    #    printf("%s\n", $email);
    #}
    $r = $ses->list_domains();

    #print "list_domains(): ", $r->result_as_json;
    ok( $r->is_success );
    ok( @{ $r->result->{Identities} } == 1, "One verified domain" );
    ok( $r->result->{Identities}->[0] eq 'talibro.com',
        "Verified domain is talibro.com" );
    $r = $ses->delete_identity('sherzodr@gmail.com');

    #print "delete_identnity(): ", $r->result_as_json;
    ok( $r->is_success && $r->request_id, $r->request_id );
    $r = $ses->get_quota;

    #print "get_quota(): ", $r->result_as_json;
    ok(      $r->is_success
          && $r->request_id
          && ( $r->result->{'Max24HourSend'} == 10000 )
          && ( $r->result->{MaxSendRate} == 5 )
          && $r->result->{SentLast24Hours} );
    $r = $ses->get_dkim_attributes('sherzodr@gmail.com');

    #print "get_dkim_attributes(): ", $r->result_as_json;
    ok( $r->is_success && !defined( $r->dkim_attributes ),
        "No Dkim attributes for this address" );
    $r = $ses->get_dkim_attributes( $ENV{AWS_SES_IDENTITY} );
    ok( $r->is_success && $r->dkim_attributes );
    $r = $ses->get_statistics();
    ok( $r->is_success );
    
    #print "get_statistics(): ", $r->result_as_json;
} ## end SKIP:
done_testing();
