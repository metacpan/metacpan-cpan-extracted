package Org::Shell::Commands;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-21'; # DATE
our $DIST = 'Org-Shell'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Path::Naive qw();

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'orgsh commands',
};

our $complete_path = sub {
    my %args = @_;
    my $shell = $args{-shell};

    my $word0 = $args{word};
    my ($dir, $word) = $word0 =~ m!(.*/)?(.*)!;
    $dir //= "";

    my $org = $shell->state('orgs')->{ $args{org} // $shell->state('curorg') // '' };
    return {message=>"No current Org document, please load some Org documents first"} unless $org;

    my $cwd = $org->{fs}->cwd;
    my @entries = $org->{fs}->ls(
        length($dir) ? Path::Naive::concat_and_normalize_path($cwd, $dir)."/*" : undef);

    [map {(length($dir) ? $dir : "") . "$_->{name}/"} @entries];
};

my $complete_setting_name = sub {
    my %args = @_;
    my $shell = $args{-shell};

    [keys %{ $shell->known_settings }];
};

our $complete_org_name = sub {
    my %args = @_;
    my $shell = $args{-shell};

    [keys %{ $shell->state('orgs') }];
};

my %arg0_org = (
    org => {
        schema => ['str*', match=>qr/\A\w+\z/],
        completion => $complete_org_name,
        req => 1,
        pos => 0,
    },
);

my %argopt_org = (
    org => {
        schema => ['str*', match=>qr/\A\w+\z/],
        cmdline_aliases => {o=>{}},
        completion => $complete_org_name,
    },
);

my %arg0_path = (
    path => {
        summary    => 'Path',
        schema     => ['str*'],
        req        => 1,
        pos        => 0,
        completion => $complete_path,
    },
);

my %arg0_paths = (
    paths => {
        summary    => 'Paths',
        schema     => ['array*', of=>'str*'],
        req        => 1,
        pos        => 0,
        slurpy     => 1,
        element_completion => $complete_path,
    },
);

my %argopt0_path = (
    path => {
        summary    => 'Path to node',
        schema     => ['str*'],
        pos        => 0,
        completion => $complete_path,
    },
);

my @drivers = qw(json yaml org);

$SPEC{loadorg} = {
    v => 1.1,
    summary => 'Load Org document',
    description => <<'_',

_
    args => {
        as => {
            schema => ['str*', {match => qr/\A\w+\z/}],
            pos => 0,
            req => 1,
        },
        source => {
            schema => ['pathname*'],
            pos => 1,
            req => 1,
            completion => sub {
                require Complete::File;
                Complete::File::complete_file(@_);
            },
        },
        opts => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'opt',
            schema => ['hash*', {of=>'str*'}],
        },
    },
};
sub loadorg {
    require File::Slurper::Dash;

    my %args = @_;
    my $as     = $args{as};
    my $driver = $args{driver};
    my $source = $args{source};
    my $shell  = $args{-shell};

    if ($shell->state('orgs')->{$as}) {
        return [412, "Org document with named '$as' already loaded, perhaps choose another name?"];
    }

    my $fs;
    require Tree::FSMethods::Org;
    eval { $fs = Tree::FSMethods::Org->new(org_file => $source) };
    return [500, "Can't load org file: $@"] if $@;

    $shell->state('orgs')->{$as} = {
        source => $source,
        fs     => $fs,
    };
    $shell->state('curorg', $as) unless defined $shell->state('curorg');
    return [200, "OK"];
}

$SPEC{orgs} = {
    v => 1.1,
    summary => 'List loaded Org documents',
    description => <<'_',

_
    args => {
    },
};
sub orgs {
    my %args = @_;
    my $shell  = $args{-shell};

    my $orgs    = $shell->state('orgs');
    my $curorg  = $shell->state('curorg') // '';
    my @rows;
    for my $name (sort keys %$orgs) {
        push @rows, {
            name => $name,
            source => $orgs->{$name}{source},
            active => $name eq $curorg ? 1:0,
            cwd    => $orgs->{$name}{fs}->cwd,
        };
    }
    [200, "OK", \@rows, {'table.fields'=>[qw/name source active cwd/]}];
}

$SPEC{setcurorg} = {
    v => 1.1,
    summary => 'Set current Org document',
    args => {
        %arg0_org,
    },
};
sub setcurorg {
    my %args = @_;
    my $shell  = $args{-shell};

    my $orgs = $shell->state('orgs');
    $orgs->{ $args{org} }
        or return [404, "No such Org document '$args{org}'"];
    $shell->state('curorg', $args{org});
    [200];
}

$SPEC{cat} = {
    v => 1.1,
    summary => 'Print node as string',
    args => {
        %argopt_org,
        %arg0_path,
    },
};
sub cat {
    my %args = @_;
    my $shell  = $args{-shell};

    my $org = $shell->state('orgs')->{ $args{org} // $shell->state('curorg') // '' };
    unless ($org) {
        return [412, "No such Org document '$args{org}'"] if defined $args{org};
        return [412, "No loaded Org documents, load some first using 'loadorg'"];
    }

    my $node;
    eval {
        $node = $org->{fs}->get($args{path});
    };
    return [500, "Can't cat: $@"] if $@;

    [200, "OK", $node->as_string];
}

$SPEC{dumporg} = {
    v => 1.1,
    summary => 'Dump a loaded Org document',
    description => <<'_',

_
    args => {
        name => {
            schema => ['str*'],
            pos => 0,
            completion => $complete_org_name,
        },
    },
};
sub dumporg {
    my %args = @_;
    my $name   = $args{name};
    my $shell  = $args{-shell};

    $name //= $shell->state('curorg');
    return [412, "Please load an Org document first"] unless defined $name;

    my $orgs = $shell->state('orgs');
    return [404, "No Org document by that name"] unless $orgs->{$name};

    require Tree::Dump;
    [200, "OK", Tree::Dump::tdmp($orgs->{$name}{fs}{tree}),
     {'cmdline.skip_format'=>1}];
}

$SPEC{ls} = {
    v => 1.1,
    summary => 'List children nodes',
    args => {
        %argopt_org,
        long => {
            summary => 'Long mode (detail=1)',
            schema => ['true*'],
            cmdline_aliases => { l => {} },
        },
        path => {
            summary    => 'Path to node',
            schema     => ['str'],
            pos        => 0,
            completion => $complete_path,
        },
        all => {
            summary     => 'Does nothing, added only to let you type ls -la',
            schema      => ['bool'],
            description => <<'_',

Some of you might type `ls -la` or `ls -al` by muscle memory. So the -a option
is added just to allow this to not produce an error :-).

_
            cmdline_aliases => { a=>{} },
        },
    },
};
sub ls {
    my %args = @_;
    my $shell = $args{-shell};

    my $resmeta = {};

    my $org = $shell->state('orgs')->{ $args{org} // $shell->state('curorg') // '' };
    unless ($org) {
        return [412, "No such Org document '$args{org}'"] if defined $args{org};
        return [412, "No loaded Org documents, load some first using 'loadorg'"];
    }

    my @rows;
    my @entries;
    eval { @entries = $org->{fs}->ls($args{path}) };
    return [500, "Can't ls: $@"] if $@;

    for my $entry (@entries) {
        if ($args{long}) {
            push @rows, {
                order => $entry->{order},
                name  => $entry->{name},
            };
        } else {
            push @rows, $entry->{name};
        }
    }

    $resmeta->{'table.fields'} = [qw/order name/] if $args{long};
    [200, "OK", \@rows, $resmeta];
}

$SPEC{pwd} = {
    v => 1.1,
    summary => 'Show current directory in an Org document',
    args => {
        %argopt_org,
    },
};
sub pwd {
    my %args = @_;
    my $shell = $args{-shell};

    my $orgname = $args{org} // $shell->state('curorg') // '';
    my $org = $shell->state('orgs')->{ $orgname };
    unless ($org) {
        return [412, "No such Org document '$args{org}'"] if defined $args{org};
        return [412, "No loaded Org documents, load some first using 'loadorg'"];
    }

    return [200, "OK", "$org->{fs}{_curpath} ($orgname)"];
}

$SPEC{cd} = {
    v => 1.1,
    summary => "Change directory",
    args => {
        %argopt_org,
        path => {
            summary    => '',
            schema     => ['str*'],
            pos        => 0,
            completion => $complete_path,
        },
    },
};
sub cd {
    my %args = @_;
    my $path = $args{path};
    my $shell = $args{-shell};

    my $org = $shell->state('orgs')->{ $args{org} // $shell->state('curorg') // '' };
    unless ($org) {
        return [412, "No such Org document '$args{org}'"] if defined $args{org};
        return [412, "No loaded Org documents, load some first using 'loadorg'"];
    }

    my $cwd = $org->{fs}->cwd;
    if ($path eq '-') {
        if (defined $org->{oldcwd}) {
            $path = $org->{oldcwd};
        } else {
            return [412, "Old directory not set yet, cd to some directory first"];
        }
    }

    eval { $org->{fs}->cd($path) };
    if ($@) {
        return [500, "Can't cd: $@"];
    } else {
        $org->{oldcwd} = $cwd;
        return [200, "OK"];
    }
}

$SPEC{tree} = {
    v => 1.1,
    summary => 'Show filesystem tree',
    args => {
        %argopt_org,
        %argopt0_path,
    },
};
sub tree {
    my %args = @_;
    my $shell = $args{-shell};

    my $resmeta = {};

    my $org = $shell->state('orgs')->{ $args{org} // $shell->state('curorg') // '' };
    unless ($org) {
        return [412, "No such Org document '$args{org}'"] if defined $args{org};
        return [412, "No loaded Org documents, load some first using 'loadorg'"];
    }

    [200, "OK", $org->{fs}->showtree($args{path})];
}

our %args_cp_or_mv = (
    src_path => {
        summary => 'Source path',
        schema => 'str*',
        completion => sub {
            my %args = @_;
            my $shell = $args{-shell};
            my $org = $shell->state('orgs')->{ $shell->state('curorg') // '' };
            return [] unless $org;
            my $res = $complete_path->(%args);
            $res;
        },
        req => 1,
        pos => 0,
    },
    target_org => {
        summary => 'Target Org document name',
        schema => ['str*', match=>qr/\A\w+\z/],
        completion => $complete_org_name,
    },
    target_path => {
        summary => 'Target path',
        schema => 'str*',
        completion => sub {
            my %args = @_;
            my $shell = $args{-shell};
            my $target_org = $args{args}{target_org};
            my $org = $shell->state('orgs')->{ $target_org // $shell->state('curorg') // '' };
            return [] unless $org;
            my $save_curorg = $shell->state('curorg');
            $shell->state('curorg', $target_org) if defined $target_org;
            my $res = $complete_path->(%args);
            $shell->state('curorg', $save_curorg);
            $res;
        },
        req => 1,
        pos => 1,
    },
);

sub _cp_or_mv {
    my $which = shift;

    my %args = @_;
    my $shell = $args{-shell};

    my $src_org    = $shell->state('orgs')->{ $shell->state('curorg') // '' }
        or return [412, "No Org document loaded, please load an Org document first"];
    my $target_org = $shell->state('orgs')->{ $args{target_org} // $shell->state('curorg') // '' }
        or return [412, "No such target Org document '$args{target_org}'"];

    eval {
        local $src_org->{fs}{tree2}     = $target_org->{fs}{tree};
        local $src_org->{fs}{_curnode2} = $target_org->{fs}{_curnode};
        local $src_org->{fs}{_curpath2} = $target_org->{fs}{_curpath};

        $src_org->{fs}->$which($args{src_path}, $args{target_path});
    };
    return [500, "Can't $which: $@"] if $@;
    [200];
}

$SPEC{cp} = {
    v => 1.1,
    summary => 'Copy nodes from one Org document to another',
    args => {
        %args_cp_or_mv,
    },
};
sub cp {
    _cp_or_mv('cp', @_);
}

$SPEC{mv} = {
    v => 1.1,
    summary => 'Move nodes from one Org document to another',
    args => {
        %args_cp_or_mv,
    },
};
sub mv {
    _cp_or_mv('mv', @_);
}

$SPEC{rm} = {
    v => 1.1,
    summary => 'Remove nodes',
    args => {
        %arg0_path,
        %argopt_org,
    },
};
sub rm {
    my %args = @_;
    my $shell = $args{-shell};

    my $resmeta = {};

    my $org = $shell->state('orgs')->{ $args{org} // $shell->state('curorg') // '' };
    unless ($org) {
        return [412, "No such Org document '$args{org}'"] if defined $args{org};
        return [412, "No loaded Org documents, load some first using 'loadorg'"];
    }

    eval {
        $org->{fs}->rm($args{path});
    };
    return [500, "Can't rm: $@"] if $@;

    [200];
}

$SPEC{mkdir} = {
    v => 1.1,
    summary => 'Create an empty directory',
    args => {
        %arg0_paths,
        %argopt_org,
        parents => {
            schema => 'true*',
            cmdline_aliases => {p=>{}},
        },
    },
};
sub mkdir {
    my %args = @_;
    my $shell = $args{-shell};

    my $resmeta = {};

    my $org = $shell->state('orgs')->{ $args{org} // $shell->state('curorg') // '' };
    unless ($org) {
        return [412, "No such Org document '$args{org}'"] if defined $args{org};
        return [412, "No loaded Org documents, load some first using 'loadorg'"];
    }

    my %opts;
    $opts{parents} = 1 if $args{parents};

    my $has_error;
    for my $path (@{ $args{paths} }) {
        eval { $org->{fs}->mkdir(\%opts, $path) };
        if ($@) {
            warn "Can't mkdir $path: $@\n";
            $has_error++;
        }
    }

    [200];
}

$SPEC{set} = {
    v => 1.1,
    summary => "List or set setting",
    args => {
        name => {
            summary    => '',
            schema     => ['str*'],
            pos        => 0,
            # we use custom completion because the list of known settings must
            # be retrieved through the shell object
            completion => $complete_setting_name,
        },
        value => {
            summary    => '',
            schema     => ['any'],
            pos        => 1,
            completion => sub {
                require Perinci::Sub::Complete;

                my %args = @_;
                my $shell = $args{-shell};
                my $args  = $args{args};
                return [] unless $args->{name};
                my $setting = $shell->known_settings->{ $args->{name} };
                return [] unless $setting;

                # a hack, construct a throwaway meta and using that to complete
                # setting argument as function argument
                Perinci::Sub::Complete::complete_arg_val(
                    arg=>'foo',
                    meta=>{v=>1.1, args=>{foo=>{schema=>$setting->{schema}}}},
                );
            },
        },
    },
};
sub set {
    my %args = @_;
    my $shell = $args{-shell};

    my $name  = $args{name};

    if (exists $args{value}) {
        # set setting
        return [400, "Unknown setting, use 'set' to list all known settings"]
            unless exists $shell->known_settings->{$name};
        $shell->setting($name, $args{value});
        [200, "OK"];
    } else {
        # list settings
        my $res = [];
        if (defined $name) {
            return [400,"Unknown setting, use 'set' to list all known settings"]
                unless exists $shell->known_settings->{$name};
        }
        for (sort keys %{ $shell->known_settings }) {
            next if defined($name) && $_ ne $name;
            push @$res, {
                name => $_,
                summary => $shell->known_settings->{$_}{summary},
                value   => $shell->{_settings}{$_},
                default => $shell->known_settings->{$_}{schema}[1]{default},
            };
        }
        [200, "OK", $res, {'table.fields' => [qw/name summary value default/]}];
    }
}

$SPEC{unset} = {
    v => 1.1,
    summary => "Unset a setting",
    args => {
        name => {
            summary    => '',
            schema     => ['str*'],
            req        => 1,
            pos        => 0,
            completion => $complete_setting_name,
        },
    },
};
sub unset {
    my %args = @_;
    my $shell = $args{-shell};

    my $name = $args{name};

    return [400, "Unknown setting, use 'set' to list all known settings"]
        unless exists $shell->known_settings->{$name};
    delete $shell->{_settings}{$name};
    [200, "OK"];
}

$SPEC{history} = {
    v => 1.1,
    summary => 'Show command-line history',
    args => {
        append => {
            summary    => "Append current session's history to history file",
            schema     => 'bool',
            cmdline_aliases => { a=>{} },
        },
        read => {
            summary    => '(Re-)read history from file',
            schema     => 'bool',
            cmdline_aliases => { r=>{} },
        },
        clear => {
            summary    => 'Clear history',
            schema     => 'bool',
            cmdline_aliases => { c=>{} },
        },
    },
};
sub history {
    my %args = @_;
    my $shell = $args{-shell};

    if ($args{add}) {
        $shell->save_history;
        return [200, "OK"];
    } elsif ($args{read}) {
        $shell->load_history;
        return [200, "OK"];
    } elsif ($args{clear}) {
        $shell->clear_history;
        return [200, "OK"];
    } else {
        my @history;
        if ($shell->{term}->Features->{getHistory}) {
            @history = grep { length } $shell->{term}->GetHistory;
        }
        return [200, "OK", \@history,
                {"x.app.riap.default_format"=>"text-simple"}];
    }
}

1;
# ABSTRACT: orgsh commands

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Shell::Commands - orgsh commands

=head1 VERSION

version 0.001

=for Pod::Coverage .+

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
