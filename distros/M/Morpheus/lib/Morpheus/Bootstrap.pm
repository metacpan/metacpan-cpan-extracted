package Morpheus::Bootstrap;
{
  $Morpheus::Bootstrap::VERSION = '0.46';
}
use strict;
use warnings;

# ABSTRACT: initial morpheus plugin which loads all other plugins


use Morpheus::Plugin::Simple;

our $BOOTSTRAP_PATH;
$BOOTSTRAP_PATH = [@INC];
@$BOOTSTRAP_PATH = split /[\s:]+/, $ENV{MORPHEUS_BOOTSTRAP_PATH} if defined $ENV{MORPHEUS_BOOTSTRAP_PATH};

sub import {
    my $class = shift;
    while (@_) {
        my $cmd = shift;
        if ($cmd eq '-path') {
            push @$BOOTSTRAP_PATH, @{(shift)};
        } else {
            die "unexpected option '$cmd'";
        }
    }
}

sub new {

    my $this = {
        priority => 200,
    };

    my $that = Morpheus::Plugin::Simple->new(sub {

        my $loaded = {};

        for my $path (@$BOOTSTRAP_PATH) {
            for my $file (glob "$path/Morpheus/Bootstrap/*.pm") {
                $file =~ m{/([^/]+)\.pm$} or die;
                my $name = "Bootstrap::$1";
                next if $loaded->{$name};
                require $file;
                my $object = "Morpheus::$name";
                $object = $object->new() if $object->can('new');
                $loaded->{$name} = {
                    priority => 300,
                    object => $object,
                };
            }
        }

        return {
            "morpheus" => {
                "plugins" => {
    
                    Bootstrap => $this,

                    %$loaded,
                }
            }
        };
    });

    $this->{object} = $that; #FIXME: weaken?

    return $that;
}

1;

__END__
=pod

=head1 NAME

Morpheus::Bootstrap - initial morpheus plugin which loads all other plugins

=head1 VERSION

version 0.46

=head1 Meta Configuration and Bootstrapping

Morpheus uses a set of plugins to retrieve the values of configuration variables from different sources like configuration files, database, environment and so on. The configuration of those plugins, their priorities and the list of them itself is called "meta configuration". It is applied within a "bootstrapping" procedure that starts at the very first call to Morpheus and after the bootstrapping is over the list of plugins may not be altered. Though you are able to reconfigure plugins objects after that it is not adviced either.

Meta plugins that provide meta configuration are called "bootstrappers", technically they are just like ordinary plugins but the configuration data they provide is inside a "/morpheus/plugins" namespace. It is expected that "/morpheus/plugins/*/object" configuration key would refer to plugin object, and "/morpheus/plugins/*/priority" would be its priority. Here "*" stands for the "name" of the plugin, that is used in debug or error messages, also this name is important when one bootstrapper is overriding the meta configuration provided by another one.

=head2 Adding your own plugins, reconfiguring or disabling default plugins

In order to add your own plugin into a set of plugins you may simply add some code into one of the existing bootstrappers. That code should properly initialize your plugin and bind it to "/morpheus/plugins/*" under the name and priority you choose. In the same way you may alter the configuration of existing plugins or completely disable them, just edit the code of the bootstrapper that defines those plugins. There are some bootstrappers provided by the default Morpheus installation. It is not recommended to modify the Morpheus::Bootstrap::Vital bootstrapper, but Morpheus::Bootstrap::Extra fits fine. See its code to get a clue of how to program a bootstrapper.

There exists a less simple but ideologically maybe a better way to update meta configuration, see L</"Advanced techniques"> section for details.

=head2 Advanced Techniques

Here goes a detailed description of bootstrapping process required for understanding the tricks described below. Bootstrapping begins with a single bootstrapper named L<Morpheus::Bootstrap>, that is a level 0 bootstrapper. It looks through perl C<@INC> path and loads all the C<Morpheus::Bootstrap::*> packages it finds, then it adds them to the set of plugins ("/morpheus/plugins/*") under the names of the corresponding packages Bootstrap::*, these are level 1 bootstrappers. There are two of them in default Morpheus installation, L<Morpheus::Bootstrap::Vital> bootstrapper that enables L<Morpheus::Defaults> and L<Morpheus::Overrides> plugins, and L<Morpheus::Bootstrap::Extra> bootstrapper that adds L<Morpheus::Plugin::File> (with some default configuration) and L<Morpheus::Plugin::Env> plugins. Normally level 1 bootstrappers introduce only non meta plugins, so the bootstrapping finishes at that point. But in general case level 1 bootstrappers may add some level 2 bootstrappers to the list of the plugins and so on. Also some bootstrappers may override configuration made by other bootstrappers, for example change some plugin priority, but much more devastating overrides are possible, including disabling of one bootstrapper by another one. So Morpheus iterates over and over until plugins set stabilizes or an iteration limit is reached leading to an exception.

Being based on the Morpheus itself meta configuration is flexible enough to allow one bootstrapper override the meta configuration provided by another bootstrapper. So you never actually have to edit any bootstrapper, you can always add a new one and achieve the same result. To add a new plugin to the list of plugin you may write your own bootstrapper instead of modifying L<Morpheus::Bootstrap::Extra>, doing so you prevent the risk to lose your modification made to L<Morpheus::Bootstrap::Extra> when updating Morpheus. And also it allows you to enable your plugin conditionally by using C<-I> perlrun option or C<PERL5LIB> environment variable if you put your bootstrapper into a separate directory not included into C<@INC> by default.

Modifying other bootstrapper definitions is slightly more complicated. First of all you need to boost your bootsrapper priority to take advantage over a bootsrapper you would want to override. Non meta plugin normally have priorities below 100, priority 0 plugins are considered disabled. The level 0 bootstrapper L<Morpheus::Bootstrap> has the priority of 200, and the level 1 bootsrappers it defines get the priority of 300. So anything over 300 will be enough to overcome them. After your bootstrapper priority is increased, the definitions it provides override ones of lower priority bootstrappers.

Consider an example:

    # A bootstrapper B1 enables plugins P1 and P2.
    package Morpheus::Bootstrap::B1;
    use Morpheus::Plugin::P1;
    use Morpheus::Plugin::P2;
    use Morpheus::Plugin::Simple;

    sub new {
        return Morpheus::Plugin::Simple->new({
            "morpheus/plugins" => {
                "P1" => {
                    object => Morpheus::Plugin::P1->new(),
                    priority => 42,
                },
                "P2" => {
                    object => Morpheus::Plugin::P2->new(foo => "bar"),
                    priority => 69,
                },

            }
        });
    }

    1;

    # A bootstrapper B2 overrides B1. It lowers P1's priority and changes its construtor parameters. Also it completely disables P2.
    package Morpheus::Bootstrap::B2;
    use Morpheus::Plugin::P1;
    use Morpheus::Plugin::Simple;

    sub new {
        return Morpheus::Plugin::Simple->new({
            "morpheus/plugins" => {
                "Bootstrap::B2" => {
                    priority => 400, # boost myself
                },
                "P1" => {
                    object => Morpheus::Plugin::P1->new(bar => "baz"),
                    priority => 25,
                },
                "P2" => {
                    priority => 0,
                },

            }
        });
    }

    1;

    # A bootstrapper B3 overrides bootstrapper B2 and completely disables it. So if all three B1, B2 and B3 are in @INC then B1's definitions will be used as B2's overrides are disabled.
    package Morpheus::Bootstrap::B3;
    use Morpheus::Plugin::Simple;

    sub new {
        return Morpheus::Plugin::Simple->new({
            "morpheus/plugins" => {
                "Bootstrap::B3" => {
                    priority => 500, # we need something over 400
                },
                "Bootstrap::B2" => {
                    priority => 0, # disable B2
                },
            }
        });
    }

    1;

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

