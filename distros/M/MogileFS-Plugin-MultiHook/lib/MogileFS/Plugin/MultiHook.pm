package MogileFS::Plugin::MultiHook;

use strict;
use warnings;

use MogileFS::Server;

=head1 NAME

MogileFS::Plugin::MultiHook - MogileFS plugins for using multiple hooks

=head1 VERSION

version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

In the mogilefsd config, 

  plugins = MultiHook Foo

In "MogileFS::Plugin::Foo" plugin,

  MogileFS::register_global_hook("cmd_create_open", sub { Mgd::log("info", "begin cmd_create_open") });
  ### Some process
  MogileFS::register_global_hook("cmd_create_open", sub { Mgd::log("info", "end cmd_create_open") });

=head1 DESCRIPTION

This module is plugin for L<MogileFS::Server> to register and use multiple hooks.
For using this plugin, you should set plugin name at head of plugins, such as:

  plugins = MultiHook FilePaths

When this module is loaded, MogileFS::register_global_hook() and MogileFS::run_global_hook() will be replaced to what is available to register and use multiple hooks from original.
But the arguments has not changed from an original in consideration.

In addition, The register_global_hook() method simpley push a hook to the list of callbacks of each hook and
run_global_hook() method will call hooks in order of pushed.

Calling MogileFS::unregister_global_hook() will delete all of callbacks of each specified hook.

=head1 METHODS

=head2 load()

Calling by MogileFS::Config::load_config() method.

=cut

our %hooks;

sub load {
    Mgd::log("info", "MultiHook plugin load : begin") if ($MogileFS::Server::DEBUG);

    {
        no strict 'refs';
        no warnings 'redefine';

        *{"MogileFS::register_global_hook"} = sub {
            my ($hookname, $callback) = @_;

            unless (exists $MogileFS::Plugin::MultiHook::hooks{$hookname} && ref $MogileFS::Plugin::MultiHook::hooks{$hookname} eq 'ARRAY') {
                $MogileFS::Plugin::MultiHook::hooks{$hookname} = [];
            }

            push(@{$MogileFS::Plugin::MultiHook::hooks{$hookname}}, $callback);
            return 1;
        };

        *{"MogileFS::run_global_hook"} = sub {
            my ($hookname) = shift;

            return undef unless (exists $MogileFS::Plugin::MultiHook::hooks{$hookname} && ref $MogileFS::Plugin::MultiHook::hooks{$hookname} eq 'ARRAY');

            my $ret = 1;

            Mgd::log("info", "Run global hook : " . $hookname) if ($MogileFS::Server::DEBUG);

            for my $callback (@{$MogileFS::Plugin::MultiHook::hooks{$hookname}}) {
                $ret = $ret && $callback->(@_) if (defined $callback && ref $callback eq 'CODE');
            }
            return $ret;
        };

        ### for debug
        *{"MogileFS::global_hook"} = sub {
            my ($hookname) = shift;

            return \%MogileFS::Plugin::MultiHook::hooks unless ($hookname);
            return undef unless (exists $MogileFS::Plugin::MultiHook::hooks{$hookname} && ref $MogileFS::Plugin::MultiHook::hooks{$hookname} eq 'ARRAY');
            return wantarray ? @{$MogileFS::Plugin::MultiHook::hooks{$hookname}} : $MogileFS::Plugin::MultiHook::hooks{$hookname};
        };

        1;
    };

    Mgd::log("info", "MultiHook plugin load : end") if ($MogileFS::Server::DEBUG);
}

=head1 SEE ALSO

=over 4

=item L<MogileFS::Server>

=item L<MogileFS::Worker::Query>

=item L<MogileFS::Client>

=item L<MogileFS::Plugin::MetaData>

=item L<MogileFS::Plugin::FilePaths>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mogilefs-plugin-multihook@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MogileFS::Plugin::MultiHook
