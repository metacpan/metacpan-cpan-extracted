=head1 NAME

B.psgi - AS2 Protocol Server for B

=head1 DESCRIPTION

Test server, B, implementing the AS2 file transfer protocol.

=cut

use strict;
use warnings;

#use Date::Format qw();
#use Log::Dispatch;
use Cwd            qw(abs_path);
use File::Basename qw(dirname);

my $dir = dirname(abs_path(__FILE__));

use Plack::Builder;

use Net::AS2::PSGI;
$Net::AS2::PSGI::CERTIFICATE_DIR = "$dir/certificates";
$Net::AS2::PSGI::PARTNERSHIP_DIR = "$dir/partnerships";
$Net::AS2::PSGI::FILE_DIR        = "$dir/files";

# Initialise directories
Net::AS2::PSGI->init();

builder {
#    enable "LogDispatch", logger => $logger;
#    enable 'StackTrace';
#    enable 'Lint';
    mount "/view"     => Net::AS2::PSGI->view_psgi();
    mount "/"         => Net::AS2::PSGI->app_psgi();
};
