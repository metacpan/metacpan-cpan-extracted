#!/usr/bin/env perl

use strict;
use warnings;

use Readonly;
use Data::Dumper;
use Log::Log4perl qw(get_logger :levels);
use JSON::XS;

BEGIN {
    unshift(@INC, 'lib');
};

use Net::FreeIPA;
use Net::FreeIPA::API;
use Template;

use Cwd qw(abs_path);
use File::Basename qw(dirname basename);


Readonly my $GEN_API_DIR => dirname(abs_path($0));

Readonly my $SCRIPT_NAME => basename($0);

Readonly my $MODULE_NAME => 'Data';

=head1 SYNOPSIS

Generate the API/Data.pm and Data.pod from JSON API

    GEN_API_DEBUG=1 GEN_API_HOSTNAME=host.example.com ./gen_api/gen_api.pl

=head2 Functions

=over

=item get_api

Get the API from the JSON API.

Args/opts are passed to C<<Net::FreeIPA->new>>
(so at least the hostname should be set).

Return version and commands hashref.

=cut

sub get_api
{

    my ($hostname, %opts) = @_;
    $opts{log} = mklogger();
    my $f = Net::FreeIPA->new($hostname, %opts);
    die("Failed to initialise the rest client") if ! $f->{rc};

    # most recent
    delete $f->{api_version};

    my $version = $f->get_api_version() || die("Failed to get api_version ".Dumper($f));
    $f->set_api_version($version);

    my $commands = $f->get_api_commands() || die("Failed to get commands metdata ".Dumper($f));

    return $version, $commands;
}


sub mklogger
{
    my $logger = get_logger("Net::FreeIPA");

    if ($ENV{GEN_API_DEBUG}) {
        $logger->level($DEBUG);
    } else {
        $logger->level($INFO);
    };
    my $appender = Log::Log4perl::Appender->new(
        "Log::Log4perl::Appender::Screen",
        mode     => "append",
        );
    my $layout =
        Log::Log4perl::Layout::PatternLayout->new(
            "%d [%p] %F{1}:%L %M - %m%n");
    $appender->layout($layout);
    $logger->add_appender($appender);

    return $logger;
}


my $f = Net::FreeIPA->new();


sub make_module
{
    my ($text, $pod) = @_;

    my $fn = "$GEN_API_DIR/../lib/Net/FreeIPA/API/Data.";
    $fn .= $pod ? 'pod' : 'pm';

    open FH, "> $fn" || die ("Failed to open $fn: $!");
    print FH $text;
    close FH;

    print "Created $fn\n"
}


sub main
{
    my ($version, $commands) = get_api($ENV{GEN_API_HOSTNAME}, debugapi => ($ENV{GEN_API_DEBUG} ? 1 : 0));

    my $tt = Template->new({
        INCLUDE_PATH => $GEN_API_DIR,
        INTERPOLATE  => 1,
    }) || die "$Template::ERROR\n";

    my $vars = {
        prefix => $Net::FreeIPA::API::API_METHOD_PREFIX,
        version => $version,
        commands => $commands,
        module_name => $MODULE_NAME,
        script_name => $SCRIPT_NAME,
        encode_json => sub { return encode_json(Net::FreeIPA::API::Magic::cache(shift));},
        check_hash => sub {
            my $array = shift;
            my @newarray;
            foreach my $el (@$array) {
                if (ref($el) eq '') {
                    my $oldel = $el;
                    $oldel =~ s/[*+?]$//;
                    $el = { %Net::FreeIPA::API::Magic::CACHE_TAKES_DEFAULT };
                    $el->{name} = $oldel;
                    $el->{doc} = 'unknown';
                };
                push(@newarray, $el);
            };
            return \@newarray;
        }
    };

    # flush the cache, otherwise the encode_json TT command uses the cache data (leading to
    # missing commands and interpreted data (so no identical JSON re-encoding))
    Net::FreeIPA::API::Magic::flush_cache();

    # pod first, the data.tt uses encode_json which modifies the commands hashref
    my $pod = '';
    $tt->process('pod.tt', $vars, \$pod)
        || die "POD error ", $tt->error(), "\n";

    make_module($pod, 1);

    my $api = '';
    $tt->process('data.tt', $vars, \$api)
        || die "API error ", $tt->error(), "\n";

    make_module($api);

}


main();

=pod

=back

=cut
