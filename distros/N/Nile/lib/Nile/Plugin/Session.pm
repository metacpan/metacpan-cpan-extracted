#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Session;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Session - Session manager plugin for the Nile framework.

=head1 SYNOPSIS
    
    use DateTime;

    # plugin session must be set to autoload in config.xml
    
    # save current username to session
    if (!$app->session->{username}) {
        $app->session->{username} = $username;
    }

    # get current username from session
    $username = $app->session->{username};
    
    # save time of the user first visit to session
    if (!$app->session->{first_visit}) {
        $app->session->{first_visit} = time;
    }

    my $dt = DateTime->from_epoch(epoch => $app->session->{first_visit});
    $view->set("first_visit", $dt->strftime("%a, %d %b %Y %H:%M:%S"));
        
=head1 DESCRIPTION
    
Nile::Plugin::Session - Session manager plugin for the Nile framework.

Plugin settings in th config file under C<plugin> section. The C<autoload> variable is must be set to true value for the plugin to be loaded
on application startup to setup hooks to work before actions dispatch.

This plugin uses the cache module L<CHI> for saving sessions. All drivers supported by the L<CHI> module are supported by this plugin.

    <plugin>

        <session>
            <autoload>1</autoload>
            <key>nile_session_key</key>
            <expire>1 year</expire>
            <cache>
                <driver>File</driver>
                <root_dir></root_dir>
                <namespace>session</namespace>
            </cache>
            <cookie>
                <path>/</path>
                <secure></secure>
                <domain></domain>
                <httponly></httponly>
            </cookie>
        </session>

    </plugin>

For DBI driver configuration example:

            <driver>
                <driver>DBI</driver>
                <namespace>session</namespace>
                <table_prefix>cache_</table_prefix>
                <create_table>1</create_table>
            </driver>

The DBI create table example:

    CREATE TABLE <table_prefix><namespace> (
       `key` VARCHAR(...),
       `value` TEXT,
       PRIMARY KEY (`key`)
    )

The driver will try to create the table if you set C<create_table> in the config and table does not exist.

=cut

use Nile::Plugin; # also extends Nile::Plugin

use CHI;
use Digest::SHA;
use Time::HiRes ();
use Time::Duration::Parse;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 cache()
    
    $app->plugin->session->cache();

Returns the L<CHI> cache object instance used by the session. All L<CHI> methods can be accessed through this method.

=head2 get set compute remove expire is_valid add replace append clear purge get_keys exists_and_is_expired
    
    $app->plugin->session->set($key, $data, "10 minutes");

    # same as

    $app->plugin->session->cache->set($key, $data, "10 minutes");

These methods are a proxy to the L<CHI> cache object methods. See L<CHI> for details about these methods.

=cut

has 'cache' => (
      is      => 'rw',
      lazy  => 1,
      #isa  => "CHI",
      default => undef,
      handles => [qw(get set compute remove expire is_valid add replace append clear purge get_keys exists_and_is_expired)],
  );

=head2 id()
    
    $id = $app->plugin->session->id();
    $app->plugin->session->id($id);

Returns or sets the current session id. Session id's are auto generated.

=cut

has 'id' => (
      is      => 'rw',
      lazy  => 1,
      default => undef
  );

=head2 sha_bits()
    
    $bits = $app->plugin->session->sha_bits();
    
    # bits: 1= 40 bytes, 256=64 bytes, 512=128 bytes, 512224, 512256 

    $bits = 1;
    $app->plugin->session->sha_bits($bits);

Returns or sets the current session id generator L<Digest::SHA> sha_bits.

=cut

has 'sha_bits' => (
      is      => 'rw',
      lazy  => 1,
      default => 1, # bits: 1= 40 bytes, 256=64 bytes, 512=128 bytes, 512224, 512256 
  );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub main { # our sub new {}

    my ($self, $arg) = @_;
    
    my $app = $self->app;
    my $setting = $self->setting();

    my $driver = $setting->{cache} || +{};

    $setting->{key} ||= "nile_session_key";
    $setting->{sha_bits} ||= 1;
    $setting->{expire} ||= "1 year";

    $setting->{cookie}->{path} ||= "/";
    $setting->{cookie}->{domain} ||= "";
    $setting->{cookie}->{secure} ||= "";
    $setting->{cookie}->{httponly} ||= "";
    
    # convert human readable time to seconds
    $setting->{expire} = parse_duration($setting->{expire});

    $self->sha_bits($setting->{sha_bits});

    $driver->{driver} ||= "File";
    $driver->{namespace} ||= "session"; # default namespace is Default

    if (!$driver->{root_dir}) {
        $driver->{root_dir} = $app->file->catdir($app->var->get("cache_dir"), $driver->{namespace});
    }

    if ($driver->{driver} eq "DBI") {
        $driver->{dbh} = $app->dbh();
    }

    if (!$self->cache) {
        $self->cache(CHI->new(%{$driver}));
    }

    # load session data after loading request
    $app->hook->after_request(sub {
        my ($me, @args) = @_;
        #say "key: " . $app->request->cookie($setting->{key});
        $self->id($app->request->cookie($setting->{key}) || $app->request->param($setting->{key}) || undef);
        
        if ($self->id) {
            $app->session($self->cache->get($self->id) || +{});
        }
        else {
            $app->session(+{});
        }

        #$app->dump($app->session);
    });
    
    # save session data, write session headers etc
    $app->hook->before_response(sub {
        my ($me, @args) = @_;
        
        #$cache->set( $name, $customer, "10 minutes" );
        # do not save empty sessions;
        return if (!$app->session);
        
        # create new session and save it
        if (!$self->id()) {
            $self->id($self->new_id());
            $self->cache->set($self->id(), +{});

            $app->response->cookies->{$setting->{key}} = {
                value => $self->id(),
                expires => time + $setting->{expire},
                path  => $setting->{cookie}->{path},
                domain  => $setting->{cookie}->{domain},
                secure  => $setting->{cookie}->{secure},
                httponly  => $setting->{cookie}->{httponly},
            };
        }

        $self->cache->set($self->id, $app->session, $setting->{expire});
    });

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new_id {
    my ($self) = @_;
    my ($sec, $ms) = Time::HiRes::gettimeofday;
    my $rand = sprintf("%.f", $$ * (+{}) * $ms * rand());
    # bits: 1= 40 bytes, 256=64 bytes, 512=128 bytes, 512224, 512256 
    return Digest::SHA->new($self->sha_bits())->add($rand)->hexdigest();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
