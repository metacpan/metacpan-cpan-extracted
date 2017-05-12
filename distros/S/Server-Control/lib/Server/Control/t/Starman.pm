package Server::Control::t::Starman;
use base qw(Server::Control::t::Base);
use File::Slurp;
use Server::Control::Starman;
use Starman;
use Test::Most;
use strict;
use warnings;

my $app_psgi_content = "
return [
    '200',
    [ 'Content-Type' => 'text/plain' ],
    [ 'Hello World' ],
];
";

sub create_ctl {
    my ( $self, $port, $temp_dir, %extra_params ) = @_;

    my $app_psgi = "$temp_dir/app.psgi";
    write_file( $app_psgi, $app_psgi_content );

    return Server::Control::Starman->new(
        %extra_params,
        app_psgi => $app_psgi,
        options  => {
            port      => $port,
            workers   => 2,
            pid       => "$temp_dir/starman.pid",
            error_log => "$temp_dir/error.log"
        }
    );
}

1;
