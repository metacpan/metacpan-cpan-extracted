requires 'Clone';
requires 'HTTP::Status';
requires 'List::Util',  '1.44';
requires 'Mojolicious', '>= 8';
requires 'Readonly';
requires 'Time::HiRes';
requires 'Try::Tiny';
requires 'UUID::Tiny';
requires 'perl', 'v5.24.1';

feature 'cgiapp', 'CGI::Application plugin' => sub {
  requires 'CGI';
  requires 'CGI::Application';
};

suggests 'Cpanel::JSON::XS';
suggests 'IO::Socket::Socks';
suggests 'IO::Socket::SSL';
suggests 'Net::DNS::Native';
suggests 'Role::Tiny';

on 'test' => sub {
  requires 'Capture::Tiny';
  requires 'CGI';
  requires 'CGI::Application';
  requires 'LWP::UserAgent';
  requires 'Perl::Critic';
  requires 'Test::Exception';
  requires 'Test::Pod::Coverage';
  requires 'Test::Pod';
  requires 'Test::Snapshot';
  requires 'Test::Spec';
};

on develop => sub {
  requires 'Dist::Milla';
};

