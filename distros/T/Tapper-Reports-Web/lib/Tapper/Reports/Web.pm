package Tapper::Reports::Web;
# git description: v5.0.14-4-g27494f9

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Frontend web application based on Catalyst
$Tapper::Reports::Web::VERSION = '5.0.15';
use 5.010;
use strict;
use warnings;

use Moose;
use Catalyst::Runtime;

extends 'Catalyst';
with 'Tapper::Reports::Web::Role::BehaviourModifications::Path';

use File::ShareDir ':ALL';
use Cwd;
use Tapper::Config;
use Log::Log4perl::Catalyst;

my $hr_subconfig;
my $s_log4perl_config;

BEGIN {

    $hr_subconfig = Tapper::Config->subconfig;

    open my $fh_log4perl_config, '<', $hr_subconfig->{files}{log4perl_webgui_cfg} or die "Unable to open log4perl configuration '$hr_subconfig->{files}{log4perl_webgui_cfg}': $!";
    $s_log4perl_config = do { local $/; <$fh_log4perl_config> };
    close $fh_log4perl_config or die "Unable to close log4perl configuration: $!";

    my ( $s_error_log_file ) = $s_log4perl_config =~ /^log4perl.appender.AppError.filename\s*=\s*(.+)$/m;

    use CGI::Carp qw( carpout );
    open( my $fh_log, '>>', $s_error_log_file ) or die ( "Unable to open log file while compiling: $!\n" );
    carpout($fh_log);

}

my $root_dir = eval { dist_dir("Tapper-Reports-Web") } || getcwd."/root";

# Configure the application
__PACKAGE__->config( name => 'Tapper::Reports::Web' );
__PACKAGE__->config->{tapper_config} = $hr_subconfig;
__PACKAGE__->log(Log::Log4perl::Catalyst->new( \$s_log4perl_config ));

# send all "die" and "warn" to Log4perl
$SIG{__DIE__} = sub {
    if($^S) {
        # We're in an eval {} and don't want log
        # this message but catch it later
        return;
    }
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    __PACKAGE__->log->error( @_ );
};
$SIG{__WARN__} = sub {
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    __PACKAGE__->log->warn( @_ );
};

use Catalyst::Engine;
use Catalyst::DispatchType::Regex;

# Configure plugins
__PACKAGE__->config(
    "Plugin::Static::Simple" => {
        dirs            => [ 'tapper/static' ],
        include_path    => [ $root_dir ],
    }
);

if ( __PACKAGE__->config->{tapper_config}{web}{use_authentication} ) {
    __PACKAGE__->config(
        "Plugin::Authentication" => {
            realms => {
                default => {
                    credential => {
                        class  => 'Authen::Simple',
                        authen => [{
                            class => 'PAM',
                            args  => {
                                service => 'login'
                            }
                        }]
                    }
                }
            }
        }
    );
}
__PACKAGE__->config( 'Controller::HTML::FormFu' => {
    constructor => {
        config_file_path => [ "$root_dir/forms", 'root/forms/' ],
    },
});

my @plugins = qw(
    Redirect
    ConfigLoader
    Static::Simple Session
    Session::State::Cookie
    Session::Store::File
);

if ( __PACKAGE__->config->{use_authentication} ) {
    push @plugins, "Authentication";
}

# Start the application
__PACKAGE__->setup(@plugins);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web - Tapper - Frontend web application based on Catalyst

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
