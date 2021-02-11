requires 'Clone';
requires 'HTTP::Status';
requires 'List::Util';
requires 'Mojolicious';
requires 'Readonly';
requires 'Time::HiRes';
requires 'Try::Tiny';
requires 'UUID::Tiny';

suggests 'Cpanel::JSON::XS';
suggests 'IO::Socket::Socks';
suggests 'IO::Socket::SSL';
suggests 'Net::DNS::Native';
suggests 'Role::Tiny';

on 'test' => sub {
  requires 'Perl::Critic';
  requires 'Test::Pod';
  requires 'Test::Pod::Coverage';
  requires 'Test::Spec';
};

on develop => sub {
    requires 'Dist::Milla';
};
