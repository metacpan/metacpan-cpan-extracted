package MozRepl;

use strict;
use warnings;

use base qw(Class::Accessor::Fast Class::Data::Inheritable);

__PACKAGE__->mk_accessors($_) for (qw/client log plugins repl search/);
__PACKAGE__->mk_classdata($_) for (qw/log_class client_class/);

__PACKAGE__->log_class('MozRepl::Log');
__PACKAGE__->client_class('MozRepl::Client');

use Text::SimpleTable;
use UNIVERSAL::require;

use MozRepl::Util;

=head1 NAME

MozRepl - Perl interface of MozRepl

=head1 VERSION

version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use strict;
    use warnings;

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup; ### You must write it.

    $repl->execute(q|window.alert("Internet Explorer:<")|);

    print $repl->repl_inspect({ source => "window" });
    print $repl->repl_search({ pattern => "^getElement", source => "document"});

=head1 DESCRIPTION

MozRepl is accessing and control firefox using telnet, provided MozLab extension.
This module is perl interface of MozRepl.

Additionaly this is enable to extend by writing plugin module.
You want to write plugin, see L<MozRepl::Plugin::Base> or other plugins.

=head2 For cygwin users

In cygwin, please add binmode param as 1 in client args.

    $repl->setup({
        client => {
            extra_client_args => {
                binmode => 1
            }
        }
    });

=head1 METHODS

=head2 new($args)

Create L<MozRepl> instance.
One argument, and it must be hash reference.

=over 4

=item search

L<Module::Pluggable::Fast>'s arguments.
If you want to search modules has not prefix like 'MozRepl::Plugin', 
then you are set this value like below.

  my $repl = MozRepl->new({ search => [qw/MyRepl::Plugin OtherRepl::Plugin/] });

=back

=cut

sub new {
    my ($class, $args) = @_;

    if (exists $args->{search} && ref $args->{search} eq 'ARRAY') {
        unshift(@{$args->{search}}, "MozRepl::Plugin");
        my %seen = ();
        $args->{search} = [grep { ++$seen{$_} } @{$args->{search}}];
    }
    else {
        $args->{search} = ["MozRepl::Plugin"];
    }

    my $pluggable = "Module::Pluggable::Fast";

    my %param = (
        "require" => 1,
        "name" => "__load_plugins",
        "search" => $args->{search}
    );

    $pluggable->use(%param);

    my $self = $class->SUPER::new({
        client => undef,
        log => undef,
        repl => 'repl',
        plugins => {},
        search => $args->{search}
    });

    return $self;
}

=head2 setup($args)

Setup logging, client, plugins.
One argument, must be hash reference.

=over 4

=item log

Hash reference or undef.
See L<MozRepl/setup_log($args)>, L<MozRepl::Log/new($args)>.

=item client

Hash reference or undef.
See L<MozRepl/setup_client($args)>, L<MozRepl::Client/new($ctx, $args)>.

=item plugins

Hash reference or undef
See L<MozRepl/setup_plugins($args)>.

=back

=cut

sub setup {
    my ($self, $args) = @_;

    $self->setup_log($args->{log});
    $self->setup_client($args->{client});

    if ($self->log->is_debug) {
        my $table = Text::SimpleTable->new([15, 'type'], [60, 'module']);
        $table->row('logging', $self->log_class);
        $table->row('client', $self->client_class);
        $self->log->debug("---- Delegating classes ----\n" . $table->draw);
    }

    $self->setup_plugins($args->{plugins});
}

=head2 setup_log($args)

Create logging instance. default class is L<MozRepl::Log>.
If you want to change log class, then set class name using L<MozRepl/log_class($class)>.

This method is only called in L<MozRepl/setup($args)>.

One arguments, array reference.
If you want to limit log levels, specify levels like below.

    $repl->setup_log([qw/info warn error fatal/]);

See L<MozRepl::Log/new($args)>.


If you want to use another log class, and already instanciate it, 
then you should call and set the instance before setup() method process.

Example,

    my $repl = MozRepl->new;
    $repl->log($another_log_instance);
    $repl->setup($config);

=cut

sub setup_log {
    my ($self, $args) = @_;

    $args ||= [qw/debug info warn error fatal/];

    ### skip already exists log instance
    unless ($self->log) {
        $self->log_class->use;
        $self->log($self->log_class->new(@$args));
    }
    else {
        $self->log_class(ref $self->log);
    }

    return unless ($self->log->is_debug);

    $self->log->debug('MozRepl logging enabled');
}

=head2 setup_client($args)

Create (telnet) client instance. default class is L<MozRepl::Client>.
If you want to change client class, then set class name using L<MozRepl/client_class($class)>.

This method is only called in L<MozRepl/setup($args)>.

One arguments, hash reference.
See L<MozRepl::Client/new($ctx, $args)>.

=cut

sub setup_client {
    my ($self, $args) = @_;

    $self->client_class->use;
    $self->client($self->client_class->new($self, $args));
    $self->client->setup($self);
}

=head2 setup_plugins($args)

Setup plugins.
One argument, must be hash reference, it will be passed each plugin's as new method arguments.
And L<MozRepl/load_plugins($args)> too.

This method is only called in L<MozRepl/setup($args)>.

=cut

sub setup_plugins {
    my ($self, $args) = @_;

    $self->plugins({});

    my @plugins = $self->load_plugins($args);

    for my $plugin (@plugins) {
        $self->setup_plugin($plugin, $args);
    }
}

=head2 setup_plugin($plugin, $args)

Create plugin instance, and mixin method to self.
Method name is detect by plugin's package, see L<MozRepl::Util/plugin_to_method($plugin, $search)>.

=cut

sub setup_plugin {
    my ($self, $plugin, $args) = @_;

    return if ($self->enable_plugin($plugin));

    my $plugin_obj = $plugin->new($args);
    $plugin_obj->setup($self, $args);

    my $method = MozRepl::Util->plugin_to_method($plugin, $self->search);

    unless ($self->can($method)) {
        no strict 'refs';

        $self->log->debug('define method : ' . $method);

        *{__PACKAGE__ . "::" . $method} = sub {
            my ($repl, @args) = @_;
            $plugin_obj->execute($repl, @args);
        };
    }

    $self->plugins->{$plugin} = $plugin_obj;
}

=head2 load_plugins

Load available plugins.
One argument, must be hash reference or undef.

=over 4

=item plugins

Array reference.
Specify only plugins you want to use.

    $repl->load_plugins({ plugins => [qw/Repl::Print Repl::Inspect/] });

=item except_plugins

Array reference.
Specify except plugins you want to use.

    $repl->load_plugins({ except_plugins => [qw/JSON/] });

=back

=cut

sub load_plugins {
    my ($self, $args) = @_;

    my @available_plugins = grep { $_ ne 'MozRepl::Plugin::Base' } $self->__load_plugins;
    my %plugins = ();
    my %except_plugins = ();

    $self->log->debug(sprintf("Available plugins (%d)", scalar(@available_plugins)));

    if ($self->log->is_debug && @available_plugins) {
        my $table = Text::SimpleTable->new([80, 'Available plugin']);
        $table->row($_) for (@available_plugins);
        $self->log->debug("---- Available plugin list ----\n" . $table->draw);
    }

    return if (@available_plugins == 0);

    if ($args->{plugins} && ref $args->{plugins} eq 'ARRAY') {
        $plugins{$_} = 1 for (map { MozRepl::Util->canonical_plugin_name($_) } @{$args->{plugins}});
    }
    else {
        @plugins{@available_plugins} = map { 1 } @available_plugins;
    }

    if ($args->{except_plugins} && ref $args->{except_plugins} eq 'ARRAY') {
        $except_plugins{$_} = 1 for (map { MozRepl::Util->canonical_plugin_name($_) } @{$args->{except_plugins}});
    }

    my @plugins = 
        grep { $plugins{$_} }
        grep { !$except_plugins{$_} }
        grep { $_ ne "MozRepl::Plugin::Base" }
            @available_plugins;

    $self->log->debug(sprintf("Load plugins (%d)", scalar(@plugins)));

    if ($self->log->is_debug && @plugins) {
        my $table = Text::SimpleTable->new([80, 'Load plugin']);
        $table->row($_) for (@plugins);
        $self->log->debug("---- Load plugin list ----\n" . $table->draw);
    }

    wantarray ? @plugins : \@plugins;
}

=head2 enable_plugin($plugin)

Return whether the specified plugin is enabled or not.

=cut

sub enable_plugin {
    my ($self, $plugin) = @_;

    return ((grep { $_ eq $plugin } keys %{$self->plugins}) == 1) ? 1 : 0;
}

=head2 execute($command)

Execute command and return result string.
See L<MozRepl::Client/execute($command)>.

=cut

sub execute {
    my ($self, $command) = @_;

    $self->client->execute($self, $command);
}

=head2 finalize()

Finalize connection.

=cut

sub finalize {
    my ($self, $args) = @_;

    $self->client->quit;
}

=head2 client($client)

Accessor of client object. See L<MozRepl::Client>.

=head2 log($log)

Accessor of log object. See L<MozRepl::Log>.

=head2 plugins($plugins)

Accessor of plugin table, key is plugin class name, value is plugin instance.

=head2 repl($repl)

Accessor of "repl" object name.
If two or more connection to MozRepl, this name is added number on postfix like 'repl1'.

=head2 search($search)

Accessor of search pathes. See L<MozRepl/new($args)>.

=head2 log_class($class)

Logging class name. default value is "L<MozRepl::Log>"

=head2 client_class($class)

Client class name. default value is "L<MozRepl::Client>"

=head1 SEE ALSO

=over 4

=item L<MozRepl::Util>

=item L<MozRepl::Plugin::Base>

=item http://dev.hyperstruct.net/mozlab

=item http://dev.hyperstruct.net/mozlab/wiki/MozRepl

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl
