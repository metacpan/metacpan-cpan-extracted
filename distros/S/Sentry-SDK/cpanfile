requires 'Clone';
requires 'HTTP::Status';
requires 'List::Util', '1.44';
requires 'Mojolicious';
requires 'Readonly';
requires 'Time::HiRes';
requires 'Try::Tiny';
requires 'UUID::Tiny';
requires 'perl', 'v5.24.1';

suggests 'Cpanel::JSON::XS';
suggests 'IO::Socket::Socks';
suggests 'IO::Socket::SSL';
suggests 'Net::DNS::Native';
suggests 'Role::Tiny';

on 'test' => sub {
  requires 'LWP::UserAgent';
  requires 'Perl::Critic';
  requires 'Test::Pod::Coverage';
  requires 'Test::Pod';
  requires 'Test::Snapshot';
  requires 'Test::Spec';
};

on develop => sub {
    requires 'Dist::Milla';
};
