package Pcore::Core::CLI;

use Pcore -class;
use Pcore::Util::Scalar qw[is_ref is_plain_arrayref];
use Getopt::Long qw[];
use Pcore::Core::CLI::Opt;
use Pcore::Core::CLI::Arg;
use Config;

has class    => ( required => 1 );
has cmd_path => ( sub { [] } );      # array of used cli commands

has spec       => ( is => 'lazy', init_arg => undef );    # HashRef
has cmd        => ( is => 'lazy', init_arg => undef );    # ArrayRef
has opt        => ( is => 'lazy', init_arg => undef );    # HashRef
has arg        => ( is => 'lazy', init_arg => undef );    # ArrayRef
has is_cmd     => ( is => 'lazy', init_arg => undef );
has _cmd_index => ( is => 'lazy', init_arg => undef );    # HashRef

sub _build_spec ($self) { return $self->_get_class_spec }

sub _build_cmd ($self) {
    my $cmd = [];

    if ( my $cli_cmd = $self->spec->{cmd} ) {
        my @classes;

        for my $cli_cmd_class ( $cli_cmd->@* ) {
            if ( substr( $cli_cmd_class, -2, 2 ) eq q[::] ) {
                my $ns = $cli_cmd_class;

                my $ns_path = $ns =~ s[::][/]smgr;

                for (@INC) {
                    next if ref;

                    my $path = $_ . q[/] . $ns_path;

                    next if !-d $path;

                    for my $fn ( P->file->read_dir( $path, full_path => 0 )->@* ) {
                        if ( $fn =~ /\A(.+)[.]pm\z/sm && -f "$path/$fn" ) {
                            push @classes, $ns . $1;
                        }
                    }
                }
            }
            else {
                push @classes, $cli_cmd_class;
            }
        }

        my $index;

        for my $class (@classes) {
            next if $index->{$class};

            $index->{$class} = 1;

            $class = P->class->load($class);

            if ( $class->isa('Pcore::Core::CLI::Cmd') ) {
                push $cmd->@*, $class;
            }
        }
    }

    return $cmd;
}

sub _build_opt ($self) {
    my $opt = {};

    my $index = {
        help    => undef,
        h       => undef,
        q[?]    => undef,
        version => undef,
    };

    if ( my $cli_opt = $self->spec->{opt} ) {
        for my $name ( keys $cli_opt->%* ) {
            die qq[Option "$name" is duplicated] if exists $index->{$name};

            $opt->{$name} = Pcore::Core::CLI::Opt->new( { $cli_opt->{$name}->%*, name => $name } );    ## no critic qw[ValuesAndExpressions::ProhibitCommaSeparatedStatements]

            $index->{$name} = 1;

            if ( $opt->{$name}->short ) {
                die qq[Short name "@{[$opt->{$name}->short]}" for option "$name" is duplicated] if exists $index->{ $opt->{$name}->short };

                $index->{ $opt->{$name}->short } = 1;
            }
        }
    }

    return $opt;
}

sub _build_arg ($self) {
    my $args = [];

    my $index = {};

    my $next_arg = 0;    # 0 - any, 1 - min = 0, 2 - no arg

    if ( my $cli_arg = $self->spec->{arg} ) {
        for ( my $i = 0; $i <= $cli_arg->$#*; $i += 2 ) {
            die q[Can't have other arguments after slurpy argument] if $next_arg == 2;

            $cli_arg->[ $i + 1 ]->{name} = $cli_arg->[$i];

            my $arg = Pcore::Core::CLI::Arg->new( $cli_arg->[ $i + 1 ] );

            die q[Can't have required argument after not mandatory argument] if $next_arg == 1 && $arg->min != 0;

            die qq[Argument "@{[$arg->{name}]}" is duplicated] if exists $index->{ $arg->{name} };

            if ( !$arg->max ) {    # slurpy arg
                $next_arg = 2;
            }
            elsif ( $arg->min == 0 ) {
                $next_arg = 1;
            }

            push $args->@*, $arg;

            $index->{ $arg->{name} } = 1;
        }
    }

    return $args;
}

sub _build__cmd_index ($self) {
    my $index = {};

    for my $class ( $self->cmd->@* ) {
        for my $cmd ( $self->_get_class_cmd($class)->@* ) {
            die qq[Command "$cmd" is duplicated] if exists $index->{$cmd};

            $index->{$cmd} = $class;
        }
    }

    return $index;
}

sub _build_is_cmd ($self) { return $self->_cmd_index->%* ? 1 : 0 }

sub run ( $self, $argv ) {

    # redirect, if class is defined
    if ( $self->spec->{class} ) {
        require $self->spec->{class} =~ s[::][/]smgr . '.pm';

        return __PACKAGE__->new( { class => $self->spec->{class} } )->run($argv);
    }

    # make a copy
    my @argv = $argv ? $argv->@* : ();

    if ( $self->is_cmd ) {
        return $self->_parse_cmd( \@argv );
    }
    else {
        return $self->_parse_opt( \@argv );
    }
}

sub _parse_cmd ( $self, $argv ) {
    my $res = {
        cmd  => undef,
        opt  => {},
        rest => undef,
    };

    my $parser = Getopt::Long::Parser->new(
        config => [    #
            'no_auto_abbrev',
            'no_getopt_compat',
            'gnu_compat',
            'no_require_order',
            'permute',
            'bundling',
            'no_ignore_case',
            'pass_through',
        ]
    );

    $parser->getoptionsfromarray(
        $argv,
        $res->{opt},
        'help|h|?',
        'version',
        '<>' => sub ($arg) {
            if ( !$res->{cmd} && substr( $arg, 0, 1 ) ne q[-] ) {
                $res->{cmd} = $arg;
            }
            else {
                push $res->{rest}->@*, $arg;
            }

            return;
        }
    );

    push $res->{rest}->@*, $argv->@* if defined $argv && $argv->@*;

    if ( $res->{opt}->{version} ) {
        return $self->help_version;
    }
    elsif ( !defined $res->{cmd} ) {
        if ( $res->{opt}->{help} ) {
            return $self->help;
        }
        else {
            return $self->help_usage;
        }
    }
    else {
        my $possible_commands = [];

        my @index = keys $self->_cmd_index->%*;

        for my $cmd_name (@index) {
            push $possible_commands->@*, $cmd_name if index( $cmd_name, $res->{cmd} ) == 0;
        }

        if ( !$possible_commands->@* ) {
            return $self->help_usage( [qq[command "$res->{cmd}" is unknown]] );
        }
        elsif ( $possible_commands->@* > 1 ) {
            return $self->help_error( qq[command "$res->{cmd}" is ambiguous:$LF  ] . join q[ ], $possible_commands->@* );
        }
        else {
            unshift $res->{rest}->@*, '--help' if $res->{opt}->{help};

            my $class = $self->_cmd_index->{ $possible_commands->[0] };

            push $self->{cmd_path}->@*, $self->_get_class_cmd($class)->[0];

            return __PACKAGE__->new( { class => $class, cmd_path => $self->{cmd_path} } )->run( $res->{rest} );
        }
    }
}

sub _parse_opt ( $self, $argv ) {
    my $res = {
        error => undef,
        opt   => {},
        arg   => {},
        rest  => undef,
    };

    # build cli spec for Getopt::Long
    my $cli_spec = [];

    for my $opt ( values $self->opt->%* ) {
        push $cli_spec->@*, $opt->getopt_spec;
    }

    my $parser = Getopt::Long::Parser->new(
        config => [    #
            'auto_abbrev',
            'no_getopt_compat',    # do not allow + to start options
            'gnu_compat',
            'no_require_order',
            'permute',
            'bundling',
            'no_ignore_case',
            'no_pass_through',
        ]
    );

    my $parsed_args = [];

    {
        no warnings qw[redefine];

        local $SIG{__WARN__} = sub {
            push $res->{error}->@*, join q[], @_;

            $res->{error}->[-1] =~ s/\n\z//sm;

            return;
        };

        $parser->getoptionsfromarray(
            $argv,
            $res->{opt},
            $cli_spec->@*,
            'version',
            'help|h|?',
            '<>' => sub ($arg) {
                push $parsed_args->@*, $arg;

                return;
            }
        );

        push $res->{rest}->@*, $argv->@* if defined $argv && $argv->@*;
    }

    if ( $res->{opt}->{version} ) {
        return $self->help_version;
    }
    elsif ( $res->{opt}->{help} ) {
        return $self->help;
    }
    elsif ( $res->{error} ) {
        return $self->help_usage( $res->{error} );
    }

    # validate options
    for my $opt ( values $self->opt->%* ) {
        if ( my $error_msg = $opt->validate( $res->{opt} ) ) {
            return $self->help_usage( [$error_msg] );
        }
    }

    # parse and validate args
    for my $arg ( $self->arg->@* ) {
        if ( my $error_msg = $arg->parse( $parsed_args, $res->{arg} ) ) {
            return $self->help_usage( [$error_msg] );
        }
    }

    return $self->help_usage( [qq[unexpected arguments]] ) if $parsed_args->@*;

    # validate cli
    my $class = $self->{class};

    if ( $class->can('CLI_VALIDATE') && defined( my $error_msg = $class->CLI_VALIDATE( $res->{opt}, $res->{arg}, $res->{rest} ) ) ) {
        return $self->help_error($error_msg);
    }

    # store results globally
    $ENV->{cli} = $res;

    # run
    if ( $class->can('CLI_RUN') ) {
        return $class->CLI_RUN( $res->{opt}, $res->{arg}, $res->{rest} );
    }
    else {
        return $res;
    }
}

sub _get_class_spec ( $self, $class = undef ) {
    $class //= $self->{class};

    if ( $class->can('CLI') && ( my $spec = $class->CLI ) ) {
        if ( !is_ref $spec ) {
            $spec = { class => $spec };
        }
        elsif ( is_plain_arrayref $spec ) {
            $spec = { cmd => $spec };
        }
        else {
            $spec->{cmd} = [ $spec->{cmd} ] if $spec->{cmd} && !is_ref $spec->{cmd};

            $spec->{name} = [ $spec->{name} ] if $spec->{name} && !is_ref $spec->{name};
        }

        return $spec;
    }
    else {
        return {};
    }
}

sub _get_class_cmd ( $self, $class = undef ) {
    my $spec = $class ? $self->_get_class_spec($class) : $self->spec;

    if ( $spec->{name} ) {
        return $spec->{name};
    }
    else {
        $class //= $self->{class};

        return [ lc $class =~ s/\A.*:://smr ];
    }
}

# HELP
sub _help_class_abstract ( $self, $class = undef ) {
    my $spec = $class ? $self->_get_class_spec($class) : $self->spec;

    return $spec->{abstract} // q[];
}

sub _help_usage_string ($self) {
    my $usage = join q[ ], P->path( $ENV->{SCRIPT_NAME} )->{filename}, $self->{cmd_path}->@*;

    if ( $self->is_cmd ) {
        $usage .= ' [COMMAND] [OPTION]...';
    }
    else {
        $usage .= ' [OPTION]...' if $self->opt->%*;

        if ( $self->arg->@* ) {
            my @args;

            for my $arg ( $self->arg->@* ) {
                push @args, $arg->help_spec;
            }

            $usage .= q[ ] . join q[ ], @args;
        }
    }

    return $usage;
}

sub _help_alias ($self) {
    my $cmd = $self->_get_class_cmd;

    shift $cmd->@*;

    if ( $cmd->@* ) {
        return 'aliases: ' . join q[ ], sort $cmd->@*;
    }
    else {
        return q[];
    }
}

sub _help ($self) {
    my $help = $self->spec->{help} // q[];

    if ($help) {
        $help =~ s/^/    /smg;

        $help =~ s/\n+\z//sm;
    }

    return $help;
}

sub _help_usage ($self) {
    my $help;

    my $list = {};

    if ( $self->is_cmd ) {
        $help = 'list of commands:' . $LF . $LF;

        for my $class ( $self->cmd->@* ) {
            $list->{ $self->_get_class_cmd($class)->[0] } = [ $self->_get_class_cmd($class)->[0], $self->_help_class_abstract($class) ];
        }
    }
    else {
        $help = 'options ([+] - can be repeated, [!] - is required):' . $LF . $LF;

        for my $opt ( values $self->opt->%* ) {
            $list->{ $opt->{name} } = [ $opt->help_spec, $opt->{desc} // '' ];
        }
    }

    return q[] if !$list->%*;

    my $max_key_len = 10;

    for ( values $list->%* ) {
        $max_key_len = length $_->[0] if length $_->[0] > $max_key_len;

        # remove \n from desc
        $_->[1] =~ s/\n+\z//smg;
    }

    my $desc_indent = $LF . q[    ] . ( q[ ] x $max_key_len );

    $help .= join $LF, map { sprintf( " %-${max_key_len}s   ", $list->{$_}->[0] ) . $list->{$_}->[1] =~ s/\n/$desc_indent/smgr } sort keys $list->%*;

    return $help // q[];
}

sub _help_footer ($self) { return '(global options: --help, -h, -?, --version)' }

sub help ($self) {
    say $self->_help_usage_string, $LF;

    if ( my $alias = $self->_help_alias ) {
        say $alias, $LF;
    }

    if ( my $abstract = $self->_help_class_abstract ) {
        say $abstract, $LF;
    }

    if ( my $help = $self->_help ) {
        say $help, $LF;
    }

    if ( my $help_usage = $self->_help_usage ) {
        say $help_usage, $LF;
    }

    say $self->_help_footer, $LF;

    exit 2;
}

sub help_usage ( $self, $invalid_options = undef ) {
    if ($invalid_options) {
        for ( $invalid_options->@* ) {
            say;
        }

        print $LF;
    }

    say $self->_help_usage_string, $LF;

    if ( my $abstract = $self->_help_class_abstract ) {
        say $abstract, $LF;
    }

    if ( my $help_usage = $self->_help_usage ) {
        say $help_usage, $LF;
    }

    say $self->_help_footer, $LF;

    exit 2;
}

sub help_version ($self) {
    if ( $ENV->dist ) {
        say $ENV->dist->version_string;
    }
    else {
        say join q[ ], $ENV->{SCRIPT_NAME}, ( $main::VERSION ? version->new($main::VERSION)->normal : () );
    }

    say $ENV->{pcore}->version_string if !$ENV->dist || $ENV->dist->name ne $ENV->{pcore}->name;

    say 'Perl ' . $^V->normal . " $Config{archname}";

    say join $LF, q[], 'Image path: ' . $ENV{PAR_PROGNAME}, 'Temp dir: ' . $ENV{PAR_TEMP} if $ENV->{is_par};

    exit 2;
}

sub help_error ( $self, $msg ) {
    say $msg, $LF if defined $msg;

    exit 2;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 42                   | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 329                  | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 488, 516             | NamingConventions::ProhibitAmbiguousNames - Ambiguously named variable "abstract"                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 108                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 457                  | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::CLI

=head1 SYNOPSIS

    # redirect CLI processing
    sub CLI ($self) {
        return 'Other::Class';
    }

    # CLI commands hub
    sub CLI {
        return ['Cmd1', 'Cmd2', 'Cmd::Modules::' ];
    }

    # or
    sub CLI {
        return {
            abstract => 'Abstract description',
            help     => <<'HELP',
    Full CLI help
    HELP
            cmd      => ['Cmd1', 'Cmd2', 'Cmd::Modules::' ],
        };
    }

    # CLI command class
    extends qw[Pcore::Core::CLI::Cmd];

    sub CLI ($self) {
        return {
            name     => 'command',
            abstract => 'abstract desc',
            help     => undef,
            opt      => {},
            arg      => {},
        };
    }

    sub CLI_VALIDATE ( $self, $opt, $arg, $rest ) {
        return;
    }

    sub CLI_RUN ( $self, $opt, $arg, $rest ) {
        return;
    }

=head1 DESCRIPTION

CLI class can be either a CLI "commands hub" or "command". Command hub - only keep other CLI commands together, it doesn't do anything else. CLI command must be a instance of Pcore::Core::CLI::Cmd role.

=head1 METHODS

=head2 CLI ($self)

Return CLI specification as Str, ArrayRef of HashRef. Str - name of class to redirect CLI processor to. ArrayRef - list of CLI commands classes or namespaces. HashRef - full CLI specification, where supported keys are:

=over

=item * cmd - CLI commands classes names or namespace. Namespace should be specified with '::' at the end, eg.: 'My::CLI::Packages::'. cmd can be Str or ArrayRef[Str];

=item * abstract - short description;

=item * help - full help, can be multiline string;

=item * name - CLI command name, can be a Str or ArrayRef[Str], if command has aliases. If command name is not specified - if will be parsed from the last segment of the class name;

=item * opt - HashRef, options specification;

=item * arg - ArrayRef, arguments specification;

=back

=head2 CLI_VALIDATE ( $self, $opt, $arg, $rest )

Should validate parsed CLI data and return Str in case of error or undef.

=head2 CLI_RUN ( $self, $opt, $arg, $rest )

=head1 SEE ALSO

=cut
