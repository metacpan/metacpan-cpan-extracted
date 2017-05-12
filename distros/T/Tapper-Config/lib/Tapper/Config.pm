package Tapper::Config;
# git description: v5.0.2-1-g2d181a9

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Context sensitive configuration hub for all Tapper libs
$Tapper::Config::VERSION = '5.0.3';
use 5.010;

use strict;
use warnings;

use YAML::Syck;
use File::Slurp         'slurp';
use File::ShareDir      'module_file';
use Hash::Merge    'merge';
use File::ShareDir 'module_file';


# --- The configuration file is lib/auto/Tapper/Config/tapper.yml ---
{
        # closure to forbid direct access to the config hash
        my $Config;



        sub default_merge
        {
                my ($config) = @_;

                no warnings 'uninitialized'; # $ENV{HOME} can be undef

                foreach my $filename ("/etc/tapper.cfg",
                                      $ENV{HOME} ? "$ENV{HOME}/.tapper/tapper.cfg" : '',
                                      "$ENV{TAPPER_CONFIG_FILE}",
                                     )
                {
                        if (-e $filename) {
                                my $new_config;
                                eval { $new_config = LoadFile($filename) };
                                die "Can not load config file '$filename': $@\n" if $@;
                                Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );
                                $config = merge($config, $new_config);
                                $config->{_last_used_tapper_config_file} = $filename;
                        }
                }
                return $config;
        }

        sub _getenv
        {
                return
                    $ENV{HARNESS_ACTIVE} ? 'test'
                        : $ENV{TAPPER_DEVELOPMENT} ? 'development'
                            : 'live';
        }


        # TODO: automatically recognize context switch
        sub _switch_context
        {
                shift if @_ && $_[0] && $_[0] eq 'Tapper::Config'; # throw away class if called as method

                my $env = shift // _getenv();

                return unless $env =~ /^test|live|development$/;

                my $yaml = slurp module_file('Tapper::Config', 'tapper.yml');
                $Config  = Load($yaml);
                $Config  = default_merge($Config);

                Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );
                $Config  = merge( $Config, $Config->{$env} );
                $Config  = _prepare_special_entries( $Config );
        }


        sub _prepare_special_entries {
                my ($Config) = @_;

                # Log4Perl: prepend sharedir path
                if (not $Config->{files}{log4perl_cfg} =~ m,^/,) {
                        $Config->{files}{log4perl_cfg} = module_file('Tapper::Config', $Config->{files}{log4perl_cfg});
                }

                # DB config can be overridden triggered by env var
                my $dbms = $ENV{TAPPERDBMS};
                if ($dbms and _getenv ne 'test') {
                        if ($dbms =~ m/^mysql|postgresql$/) {
                                my $val = $Config->{database}{by_TAPPERDBMS}{$dbms}{TestrunDB};
                                $Config->{database}{TestrunDB} = $val if defined $val;
                        } else {
                                die 'Unsupported Tapper DBMS $TAPPERDBMS='.$ENV{TAPPERDBMS};
                        }
                }
                return $Config;
        }

        sub subconfig { $Config }

}

BEGIN { _switch_context() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Config - Tapper - Context sensitive configuration hub for all Tapper libs

=head1 SYNOPSIS

 use Tapper::Config;
 say Tapper::Config->subconfig->{test_value};
 say Tapper::Config->subconfig->{paths}{build_conf_path};

=head2 default_merge

Merges values from alternative config file locations into the
config. This allows to overwrite values given from the config provided
with the module. It searches for config in the following places.
* /etc/tapper.cfg
* $ENV{HOME}/.tapper/tapper.cfg
* filename given in $ENV{TAPPER_CONFIG_FILE}

@param hash ref - config

@return hash ref - merged config

=head2 Environment merge

Depending on environment variables a context of I<life>, I<test>, or
I<development> is derived. Default is I<live>. If C<HARNESS_ACTIVE> is
set the context is C<test>, if C<TAPPER_DEVELOPMENT> is set to C<1>
the context is I<development>.

This context is used for creating the final config. Inside the config
all keys under I<development> or I<test> are merged up into the main
level. Therefore usually there you put special values overriding
defaults.

=head2 Special entries

There are entries that are handled in special way:

=over 4

=item files.log4perl_cfg

This local path/file entry is prepended by the
sharedir path of Tapper::Config to make it an absolute path.

=item database

When the environment variable C<TAPPERDBMS> is set to C<postgresql>
(or C<mysql>) then the config values for C<database.TestrunDB> are overwritten
by the values <database.by_TAPPERDBMS.postgresql.TestrunDB> respectively.

This introduces a backwards compatible way of using another DBMS with
Tapper, in particular PostgreSQL.

=back

These special entries are prepared after the default and context
merges.

=head2 subconfig

Return the actual config for the current context.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
