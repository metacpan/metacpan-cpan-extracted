package TaskPipe::WhoisManager::Settings;

use Moose;

has whois_mgr_module => (is => 'ro', isa => 'Str', default => 'Net::Whois::Raw');

1;
