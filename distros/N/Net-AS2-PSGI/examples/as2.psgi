=head1 NAME

as2.psgi - Example AS2 Protocol Server

=head1 DESCRIPTION

Example server implementing the AS2 file transfer protocol.

=cut

use strict;
use warnings;

use Config::General qw();
use Date::Format    qw();
use File::Basename  qw(dirname);
use Log::Dispatch   qw();

use Plack::Builder;

use Net::AS2::PSGI;

my $conf_file = dirname(__FILE__) . '/as2.conf';

my %config = Config::General::ParseConfig($conf_file);

# Setup logging
my @loggers;
if ($config{log_facility} eq 'STDERR') {
    my $handle = IO::Handle->new_from_fd(\*STDERR, 'w');
    $handle->autoflush(1);
    push @loggers, [
        'Handle',
        min_level => 'debug',
        newline   => 1,
        name      => $config{log_facility},
        handle    => $handle,
    ];
}
elsif ($config{log_facility} =~ qr{^/}) {
    push @loggers, [
        'File',
        min_level => 'debug',
        newline   => 1,
        mode      => '>>',
        name      => 'log_facility',
        filename  => $config{log_facility},
    ];
}
else {
    push @loggers, [
        'Syslog',
        min_level => 'debug',
        newline   => 1,
        ident     => 'AS2',
        facility  => $config{log_facility},
    ];
}

my $logger = Log::Dispatch->new(
    outputs   => \@loggers,
    callbacks => sub {
        my %args = @_;
        return Date::Format::time2str('%b %e %k:%M:%S', time) . " [$args{level}] $args{message}";
    },
);

# Initialise directories
Net::AS2::PSGI->init(\%config, $logger);

builder {
    enable "LogDispatch", logger => $logger;
    mount "/view"     => Net::AS2::PSGI->view_psgi();
    mount "/"         => Net::AS2::PSGI->app_psgi();
};
