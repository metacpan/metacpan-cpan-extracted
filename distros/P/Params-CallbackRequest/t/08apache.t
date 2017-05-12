#!perl -w

use strict;
use Test::More;
my $key = 'myCallbackTester';
my $cbs = [];

BEGIN {
    plan skip_all => 'Testing of apache_req requires Apache::FakeRequest'
      unless eval { require Apache::FakeRequest };
    plan tests => 15;
    use_ok('Params::CallbackRequest');
}

##############################################################################
# Make sure that Apache::FakeRequest inherits from Apache, and set up headers
# class for Apache::FakeRequest.
@Apache::FakeRequest::ISA = qw(Apache) unless @Apache::FakeRequest::ISA;
package Params::Callback::Test::Headers;
sub unset {}
sub new { bless {} }
sub add {
    my ($self, $key, $val) = @_;
    $self->{$key} = $val;
}

package main;

##############################################################################
# Set up a redirection callback function.
my $url = 'http://example.com/';
sub redir {
    my $cb = shift;
    my $val = $cb->value;
    $cb->redirect($url, $val);
}
push @$cbs, { pkg_key => $key,
              cb_key  => 'redir',
              cb      => \&redir
            };

# Set up a callback to check the redirected URL.
sub chk_url {
    my $cb = shift;
    my $val = $cb->value;
    main::is( $cb->redirected, $val, "Check redirected is '" .
              ($val || 'undef') . "'" );
}
push @$cbs, { pkg_key => $key,
              cb_key  => 'chk_url',
              cb      => \&chk_url
            };

##############################################################################
# Create the callback request object.
ok( my $cb_request = Params::CallbackRequest->new( callbacks => $cbs ),
    "Construct CBExec object" );
isa_ok($cb_request, 'Params::CallbackRequest' );

# Create an Apache request object.
ok( my $headers_in = Params::Callback::Test::Headers->new,
     "Create headers_in object" );
ok( my $err_headers_out = Params::Callback::Test::Headers->new,
     "Create err_headers_out object" );

ok( my $apache_req = Apache::FakeRequest->new(
    headers_in      => $headers_in,
    err_headers_out => $err_headers_out,
),
    "Create apache request object" );

# Execute the delayed redirection callback.
my %params = ( "$key|redir_cb"    => 1,
               "$key|chk_url_cb9" => $url );
is( $cb_request->request(\%params, apache_req => $apache_req), 302,
    "Execute delayed redir callback" );

# Check apache request values.
is_deeply $apache_req->{err_headers_out}, { Location => $url },
    "Check err_header_out";
delete $apache_req->{err_headers_out}{Location};
is( delete $apache_req->{method}, 'GET', "Check request method" );

##############################################################################
# Now execute an instant redirection (that is, with abort).
%params = ( "$key|redir_cb"    => 0 );
is( $cb_request->request(\%params, apache_req => $apache_req), 302,
    "Execute instant redir callback" );

# Check the Apache settings again.
is_deeply $apache_req->{err_headers_out}, { Location => $url },
    "Check err_header_out";
delete $apache_req->{err_headers_out}{Location};
is( delete $apache_req->{method}, 'GET', "Check request method" );

##############################################################################
# Now make sure that if there is no redirection that redirectd returns false,
# and that no abort status is returned.
%params = ( "$key|chk_url_cb" => undef );
is( $cb_request->request(\%params, apache_req => $apache_req), $cb_request,
    "Execute no redir callback" );

1;
__END__
