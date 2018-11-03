#!/usr/bin/perl

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(basename dirname);

BEGIN {
    unshift(@INC, dirname(abs_path($0)));
    unshift(@INC, dirname(abs_path($0)).'/../lib');
};

use Net::OpenStack::Client::Request qw(parse_endpoint @SUPPORTED_METHODS @METHODS_REQUIRE_OPTIONS);
use File::Path qw(make_path);
use Config::INI::Reader;
use Data::Dumper;
use Template;
use Readonly;
use typedjson;

my $debug = 1;

Readonly my $GEN_API_DIR => dirname(abs_path($0));
Readonly my $API_DIR => "$GEN_API_DIR/../lib/Net/OpenStack/Client/API";

Readonly my $SCRIPT_NAME => basename($0);


sub info {
    print "[INFO] @_\n"
}

sub error {
    print "[ERROR] @_\n"
}

sub debug
{
    print "[DEBUG] @_\n" if $debug;
}

sub make_file
{
    my ($fn, $text) = @_;
    open FH, "> $fn" || die ("Failed to open $fn: $!");
    print FH $text;
    close FH;
}


sub make_module
{
    my ($service, $version, $config) = @_;

    my $modname = "v$version";
    $modname =~ s/\./DOT/g;

    my $err_prefix = "service $service version $version";

    # ensure unique option names
    foreach my $method (sort keys %$config) {
        my @known;
        my $mcfg = $config->{$method};

        # get templates from endpoint / url
        my ($endpoint, $templates, $params) = parse_endpoint($mcfg->{url});
        $mcfg->{hrendpoint} = $endpoint;
        $mcfg->{templates} = $templates if @$templates;
        push(@known, @$templates);
        $mcfg->{parameters} = $params if @$params;
        foreach my $kn (@$params) {
            if (grep {$_ eq $kn} @known) {
                die "$err_prefix parameter name $kn is already known (@known)";
            } else {
                push(@known, $kn);
            }
        }

        if (!grep {$_ eq $mcfg->{method}} @SUPPORTED_METHODS) {
            die "$err_prefix method $method $mcfg->{method} is not supported";
        }

        # get options from JSON
        my $json = $mcfg->{json};

        if ((grep {$mcfg->{method} eq $_} @METHODS_REQUIRE_OPTIONS) && !$json) {
            die "$err_prefix data should contain JSON for options for method $method $mcfg->{method}";
        }
        $mcfg->{options} = process_json($json, $templates) if $json;
        foreach my $kn (sort keys %{$mcfg->{options}}) {
            if (grep {$_ eq $kn} @known) {
                die "$err_prefix options name $kn is already known @known";
            } else {
                push(@known, $kn);
            }
        }
    }

    my $vars = {
        script_name => $SCRIPT_NAME,
        service => $service,
        version => $version,
        modname => $modname,
        methods => $config,
        sdump => sub {
            # single line dumper
            my $d = Data::Dumper->new([@_]);
            $d->Indent(0);
            $d->Sortkeys(1);
            my $txt = $d->Dump;
            $txt =~ s/^\$VAR\d+\s*=\s*//;
            $txt =~ s/;$//;
            return $txt;
        },
    };

    my $tt = Template->new({
        INCLUDE_PATH => $GEN_API_DIR,
        INTERPOLATE  => 1,
    }) || die "$err_prefix $Template::ERROR\n";

    my $pod = '';
    $tt->process('pod.tt', $vars, \$pod)
        || die "$err_prefix API error ", $tt->error(), "\n";

    my $api = '';
    $tt->process('data.tt', $vars, \$api)
        || die "$err_prefix API error ", $tt->error(), "\n";

    debug("Generated API service $service version $version");

    my $servdir = "$API_DIR/$service";
    if (!-d $servdir ) {
        make_path $servdir;
    };

    make_file("$servdir/$modname.pm", $api);
    make_file("$servdir/$modname.pod", $pod);
}

sub walk
{
    my ($dir) = @_;

    debug("Walking $dir for services");
    my @services = map {basename($_)} grep {-d $_ } glob("$dir/*");
    foreach my $service (@services) {
        debug("Found service $service");
        my @versions = map {s/\.ini$//;basename($_)} grep {-f $_ } glob("$dir/$service/*.ini");
        foreach my $version (@versions) {
            debug("Found service $service version $version");
            my $config = Config::INI::Reader->read_file("$dir/$service/$version.ini" , 'utf8');
            make_module($service, $version, $config);
        }
    }
}

sub main
{
    die "No API dir $API_DIR found." if ! -d $API_DIR;
    walk($GEN_API_DIR);
}

main();
