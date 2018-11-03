package TaskPipe::Task_WhoIs::Settings;

use Moose;

has whois_mgr_module => (is => 'ro', isa => 'Str', default => 'TaskPipe::WhoisManager');

1;
