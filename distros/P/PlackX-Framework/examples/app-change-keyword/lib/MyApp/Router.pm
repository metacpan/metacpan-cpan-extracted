#!perl
use v5.36;
package MyApp::Router {
  use parent 'PlackX::Framework::Router';
  sub filter_request_keyword { 'pxf_filter'; }
  sub route_request_keyword  { 'pxf_route';  }
  sub uri_base_keyword       { 'pxf_base';   }
}

1;
