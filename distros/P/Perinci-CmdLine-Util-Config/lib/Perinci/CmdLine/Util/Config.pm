package Perinci::CmdLine::Util::Config;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-21'; # DATE
our $DIST = 'Perinci-CmdLine-Util-Config'; # DIST
our $VERSION = '1.724'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = (
    'get_default_config_dirs',
    'read_config',
    'get_args_from_config',
);

our %SPEC;

# from PERLANCAR::File::HomeDir 0.03, with minor modification
sub _get_my_home_dir {
    if ($^O eq 'MSWin32') {
        # File::HomeDir always uses exists($ENV{x}) first, does it want to avoid
        # accidentally creating env vars?
        return $ENV{HOME} if $ENV{HOME};
        return $ENV{USERPROFILE} if $ENV{USERPROFILE};
        return join($ENV{HOMEDRIVE}, "\\", $ENV{HOMEPATH})
            if $ENV{HOMEDRIVE} && $ENV{HOMEPATH};
    } else {
        return $ENV{HOME} if $ENV{HOME};
        my @pw;
        eval { @pw = getpwuid($>) };
        return $pw[7] if @pw;
    }
    die "Can't get home directory";
}

$SPEC{get_default_config_dirs} = {
    v => 1.1,
    args => {},
};
sub get_default_config_dirs {
    my @dirs;
    #local $PERLANCAR::File::HomeDir::DIE_ON_FAILURE = 1;
    my $home = _get_my_home_dir();
    if ($^O eq 'MSWin32') {
        push @dirs, $home;
    } else {
        push @dirs, "$home/.config", $home, "/etc";
    }
    \@dirs;
}

$SPEC{read_config} = {
    v => 1.1,
    args => {
        config_paths    => {},
        config_filename => {},
        config_dirs     => {},
        program_name    => {},
        # TODO: hook_file
        hook_section    => {},
        # TODO: hook_param?
    },
};
sub read_config {
    require Config::IOD::Reader;

    my %args = @_;

    my $config_dirs = $args{config_dirs} // get_default_config_dirs();

    my $paths;

    my @filenames;
    my %section_config_filename_map;
    if (my $names = $args{config_filename}) {
        for my $name (ref($names) eq 'ARRAY' ? @$names : ($names)) {
            if (ref($name) eq 'HASH') {
                $section_config_filename_map{$name->{filename}} = $name->{section};
                push @filenames, $name->{filename};
            } else {
                $section_config_filename_map{$name} = 'GLOBAL';
                push @filenames, $name;
            }
        }
    }
    unless (@filenames) {
        @filenames = (($args{program_name} // "prog") . ".conf");
    }

    if ($args{config_paths}) {
        $paths = $args{config_paths};
    } else {
        for my $dir (@$config_dirs) {
            for my $name (@filenames) {
                my $path = "$dir/" . $name;
                push @$paths, $path if -e $path;
            }
        }
    }

    my $reader = Config::IOD::Reader->new;
    my %res;
    my @read;
    my %section_read_order;
  FILE:
    for my $i (0..$#{$paths}) {
        my $path           = $paths->[$i];
        my $filename = $path; $filename =~ s!.*[/\\]!!;
        my $wanted_section = $section_config_filename_map{$filename};
        log_trace "[pericmd] Reading config file '%s' ...", $path;
        my $j = 0;
        $section_read_order{GLOBAL} = [$i, $j++];
        my @file_sections = ("GLOBAL");
        my $hoh = $reader->read_file(
            $path,
            sub {
                my %args = @_;
                return unless $args{event} eq 'section';
                my $section = $args{section};
                push @file_sections, $section
                    unless grep {$section eq $_} @file_sections;
                $section_read_order{$section} = [$i, $j++];
            },
        );
        push @read, $path;
      SECTION:
        for my $section (@file_sections) {
            $res{$section} //= {};
            my $hash = $hoh->{$section};

            my $s = $section; $s =~ s/\s*\S*=.*\z//; # strip key=value pairs
            $s = 'GLOBAL' if $s eq '';

            if ($args{hook_section}) {
                my $res = $args{hook_section}->($section, $hash);
                if ($res->[0] == 204) {
                    log_trace "[pericmd] Skipped config section '$section' ".
                        "in file '$path': hook_section returns 204";
                    next SECTION;
                } elsif ($res->[0] >= 400 && $res->[0] <= 599) {
                    return [$res->[0], "Error when reading config file '$path'".
                                ": $res->[1]"];
                }
            }

            next unless !defined($wanted_section) || $s eq $wanted_section;

            for (keys %$hash) {
                $res{$section}{$_} = $hash->{$_};
            }
        }
    }
    [200, "OK", \%res, {
        'func.read_files' => \@read,
        'func.section_read_order' => \%section_read_order,
    }];
}

$SPEC{get_args_from_config} = {
    v => 1.1,
    description => <<'_',

`config` is a HoH (hashes of hashrefs) produced by reading an INI (IOD)
configuration file using modules like <pm:Config::IOD::Reader>.

Hashref argument `args` will be set by parameters in `config`, while `plugins`
will be set by parameters in `[plugin=...]` sections in `config`. For example,
with this configuration:

    arg1=val1
    arg2=val2
    -special_arg1=val3
    -special_arg2=val4

    [plugin=DumpArgs]
    -event=before_validation

    [plugin=Foo]
    arg1=val1

`args` will become:

    {
      arg1=>"val1",
      arg2=>"val2",
      -special_arg1=>"val3",
      -special_arg2=>"val4",
    }

and `plugins` will become:

    [
      'DumpArgs@before_validation' => {},
      Foo => {arg1=>val},
    ]

_
    args => {
        r => {},
        config => {},
        args => {schema=>'hash'},
        plugins => {schema=>'array'},
        subcommand_name => {},
        config_profile => {},
        common_opts => {},
        meta => {},
        meta_is_normalized => {},
    },
};
sub get_args_from_config {
    my %fargs = @_;

    my $r       = $fargs{r};
    my $conf    = $fargs{config};
    my $progn   = $fargs{program_name};
    my $scn     = $fargs{subcommand_name} // '';
    my $profile = $fargs{config_profile};
    my $args    = $fargs{args} // {};
    my $plugins = $fargs{plugins} // [];
    my $copts   = $fargs{common_opts};
    my $meta    = $fargs{meta};
    my $found;

    unless ($fargs{meta_is_normalized}) {
        require Perinci::Sub::Normalize;
        $meta = Perinci::Sub::Normalize::normalize_function_metadata($meta);
    }

    my $csro = $r->{_config_section_read_order} // {};
    my @sections = sort {
        # sort according to the order the section is seen in the file
        my $csro_a = $csro->{$a} // [0,0];
        my $csro_b = $csro->{$b} // [0,0];
        $csro_a->[0] <=> $csro_b->[0] ||
            $csro_a->[1] <=> $csro_b->[1] ||
            $a cmp $b
        } keys %$conf;

    my %seen_profiles; # for debugging message
    for my $section0 (@sections) {
        my %keyvals;
        my $sect_name;
        for my $word (split /\s+/, $section0) {
            if ($word =~ /(.*?)=(.*)/) {
                $keyvals{$1} = $2;
            } else {
                $sect_name //= $word;
            }
        }
        $seen_profiles{$keyvals{profile}}++ if defined $keyvals{profile};

        my $sect_scn     = $keyvals{subcommand} // '';
        my $sect_profile = $keyvals{profile};
        my $sect_plugin  = $keyvals{plugin};

        # if there is a subcommand name, use section with no subcommand=... or
        # the matching subcommand
        if (length $scn) {
            if (length($sect_scn) && $sect_scn ne $scn) {
                log_trace(
                    "[pericmd] Skipped config section '%s' (%s)",
                    $section0, "subcommand does not match '$scn'",
                );
                next;
            }
        } else {
            if (length $sect_scn) {
                log_trace(
                    "[pericmd] Skipped config section '%s' (%s)",
                    $section0, "only for a certain subcommand",
                );
                next;
            }
        }

        # if user chooses a profile, only use section with no profile=... or the
        # matching profile
        if (defined $profile) {
            if (defined($sect_profile) && $sect_profile ne $profile) {
                log_trace(
                    "[pericmd] Skipped config section '%s' (%s)",
                    $section0, "profile does not match '$profile'",
                );
                next;
            }
            $found = 1 if defined($sect_profile) && $sect_profile eq $profile;
        } else {
            if (defined($sect_profile)) {
                log_trace(
                    "[pericmd] Skipped config section '%s' (%s)",
                    $section0, "only for a certain profile",
                );
                next;
            }
        }

        # only use section marked with program=... if the program name matches
        if (defined($progn) && defined($keyvals{program})) {
            if ($progn ne $keyvals{program}) {
                log_trace(
                    "[pericmd] Skipped config section '%s' (%s)",
                    $section0, "program does not match '$progn'",
                );
                next;
            }
        }

        # if user specifies env=... then apply filtering by ENV variable
        if (defined(my $env = $keyvals{env})) {
            my ($var, $val);
            if (($var, $val) = $env =~ /\A(\w+)=(.*)\z/) {
                if (($ENV{$var} // '') ne $val) {
                    log_trace(
                        "[pericmd] Skipped config section '%s' (%s)",
                        $section0, "env $var has non-matching value '".
                            ($ENV{$var} // '')."'",
                    );
                    next;
                }
            } elsif (($var, $val) = $env =~ /\A(\w+)!=(.*)\z/) {
                if (($ENV{$var} // '') eq $val) {
                    log_trace(
                        "[pericmd] Skipped config section '%s' (%s)",
                        $section0, "env $var has that value",
                    );
                    next;
                }
            } elsif (($var, $val) = $env =~ /\A(\w+)\*=(.*)\z/) {
                if (index(($ENV{$var} // ''), $val) < 0) {
                    log_trace(
                        "[pericmd] Skipped config section '%s' (%s)",
                        $section0, "env $var has value '".
                            ($ENV{$var} // '')."' which does not contain the ".
                                "requested string"
                    );
                    next;
                }
            } else {
                if (!$ENV{$env}) {
                    log_trace(
                        "[pericmd] Skipped config section '%s' (%s)",
                        $section0, "env $env is not set/true",
                    );
                    next;
                }
            }
        }

        log_trace("[pericmd] Reading config section '%s'", $section0);

        if (defined $sect_plugin) {
            # TODO: check against metadata in plugin
            my $event;
            my $prio;
            my $plugin_args = {};
            for my $k (keys %{ $conf->{$section0} }) {
                my $v = $conf->{$section0}{$k};
                if    ($k eq '-event') { $event = $v }
                elsif ($k eq '-prio')  { $prio  = $v }
                else { $plugin_args->{$k} = $v }
            }
            push @$plugins, $sect_plugin .
                (defined $event || defined $prio ?
                 '@'.($event // '') . (defined $prio ? "\@$prio" : "") : '');
            push @$plugins, $plugin_args;
        } else {
            my $as = $meta->{args} // {};
            for my $k (keys %{ $conf->{$section0} }) {
                my $v = $conf->{$section0}{$k};
                if ($copts->{$k} && $copts->{$k}{is_settable_via_config}) {
                    my $sch = $copts->{$k}{schema};
                    if ($sch) {
                        require Data::Sah::Resolve;
                        my $rsch = Data::Sah::Resolve::resolve_schema($sch);
                        # since IOD might return a scalar or an array (depending on
                        # whether there is a single param=val or multiple param=
                        # lines), we need to arrayify the value if the argument is
                        # expected to be an array.
                        if (ref($v) ne 'ARRAY' && $rsch->[0] eq 'array') {
                            $v = [$v];
                        }
                    }
                    $copts->{$k}{handler}->(undef, $v, $r);
                } else {
                    # when common option clashes with function argument name,
                    # user can use NAME.arg to refer to function argument.
                    $k =~ s/\.arg\z//;

                    # since IOD might return a scalar or an array (depending on
                    # whether there is a single param=val or multiple param=
                    # lines), we need to arrayify the value if the argument is
                    # expected to be an array.
                    if (ref($v) ne 'ARRAY' && $as->{$k} && $as->{$k}{schema}) {
                        require Data::Sah::Resolve;
                        my $rsch = Data::Sah::Resolve::resolve_schema($as->{$k}{schema});
                        if ($rsch->[0] eq 'array') {
                            $v = [$v];
                        }
                    }
                    $args->{$k} = $v;
                }
            } # for params in section
        } # if for plugin
    }
    log_trace("[pericmd] Seen config profiles: %s",
              [sort keys %seen_profiles]);

    [200, "OK", $args, {'func.found'=>$found}];
}

1;
# ABSTRACT: Utility routines related to config files

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Util::Config - Utility routines related to config files

=head1 VERSION

This document describes version 1.724 of Perinci::CmdLine::Util::Config (from Perl distribution Perinci-CmdLine-Util-Config), released on 2020-10-21.

=head1 FUNCTIONS


=head2 get_args_from_config

Usage:

 get_args_from_config(%args) -> [status, msg, payload, meta]

C<config> is a HoH (hashes of hashrefs) produced by reading an INI (IOD)
configuration file using modules like L<Config::IOD::Reader>.

Hashref argument C<args> will be set by parameters in C<config>, while C<plugins>
will be set by parameters in C<[plugin=...]> sections in C<config>. For example,
with this configuration:

 arg1=val1
 arg2=val2
 -special_arg1=val3
 -special_arg2=val4
 
 [plugin=DumpArgs]
 -event=before_validation
 
 [plugin=Foo]
 arg1=val1

C<args> will become:

 {
   arg1=>"val1",
   arg2=>"val2",
   -special_arg1=>"val3",
   -special_arg2=>"val4",
 }

and C<plugins> will become:

 [
   'DumpArgs@before_validation' => {},
   Foo => {arg1=>val},
 ]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args> => I<hash>

=item * B<common_opts> => I<any>

=item * B<config> => I<any>

=item * B<config_profile> => I<any>

=item * B<meta> => I<any>

=item * B<meta_is_normalized> => I<any>

=item * B<plugins> => I<array>

=item * B<r> => I<any>

=item * B<subcommand_name> => I<any>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_default_config_dirs

Usage:

 get_default_config_dirs() -> [status, msg, payload, meta]

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 read_config

Usage:

 read_config(%args) -> [status, msg, payload, meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<config_dirs> => I<any>

=item * B<config_filename> => I<any>

=item * B<config_paths> => I<any>

=item * B<hook_section> => I<any>

=item * B<program_name> => I<any>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Util-Config>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Util-Config>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Util-Config>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
