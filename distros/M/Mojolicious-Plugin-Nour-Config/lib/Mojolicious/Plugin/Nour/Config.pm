package Mojolicious::Plugin::Nour::Config;
use Mojo::Base 'Mojolicious::Plugin';
use Nour::Config; has '_nour_config';
use List::AllUtils qw/:all/;
use Linux::Inotify2;
use IO::All;
use File::Find;
# ABSTRACT: Robustly imports config from a ./config sub-directory loaded with nested YAML files

sub register {
    my ( $self, $app, $opts ) = @_;
    my $helpers = delete $opts->{ '-helpers' };
    my $silence = delete $opts->{ '-silence' };
    my $watcher = delete $opts->{ '-watcher' };

    $app->helper( _config_nour => sub {
        $self->_nour_config( new Nour::Config ( %{ $opts } ) );
        return $self->_nour_config->config;
    } );

    $app->_config_nour;

    if ( $helpers ) { # inherit some helpers from Nour::Base
        do { my $method = $_; eval qq|
        \$app->helper( $method => sub {
            my ( \$ctrl, \@args ) = \@_;
            return \$self->_nour_config->$method( \@args );
        } )| } for qw/path merge_hash write_yaml/;
    }

    my $config = $self->_nour_config->config;
    my $current = $app->defaults( config => $app->config )->config;
    %{ $current } = ( %{ $current }, %{ $config } );

    $app->log->debug( 'config', $app->dumper( $current ) ) unless $silence;

    if ( $watcher ) {
        for ( my $spawn = fork ) {
            if ( not defined $spawn ) { # resource not available
                $app->log->warn( "nour-config watcher said: resource not available?" );
            }
            elsif ( $spawn eq -1 ) { # can't fork
                $app->log->warn( "nour-config watcher said: can't fork?" );
            }
            elsif ( $spawn eq 0 ) { # child process
                $self->watcher_run( $app );
            }
            else { # parent process
                $self->_watcher_pid( $_ );
                $_ > io( $self->_watcher_file );
            }
        }
    }

    return $current;
}

has '_watcher_pid';
has '_watcher_file' => sub { '/tmp/nour-config.watcher.pid' };
has '_watcher_inotify' => sub { new Linux::Inotify2 };
sub DESTROY {
    my $self = shift;
    $self->watcher_kill;
}
sub watcher_kill {
    my ( $self, $sig ) = @_;
    my ( $file, $pid ) = ( $self->_watcher_file, $self->_watcher_pid );

    $pid = $self->watcher_pid unless $pid;
    $sig //= 'kill';

    system 'rm', qw/-f/, $file if -e $file;
    system 'kill', qw/-s/, $sig, $pid if $pid;

    return $pid;
}

sub watcher_pid {
    my ( $self ) = @_;
    my ( $pid, $file ) = ( $self->_watcher_pid, $self->_watcher_file );

    return $pid if $pid;

    $pid = io( $file )->all if -e $file;
    $pid =~ s/[^\d]*//g if $pid;
    $pid = `ps aux | grep --color=never " $pid " | grep -v grep | awk -F' ' '{ print \$2 }' | grep "^$pid\$"` if $pid;
    $pid =~ s/[^\d]*//g if $pid;

    $self->_watcher_pid( $pid ) if $pid;
    return $pid;
}

sub watcher_run {
    my ( $self, $app ) = @_;
    my ( @path, %while ) = ( @{ $self->_nour_config->_path_list } );
    my ( $watch, $event, $changed );

    $changed = sub {
        my ( $file, $notice ) = @_;
        return (
            -f $file
                and not $file =~ /\/\.[^\/]+\.sw.$/
                and     $file =~ /[^\/]+\.[^\/]+$/
                and (   $file =~ /\.ep$/
                    or  $file =~ /\.pm$/
                    or  $file =~ /\.yml$/ )
                and (
                        $notice->IN_MODIFY or
                        $notice->IN_DELETE or
                        $notice->IN_CLOSE_WRITE or
                        $notice->IN_MOVED_TO
                )
        );
    };

    $event = sub {
        my $notice = shift;
        my $file = $notice->fullname;
        $while{poll} = 0 if -d $file and $notice->IN_CREATE;
        do {
            $while{poll} = 0;
            sleep 1;
        } if $changed->( $file, $notice );
    };

    $watch = sub {
        my @watched;
        find( { wanted => sub {
            my $path = File::Spec->rel2abs( $File::Find::name );
            push @watched, $path if -d $path;
        } }, @path );
        @watched = uniq @watched;
        $self->_watcher_inotify->watch( $_, IN_ALL_EVENTS, $event ) for @watched;
    };

    $while{loop} = 1;
    while ( $while{loop} ) {
        my $conf = $app->config;
        $conf->{foo}{bar}{baz}++;
        my $nour = $app->_config_nour;
        %{ $conf } = ( %{ $conf }, %{ $nour } );
        $watch->();
        $while{poll} = 1;
        $self->_watcher_inotify->poll while $while{poll};
    }
}



1;

__END__

=pod

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Nour::Config - Robustly imports config from a ./config sub-directory loaded with nested YAML files

=head1 VERSION

version 0.09

=head1 USAGE

Place your YAML configuration files under a ./config sub-directory from your mojo app's home directory.
There's an example in the package tarball you can look at, but roughly something like this:

     $ find ./config/
    ./config/
    ./config/application
    ./config/application/nested
    ./config/application/nested/example.yml
    ./config/application.yml
    ./config/database
    ./config/database/private
    ./config/database/private/production.yml
    ./config/database/private/README.md
    ./config/database/config.yml

Somewhere in your startup routine, include something like this:

    $self->plugin( 'Mojolicious::Plugin::Nour::Config', {
        -base => 'config'
        , -helpers => 1 # adds some unrelated helper methods i wrote
        , -silence => 1 # turning this on disables the config dump on startup in the debug log
    } );

On application startup, if you haven't turned the silence option on you can see your configuration from the debug log:

    [Tue Apr  8 12:10:21 2014] [debug] config
    {
      'application' => {
        'nested' => {
          'example' => {
            'wow' => 'amazing'
          }
        },
        'secret' => 'don\'t tell anyone'
      },
      'database' => {
        'default' => {
          'database' => 'production',
          'option' => {
            'AutoCommit' => '1',
            'PrintError' => '1',
            'RaiseError' => '1',
            'pg_bool_tf' => '0',
            'pg_enable_utf8' => '1'
          },
          'password' => 'nour',
          'username' => 'nour'
        },
        'development' => {
          'dsn' => 'dbi:Pg:dbname=nourdb_dev',
          'password' => 'sharabash',
          'username' => 'nour'
        },
        'production' => {
          'dsn' => 'dbi:Pg:dbname=nourdb_prod;host=secret.com',
          'password' => 'secret',
          'username' => 'override'
        }
      }
    }

Neat, right? Yeah.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/sharabash/mojolicious-plugin-nour-config/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/sharabash/mojolicious-plugin-nour-config>

  git clone git://github.com/sharabash/mojolicious-plugin-nour-config.git

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 CONTRIBUTOR

Nour Sharabash <nour.sharabash@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
