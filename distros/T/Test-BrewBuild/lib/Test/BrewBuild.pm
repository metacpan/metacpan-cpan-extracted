package Test::BrewBuild;
use strict;
use warnings;

use Carp qw(croak);
use Cwd qw(getcwd);
use File::Copy;
use File::Copy::Recursive qw(dircopy);
use File::Find;
use File::Path qw(remove_tree);
use File::Temp;
use Getopt::Long qw(GetOptionsFromArray);
Getopt::Long::Configure ("no_ignore_case", "pass_through");
use Logging::Simple;
use Module::Load;
use Plugin::Simple default => 'Test::BrewBuild::Plugin::DefaultExec';
use Test::BrewBuild::BrewCommands;
use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Tester;

our $VERSION = '2.19';

my $log;
my $bcmd;

sub new {
    my ($class, %args) = @_;
    my $self = bless { }, $class;

    # see if we have config file data

    if ($self->config_file) {
        $self->_config;
    }

    # override the config file and populate the rest of the args

    for (keys %args){
        $self->{args}{$_} = $args{$_};
    }

    $log = $self->_create_log($args{debug});
    $log->_6("in new(), constructing " . __PACKAGE__ . " object");

    $bcmd = Test::BrewBuild::BrewCommands->new($log);

    $self->_set_plugin();

    $self->tempdir;
    $log->_7("using temp bblog dir: " . $self->tempdir);

    return $self;
}
sub options {
    my ($self, $args) = @_;
    my %opts;

    my @arg_directives = grep {$_ =~ /^-/} @$args;

    my $bad_opt = _validate_opts(\@arg_directives);

    GetOptionsFromArray(
        $args,
        "on=s@"         => \$opts{on},
        "n|new=s"       => \$opts{new},
        "r|remove"      => \$opts{remove},
        "R|revdep"      => \$opts{revdep},
        "plugin=s"      => \$opts{plugin},
        "a|args=s@"     => \$opts{args},
        "d|debug=i"     => \$opts{debug},
        "i|install=s@"  => \$opts{install},
        "N|notest"      => \$opts{notest},
        "S|save"        => \$opts{save_reports},
        "l|legacy"      => \$opts{legacy},
        "T|selftest"    => \$opts{selftest},
        "D|dispatch"    => \$opts{dispatch},
        "t|tester=s@"   => \$opts{testers},
        "X|nocache"     => \$opts{nocache},
        "s|setup"       => \$opts{setup},
        "h|help"        => \$opts{help},
    );

    $opts{error} = 1 if $bad_opt;

    return %opts;
}
sub config_file {
    shift;
    if (is_win()){
        return $ENV{BB_CONF} if $ENV{BB_CONF};
        return "$ENV{USERPROFILE}/brewbuild/brewbuild.conf";
    }
    else {
        return $ENV{BB_CONF} if $ENV{BB_CONF};
        return "$ENV{HOME}/brewbuild/brewbuild.conf";
    }
}
sub is_win {
    my $is_win = ($^O =~ /Win/) ? 1 : 0;
    return $is_win;
}
sub brew_info {
    my $self = shift;
    my $log = $log->child('brew_info');

    my $brew_info;

    if ($self->{args}{nocache}){
        # don't use cached info
        $brew_info = $bcmd->info;
    }
    else {
        $brew_info = $bcmd->info_cache;
    }

    $log->_6("brew info set to:\n$brew_info") if $brew_info;

    return $brew_info;
}
sub perls_available {
    my $self = shift;
    my $log = $log->child('perls_available');
    my @perls_available = $bcmd->available($self->legacy, $self->brew_info);
    $log->_6("perls available: " . join ', ', @perls_available);
    return @perls_available;
}
sub perls_installed {
    my $self = shift;
    my $log = $log->child('perls_installed');
    $log->_6("checking perls installed");
    return $bcmd->installed($self->legacy, $self->brew_info);
}
sub instance_install {
    my ($self, $install, $timeout) = @_;

    # timeout an install after...

    if (! $timeout){
        if ($self->{args}{timeout}){
            $timeout = $self->{args}{timeout};
        }
        else {
            $timeout = 600;
        }
    }

    my $log = $log->child('instance_install');

    my @perls_available = $self->perls_available;
    my @perls_installed = $self->perls_installed;
    my @new_installs;

    if (ref $install eq 'ARRAY'){
        for my $version (@$install){
            $version = "perl-$version" if ! $self->is_win && $version !~ /perl/;

            if ($self->is_win){
                if ($version !~ /_/){
                    $log->_7("MSWin: no bit suffix supplied");
                    if (! grep {$_ =~ /$version/} @perls_available){
                        $version .= '_64';
                        $log->_7("MSWin: default to available 64-bit $version");
                    }
                    else {
                        $version .= '_32';
                        $log->_7("MSWin: no 64-bit version... using $version");
                    }
                }
            }
            $version =~ s/_.*$// if ! $self->is_win;

            if (! grep { $version eq $_ } @perls_available){
                $log->_0("$version is not a valid perl version");
                next;
            }

            if (grep { $version eq $_ } @perls_installed){
                $log->_6("$version is already installed... skipping");
                next;
            }
            push @new_installs, $version;
        }
    }
     elsif ($install == -1) {
        $log->_5("installing all available perls");

        for my $perl (@perls_available){
            if (grep { $_ eq $perl } @perls_installed) {
                $log->_6( "$perl already installed... skipping" );
                next;
            }
            push @new_installs, $perl;
        }
    }
    elsif ($install) {
        $log->_5("looking to install $install perl instance(s)");

        my %avail = map {$_ => 1} @perls_available;

        while ($install > 0){
            last if ! keys %avail;

            my $candidate = (keys %avail)[rand keys %avail];
            delete $avail{$candidate};

            if (grep { $_ eq $candidate } @perls_installed) {
                $log->_6( "$candidate already installed... skipping" );
                next;
            }

            push @new_installs, $candidate;
            $install--;
        }
    }

    if (@new_installs){
        $log->_4("preparing to install..." . join ', ', @new_installs);

        my $install_cmd = $bcmd->install;

        for my $ver (@new_installs) {
            $log->_0( "installing $ver..." );
            $log->_5( "...using cmd: $install_cmd" );
            undef $@;
            eval {
                local $SIG{ALRM} = sub {
                    croak "$ver failed to install... skipping"
                };
                alarm $timeout;
                `$install_cmd $ver`;
                alarm 0;
            };
            if ($@){
                $log->_0($@);
                $log->_1("install of $ver failed: uninstalling the remnants..");
                $self->instance_remove($ver);
                next;
            }
        }
        $bcmd->info_cache(1) if ! $self->{args}{nocache};
    }
    else {
        $log->_5("using existing versions only, nothing to install");
    }
}
sub instance_remove {
    my ($self, $version) = @_;

    my $log = $log->child('instance_remove');

    my @perls_installed = $self->perls_installed;

    $log->_6("perls installed: " . join ', ', @perls_installed);

    my $remove_cmd = $bcmd->remove;

    $log->_4( "using '$remove_cmd' remove command" );

    if ($version){
        $log->_5("$version supplied, removing...");
        if ($self->is_win){
            `$remove_cmd $version 2`
        }
        else {
            `$remove_cmd $version 2>/dev/null`;
        }
        $bcmd->info_cache(1) if ! $self->{args}{nocache};
    }
    else {
        $log->_0("removing previous installs...");

        for my $installed_perl (@perls_installed){

            my $using = $bcmd->using($self->brew_info);

            if ($using eq $installed_perl) {
                $log->_5( "not removing version we're using: $using" );
                next;
            }

            $log->_5( "exec'ing $remove_cmd $installed_perl" );

            if ($bcmd->is_win) {
                `$remove_cmd $installed_perl 2>nul`;
            }
            else {
                `$remove_cmd $installed_perl 2>/dev/null`;
            }
            $bcmd->info_cache(1) if ! $self->{args}{nocache};
        }
    }

    $log->_4("removal of existing perl installs complete...\n");
}
sub revdep {
    my ($self, %args) = @_;

    delete $self->{args}{args};

    # these args aren't sent through to test()

    delete $args{revdep};
    delete $self->{args}{delete};
    delete $args{remove};
    delete $args{install};
    delete $args{new};

    $args{plugin} = 'Test::BrewBuild::Plugin::TestAgainst';

    my @revdeps = $self->revdeps;
    my @ret;

    my $rlist = "\nreverse dependencies: " . join ', ', @revdeps;
    $rlist .= "\n\n";
    push @ret, $rlist;

    for (@revdeps){
        $args{plugin_arg} = $_;
        my $bb = __PACKAGE__->new(%args);
        $bb->log()->file($self->log()->file());
        push @ret, $bb->test;
    }
    return \@ret;
}
sub test {
    my $self = shift;

    exit if $self->{args}{notest};

    my $log = $log->child('test');
    local $SIG{__WARN__} = sub {};
    $log->_6("warnings trapped locally");

    my $failed = 0;

    my $results = $self->_exec;

    $log->_7("\n*****\n$results\n*****");

    my @ver_results = $results =~ /
        [Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===
        .*?
        (?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))
        /gsx;

    $log->_5("got " . scalar @ver_results . " results");

    my (@pass, @fail);

    for my $result (@ver_results){
        my $ver;

        if ($result =~ /^([Pp]erl-\d\.\d+\.\d+(_\d{2})?)/){
            $ver = $1;
            $ver =~ s/[Pp]erl-//;
        }
        my $res;

        if ($result =~ /Successfully tested / && $result !~ /FAIL/){
            $log->_6("$ver PASSED...");
            $res = 'PASS';

            push @pass, "$ver :: $res\n";
            $self->_save_reports($ver, $res, $result);
        }
        else {
            $log->_6("$ver FAILED...");
            $res = 'FAIL';
            $failed = 1;

            push @fail, "$ver :: $res\n";
            $self->_save_reports($ver, $res, $result);
        }
    }

    $self->_copy_logs;

    $log->_5(__PACKAGE__ ." run finished\n");

    my $ret = "\n";
    $ret .= "$self->{args}{plugin_arg}\n" if $self->{args}{plugin_arg};
    $ret .= $_ for @pass;
    $ret .= $_ for @fail;
    $ret .= "\n\n";

    return $ret;
}
sub tempdir {
    my $self = shift;
    return $self->{tempdir} if $self->{tempdir};

    my $dir = File::Temp->newdir;
    my $dir_name = $dir->dirname;
    $self->{temp_handle} = $dir;
    $self->{tempdir} = $dir_name;
    return $self->{tempdir};
}
sub workdir {
    my $self = shift;
    return is_win()
        ? "$ENV{USERPROFILE}/brewbuild"
        : "$ENV{HOME}/brewbuild";
}
sub log {
    my $self = shift;
    $self->{log}->_6(ref($self) ." class/obj accessing the log object");
    $self->{log};
}
sub revdeps {
    my $self = shift;

    load 'MetaCPAN::Client';
    my $mcpan = MetaCPAN::Client->new;

    my $log = $log->child('revdeps');
    $log->_6('running --revdep');

    my $mod;

    find({
            wanted => sub {
                return if $mod;

                if (-f && $_ =~ /\.pm$/){

                    $log->_6("processing module '$_'");

                    s|lib/||;
                    s|/|-|g;
                    s|\.pm||;

                    $log->_6("module file converted to '$_'");

                    my $dist;

                    eval {
                        $dist = $mcpan->distribution($_);
                    };
                    $mod = $_ if ref $dist;

                }
            },
            no_chdir => 1,
        },
        'lib/'
    );

    $log->_7("using '$mod' as the project we're working on");

    my @revdeps = $self->_get_revdeps($mod);
    return @revdeps;
}
sub legacy {
    my ($self, $legacy) = @_;
    if (! defined $legacy && defined $self->{args}{legacy}){
        return $self->{args}{legacy};

    }
    $self->{args}{legacy} = defined $legacy ? $legacy : 0;
    return $self->{args}{legacy};
}
sub setup {
    print "\n";
    my @setup = <DATA>;
    print $_ for @setup;
    exit;
}
sub help {
     print <<EOF;

Usage: brewbuild [OPTIONS]

Local usage options:

-o | --on       Perl version number to run against (can be supplied multiple times). Can not be used on Windows
-R | --revdep   Run tests, install, then run tests on all CPAN reverse dependency modules
-n | --new      How many random versions of perl to install (-1 to install all)
-r | --remove   Remove all installed perls (less the current one)
-i | --install  Number portion of an available perl version according to "*brew available". Multiple versions can be sent in at once
-S | --save     By default, we save only FAIL logs. This will also save the PASS logs
-N | --notest   Do not run tests. Allows you to --remove and --install without testing
-X | --nocache  By default, we cache the results of 'perlbrew available'. Disable with this flag.

Network dispatching options:

-D | --dispatch Dispatch a basic run to remote testers
-t | --tester   Testers to dispatch to. Can be supplied multiple times. Format: "host[:port]"

Help options:

-s | --setup    Display test platform setup instructions
-h | --help     Print this help message

Special options:

-p | --plugin   Module name of the exec command plugin to use
-a | --args     List of args to pass into the plugin (one arg per loop)
-l | --legacy   Operate on perls < 5.8.9. The default plugins won't work with this flag set if a lower version is installed
-T | --selftest Testing only: prevent recursive testing on Test::BrewBuild
-d | --debug    0-7, sets logging verbosity, default is 0

EOF
return 1;
}
sub _config {
    # slurp in config file elements

    my $self = shift;

     my $conf_file = $self->config_file;

    if (-f $conf_file){
        my $conf = Config::Tiny->read($conf_file)->{brewbuild};
        for (keys %$conf){
            $self->{args}{$_} = $conf->{$_};
        }
    }
}
sub _attach_build_log {
    # attach the cpanm logs to the PASS/FAIL logs

    my ($self, $bblog) = @_;

    my $bbfile;
    {
        local $/ = undef;
        open my $bblog_fh, '<', $bblog or croak $!;
        $bbfile = <$bblog_fh>;
        close $bblog_fh;
    }

    if ($bbfile =~ m|failed.*?See\s+(.*?)\s+for details|){
        my $build_log = $1;
        open my $bblog_wfh, '>>', $bblog or croak $!;
        print $bblog_wfh "\n\nCPANM BUILD LOG\n";
        print $bblog_wfh "===============\n";

        open my $build_log_fh, '<', $build_log or croak $!;

        while (<$build_log_fh>){
            print $bblog_wfh $_;
        }
        close $bblog_wfh;
    }
}
sub _copy_logs {
    # copy the log files out of the temp dir

    my $self = shift;
    dircopy $self->{tempdir}, "bblog" if $self->{tempdir};
    unlink 'bblog/stderr.bblog' if -e 'bblog/stderr.bblog';
}
sub _create_log {
    # set up the log object

    my ($self, $level) = @_;

    $self->{log} = Logging::Simple->new(
        name  => 'BrewBuild',
        level => defined $level ? $level : 0,
    );

    $self->{log}->_7("in _create_log()");

    if ($self->{log}->level < 6){
        $self->{log}->display(0);
        $self->{log}->custom_display("-");
        $self->{log}->_5("set log level to " . defined $level ? $level : 0);
    }

    return $self->{log};
}
sub _exec {
    # perform the actual *brew build commands (called by test())

    my $self = shift;

    my $log = $log->child('exec');

    if ($self->{args}{plugin_arg}) {
        $log->_5( "" .
            "fetching instructions from the plugin with arg " .
            $self->{args}{plugin_arg}
        );
    }

    my @exec_cmd = $self->{exec_plugin}->(
        __PACKAGE__,
        $self->log,
        $self->{args}{plugin_arg}
    );

    chomp @exec_cmd;

    $log->_6("instructions to be executed:\n" . join "\n", @exec_cmd);

    my $brew = $bcmd->brew;

    if ($self->{args}{on}){
        my $vers = join ',', @{ $self->{args}{on} };
        $log->_5("versions to run on: $vers");

        my $wfh = File::Temp->new(UNLINK => 1);
        my $fname = $wfh->filename;

        $log->_6("created temp file for storing output: $fname");

        open $wfh, '>', $fname or croak $!;
        for (@exec_cmd){
            s/\n//g;
        }
        my $cmd = join ' && ', @exec_cmd;
        $cmd = "system(\"$cmd\")";
        print $wfh $cmd;
        close $wfh;

        $self->_dzil_shim($fname);
        $log->_5("exec'ing: $brew exec --with $vers " . join ', ', @exec_cmd);

        my $ret
          = `$brew exec --with $vers perl $fname 2>$self->{tempdir}/stderr.bblog`;

        $self->_dzil_unshim if $self->{is_dzil};

        return $ret;
    }
    else {

        if ($bcmd->is_win){

            # all of this because berrybrew doesn't get the path right
            # when calling ``berrybrew exec perl ...''

            my %res_hash;

            $self->_dzil_shim;

            for (@exec_cmd){
                $log->_5("exec'ing: $brew exec:\n". join ', ', @exec_cmd);
                my $res = `$brew exec $_`;

                my @results = $res =~ /
                    [Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===
                    .*?
                    (?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))
                    /gsx;

                for (@results){
                    if ($_ =~ /
                        ([Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+=+?)
                        (\s+.*?)
                        (?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))
                        /gsx)
                    {
                        push @{ $res_hash{$1} }, $2;
                    }
                }
            }

            $self->_dzil_unshim if $self->{is_dzil};

            my $result;

            for (keys %res_hash){
                $result .= $_ . join '', @{ $res_hash{$_} };
            }

            return $result;
        }
        else {
            my $wfh = File::Temp->new(UNLINK => 1);
            my $fname = $wfh->filename;

            $log->_6("created temp file for storing output: $fname");

            open $wfh, '>', $fname or croak $!;
            for (@exec_cmd){
                s/\n//g;
            }
            my $cmd = join ' && ', @exec_cmd;
            $cmd = "system(\"$cmd\")";
            print $wfh $cmd;
            close $wfh;

            $self->_dzil_shim($fname);

            my $ret = `$brew exec perl $fname 2>$self->{tempdir}/stderr.bblog`;

            $self->_dzil_unshim if $self->{is_dzil};

            return $ret;
        }
    }
}
sub _dzil_shim {
    # shim for working on Dist::Zilla modules

    my ($self, $cmd_file) = @_;

    # return early if possible

    return if -e 'Build.PL' || -e 'Makefile.PL';
    return if ! -e 'dist.ini';

    my $log = $log->child('_dzil_shim');
    $log->_5("dzil dist... loading the shim");

    my $path_sep = $self->is_win ? ';' : ':';

    if (! grep {-x "$_/dzil"} split /$path_sep/, $ENV{PATH} ){
        $log->fatal(
            "this appears to be a Dist::Zilla module, but the dzil binary " .
            "can't be found\n"
        );
    }

    $self->{is_dzil} = 1;

    open my $fh, '<', 'dist.ini' or croak $!;

    my ($dist, $version);

    while (<$fh>){
        if (/^name\s+=\s+(.*)$/){
            $dist = $1;
        }
        if (/^version\s+=\s+(.*)$/){
            $version = $1;
        }
        last if $dist && $version;
    }

    $log->_7("running dzil commands: 'dzil authordeps --missing | cpanm', " .
             "'dzil build'"
     );

    `dzil authordeps --missing | cpanm`;
    `dzil clean`;
    `dzil build`;

    my $dir = "$dist-$version";
    copy $cmd_file, $dir if defined $cmd_file;
    chdir $dir;
    $log->_7("entered $dir directory");
}
sub _dzil_unshim {
    # unshim after doing dzil work

    my $log = $log->child('_dzil_unshim');
    $log->_5("removing dzil shim");

    my $self = shift;
    $self->{is_dzil} = 0;
    chdir '..';
    $log->_7("changed to '..' dir");
}
sub _get_revdeps {
    my ($self, $module) = @_;

    load 'MetaCPAN::Client';

    my $mcpan = MetaCPAN::Client->new;

    my $rs = $mcpan->reverse_dependencies($module);

    my @revdeps;

    while (my $release = $rs->next){
        push @revdeps, $release->distribution;
    }

    @revdeps = grep {$_ ne 'Test-BrewBuild'} @revdeps;

    for (@revdeps) {
        s/-/::/g;
    }

    return @revdeps;
}
sub _process_stderr {
    # compile data written to STDERR

    my $self = shift;
    
    my $errlog = "$self->{tempdir}/stderr.bblog";

    if (-e $errlog){
        open my $errlog_fh, '<', $errlog or croak $!;
    
        my $error_contents;
        {
            local $/ = undef;
            $error_contents = <$errlog_fh>;
        }
        close $errlog_fh;

        my @errors = $error_contents =~ /
                cpanm\s+\(App::cpanminus\)
                .*?
                (?=(?:cpanm\s+\(App::cpanminus\)|$))
            /xgs;

        my %error_map;

        for (@errors){
            if (/cpanm.*?perl\s(5\.\d+)\s/){
                $error_map{$1} = $_;
            }
        }
        
        if (! keys %error_map){
            $error_map{0} = $error_contents;
        }
        return %error_map;
    }
}
sub _save_reports {
    # save FAIL and optionally PASS report logs

    my ($self, $ver, $status, $result) = @_;

    if ($status ne 'FAIL' && ! $self->{args}{save_reports}){
        return;
    }

    my $tested_mod = $self->{args}{plugin_arg};

    if (defined $tested_mod){
        $tested_mod =~ s/::/-/g;
        my $report = "$self->{tempdir}/$tested_mod-$ver-$status.bblog";
        open my $wfh, '>', $report, or croak $!;

        print $wfh $result;

        if (! $self->is_win){
            my %errors = $self->_process_stderr;

            if (defined $errors{0}){
                print $wfh "\nCPANM ERROR LOG\n";
                print $wfh "===============\n";
                print $wfh $errors{0};
            }
            else {
                for (keys %errors){
                    if (version->parse($_) == version->parse($ver)){
                        print $wfh "\nCPANM ERROR LOG\n";
                        print $wfh "===============\n";
                        print $wfh $errors{$_};
                    }
                }
            }
        }
        close $wfh;
        $self->_attach_build_log($report);
    }
    else {
        my $report = "$self->{tempdir}/$ver-$status.bblog";
        open my $wfh, '>', $report or croak $!;
        print $wfh $result;

        if (! $self->is_win){
            my %errors = $self->_process_stderr;
            for (keys %errors){
                if (version->parse($_) == version->parse($ver)){
                    print $wfh "\nCPANM ERROR LOG\n";
                    print $wfh "===============\n";
                    print $wfh $errors{$_};
                }
            }
        }
        close $wfh;
        $self->_attach_build_log($report) if ! $self->is_win;
    }
}
sub _set_plugin {
    # import the exec plugin

    my $self = shift;
    my $log = $log->child('_set_plugin');
    my $plugin = $self->{args}{plugin}
        ? $self->{args}{plugin}
        : $ENV{TBB_PLUGIN};

    $log->_5("plugin param set to: " . defined $plugin ? $plugin : 'default');

    $plugin = $self->plugins($plugin, can => ['brewbuild_exec']);

    my $exec_plugin_sub = $plugin .'::brewbuild_exec';
    $self->{exec_plugin} = \&$exec_plugin_sub;

    $log->_4("successfully loaded $plugin plugin");
}
sub _validate_opts {
    # validate command line arguments

    my $args = shift;

    my @valid_args = qw(
        on o new n remove r revdep R plugin p args a debug d install i help h
        N notest setup s legacy l selftest T t testers S save D dispatch X
        nocache
    );

    my $bad_opt = 0;
    my $i;
    if (@$args) {
        my @params = grep {++$i % 2 != 0} @$args;
        for my $arg (@params) {
            $arg =~ s/^-{1,2}//g;
            if (!grep { $arg eq $_ } @valid_args) {
                $bad_opt = 1;
                last;
            }
        }
    }
    return $bad_opt;
}

1;

=head1 NAME

Test::BrewBuild - Perl/Berry brew unit testing automation, with remote tester
dispatching capabilities.

=head1 DESCRIPTION

This module is the backend for the C<brewbuild> script that is accompanied by
this module.

For end-user use, see
L<brewbuild|https://metacpan.org/pod/distribution/Test-BrewBuild/bin/brewbuild>.
You can also read the documentation for the network dispatcher
L<bbdispatch|https://metacpan.org/pod/distribution/Test-BrewBuild/bin/bbdispatch>,
the remote test listener
L<bbtester|https://metacpan.org/pod/distribution/Test-BrewBuild/bin/bbtester>,
or browse through the L<Test::BrewBuild::Tutorial> for network testing.

This module provides you the ability to perform your unit tests across all of
your L<Perlbrew|http://perlbrew.pl> (Unix) or L<Berrybrew|https://github.com/stevieb9/berrybrew>
(Windows) Perl instances.

For Windows, you'll need to install B<L<Berrybrew|https://github.com/stevieb9/berrybrew>>, 
and for Unix, you'll need B<L<Perlbrew|http://perlbrew.pl>>.

It allows you to remove and reinstall on each test run, install random versions
of perl, or install specific versions.

All unit tests are run against all installed instances, unless specified
otherwise.

=head1 SYNOPSIS

    use Test::BrewBuild;

    my $bb = Test::BrewBuild->new;

    my @perls_available = $bb->perls_available;
    my @perls_installed = $bb->perls_installed;

    # remove all currently installed instances of perl, less the one you're
    # using

    $bb->instance_remove;

    # install four new random versions of perl

    $bb->instance_install(4);

    # install two specific versions

    $bb->instance_install(['5.10.1', '5.20.3']);

    # install all instances

    $bb->instance_install(-1);

    # find and test against all the current module's reverse CPAN dependencies

    $bb->revdep;

    # run the unit tests of the current module only

    $bb->test;

=head1 METHODS



=head2 new(%args)

Returns a new C<Test::BrewBuild> object. See the documentation for the
L<brewbuild|https://metacpan.org/pod/distribution/Test-BrewBuild/bin/brewbuild>
script to understand what the arguments are and do.

Many of the options can be saved in a configuration file if you want to set them
permanently, or override defaults. Options passed into the various methods will
override those in the configuration file.
See L<config file documentation|https://metacpan.org/pod/distribution/Test-BrewBuild/lib/Test/BrewBuild/brewbuild.conf.pod>.

=head2 brew_info

Returns in string form the full output of C<*brew available>.

=head2 perls_available

Returns an array containing all perls available, whether already installed or
not.

=head2 perls_installed

Returns an array of the names of all perls currently installed under your 
C<*brew> setup.

=head2 instance_install

If an integer is sent in, we'll install that many random versions of perl. If
the integer is C<-1>, we'll install all available versions. You can also send in
an array reference, where each element is a version of perl, and we'll install
those instead.

You can send a second parameter, an integer for a time out. On each install,
we'll bail if it takes longer than this time. Default is 300 seconds. If you're
on a fast machine, you should probably lower this value.

On Windows, where you want to install specific perls, we'll default to
installing 64-bit versions only, if a 64 bit perl is available for the version
desired and you haven't added the C<_64/_32> suffix per C<berrybrew available>.

Simply add the C<_32> suffix if you want to install it specifically. Note that
if you're dispatching to Unix and Windows servers, the Unix systems will remove
this invalid portion of the version prior to processing further.

=head2 instance_remove

Uninstalls all currently installed perls, less the one you are currently
C<switch>ed or C<use>d to.

=head2 test

Processes and returns the test results as a string scalar of the distribution
located in the current working directory.

=head2 revdeps

Returns a list of the reverse dependencies (according to CPAN) that the module
you're working on in the current working directory have.

=head2 revdep

Loops over all of the current module's reverse dependencies, and executes
C<test()> on each one at a time. This helps you confirm whether your new build
won't break your downstream users' modules.

=head2 legacy

By default, we don't install perl versions less than v5.8.9. Pass in a true
value to override this default.

=head2 options(\%args)

Takes a hash reference of the command-line argument list, and converts it into
a hash of the translated C<Test::BrewBuild> parameters along with their values.

Returns the converted hash for passing back into C<new()>.

If an invalid argument is included, we'll set C<$args{error} = 1;>. It is up to
the caller to look for and process an error handling routine.

=head2 config_file

Returns a string that contains the path/filename of the configuration file, if
available.

=head2 plugin('Module::Name')

Fetches and installs a custom plugin which contains the code that
C<perlbrew/berrybrew exec> will execute. If not used or the module specified
can't be located (or it contains errors), we fall back to the default bundled
L<Test::BrewBuild::Plugin::DefaultExec> (which is the canonical example for
writing new plugins).

Note that you can send in a custom plugin C<*.pm> filename to plugin as opposed
to a module name if the module isn't installed. If the file isn't in the
current working directory, send in the relative or full path.

=head2 is_win

Helper method, returns true if the current OS is Windows, false if not.

=head2 log

Returns an instance of the packages log object for creating child log objects.

=head2 tempdir

Sets up the object with a temporary directory used for test logs, that will be 
removed after the run.

=head2 workdir

Returns the brewbuild working directory.

=head2 setup

Prints out detailed information on setting up a testing environment, on Windows
and Unix.

=head2 help

Displays the C<brewbuild> command line usage information.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 SEE ALSO

Berrybrew for Windows:

L<https://github.com/stevieb9/berrybrew>

Perlbrew for Unixes:

L<http://perlbrew.pl>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;

__DATA__

Test::BrewBuild test platform configuration guide

*** Unix ***

Install perlbrew and related requirements:
    cpanm App::perlbrew
    perlbrew install-patchperl
    perlbrew install-cpanm

Install and switch to your base perl instance, and install C<Test::BrewBuild>:
    perlbrew install 5.22.1
    perlbrew switch 5.22.1
    cpanm Test::BrewBuild

*** Windows ***

Note that the key here is that your %PATH% must be free and clear of anything
Perl. That means that if you're using an existing box with Strawberry or
ActiveState installed, you *must* remove all traces of them in the PATH
environment variable for ``brewbuild'' to work correctly.

Easiest way to guarantee a working environment is using a clean-slate Windows
server with nothing on it. For a Windows test platform, I mainly used an
Amazon AWS t2.small server.

Download/install git for Windows:
    https://git-scm.com/download/win)

Create a repository directory, and enter it:
    mkdir c:\repos
    cd c:\repos

Clone and configure berrybrew
    git clone https://github.com/stevieb9/berrybrew
    cd berrybrew
    bin\berrybrew.exe config (type 'y' when asked to install in PATH)

Close the current CMD window and open a new one to update env vars

Check available perls, and install one that'll become your core base install
    berrybrew available
    berrybrew install 5.22.1_64
    berrybrew switch 5.22.1_64
    close CMD window, and open new one

Make sure it took
    perl -v

Install Test::BrewBuild
    cpanm Test::BrewBuild

