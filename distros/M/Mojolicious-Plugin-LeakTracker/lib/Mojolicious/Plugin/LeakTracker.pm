use strict;
use warnings;
package Mojolicious::Plugin::LeakTracker;
{
  $Mojolicious::Plugin::LeakTracker::VERSION = '1.00';
}
# ABSTRACT: Helps you track down memory leaks in your code
use Mojo::Base 'Mojolicious::Plugin';

use Devel::Events::Filter::Stamp;
use Devel::Events::Filter::RemoveFields;
use Devel::Events::Filter::Stringify;

use Devel::Events::Handler::Log::Memory;
use Devel::Events::Handler::Multiplex;
use Devel::Events::Handler::ObjectTracker;
use Devel::Events::Generator::Objects;

use Devel::Cycle ();
use Devel::Size ();
use Data::Dumper ();

sub register {
    my $self = shift;
    my $app  = shift;
    my $_args = shift || {};
    my %args = ( loglevel => undef, ignore_mode => 0, %{$_args} );

    # if app is in production mode and ignore_mode is not 1, bail out
    if($app->mode eq 'production' && $args{'ignore_mode'} < 1) {
        $app->log->info('Not enabling LeakTracker plugin, you are in production mode!');
        return 0;
    }

    my $loglevel = $args{'loglevel'} || ($app->mode eq 'production') ? 'info' : 'debug'; # yes, bad
    $app->attr(lt_loglevel => sub { $loglevel });

    $app->attr($_ => undef) for(qw/devel_events_log devel_events_multiplexer devel_events_filters devel_events_generator/);

    $app->helper(lt_log => sub {
        my $self = shift;
        my $l = $app->lt_loglevel;

        $app->log->$l(sprintf('[LeakTracker] [%d]: %s', $$, join(' ', @_)));
    });

    $app->helper(create_devel_events_object_tracker => sub {
        return Devel::Events::Handler::ObjectTracker->new();
    });

    my $log          = $self->create_devel_events_log;
    my $filtered_log = $self->create_devel_events_log_filter($log);
    my $multiplexer  = $self->create_devel_events_multiplexer;
    my $filters      = $self->create_devel_events_filter_chain($multiplexer);
    my $generator    = $self->create_devel_events_objects_event_generator($filters);

    $app->devel_events_log($log);
    $app->devel_events_multiplexer($multiplexer);
    $app->devel_events_filters($filters);
    $app->devel_events_generator($generator);

    $app->hook(after_build_tx => sub {
        my ($tx, $app) = (@_);

        $tx->on(request => sub {
            my $tx = shift;

            my $tracker = $app->create_devel_events_object_tracker;
            $tx->{lt_tracker} = $tracker;
            $app->devel_events_multiplexer->add_handler($tracker);

            my $generator = $app->devel_events_generator;
            $tx->{lt_generator} = $generator;
            $generator->enable;
        });

        $tx->on(finish => sub {
            my $tx = shift;

            my $generator = $tx->{lt_generator};
            $generator->disable;

            my $tracker = $tx->{lt_tracker};
            if(my $n_leaked = scalar(keys(%{$tracker->live_objects}))) {
                $self->dump_leak_info($app => $tx->{lt_tracker});
            }
        });
    });
}

sub dump_leak_info {
    my $self = shift;
    my $app  = shift;
    my $tracker = shift;

    my $live_objects = $tracker->live_objects;
    my @leaks = map {
        my $object = $_->{object};

        +{
            %$_,
            size => Devel::Size::total_size($object),
            class => ref $object,
        }
    } values %$live_objects;

    $app->lt_log('Request finished with ', scalar(keys(%$live_objects)), ' live objects');

    foreach my $leak (@leaks) {
        $self->dump_single_leak($app => $leak);
    }
}

sub dump_single_leak {
    my $self = shift;
    my $app  = shift;
    my $leak = shift;

    my $obj = $leak->{object};
    my $cycles = $self->_cycle_report($obj);

    $app->lt_log(sprintf("class: %s\n\tsize: %d\n\tfile: %s\n\tline: %d\n\tpackage: %s\n\tCycle report:\n\t\t%s", $leak->{class}, $leak->{size}, $leak->{file}, $leak->{line}, $leak->{package}, $cycles));
}

my %shortnames;
my $new_shortname = "A";

sub _ref_shortname {
    my $ref = shift;
    my $refstr = "$ref";
    my $refdisp = $shortnames{ $refstr };
    if ( !$refdisp ) {
        my $sigil = ref($ref) . " ";
        $sigil = '%' if $sigil eq "HASH ";
        $sigil = '@' if $sigil eq "ARRAY ";
        $sigil = '$' if $sigil eq "REF ";
        $sigil = '&' if $sigil eq "CODE ";
        $refdisp = $shortnames{ $refstr } = $sigil . $new_shortname++;
    }

    return $refdisp;
}

sub _cycle_report {
    my ( $self, $obj ) = @_;

    my @diags;
    my $cycle_no;

    # Callback function that is called once for each memory cycle found.
    my $callback = sub {
        my $path = shift;
        $cycle_no++;
        push( @diags, "Cycle #$cycle_no" );
        foreach (@$path) {
            my ($type,$index,$ref,$value) = @$_;

            my $str = 'Unknown! This should never happen!';
            my $refdisp = _ref_shortname( $ref );
            my $valuedisp = _ref_shortname( $value );

            $str = sprintf( '    %s => %s', $refdisp, $valuedisp )               if $type eq 'SCALAR';
            $str = sprintf( '    %s => %s', "${refdisp}->[$index]", $valuedisp ) if $type eq 'ARRAY';
            $str = sprintf( '    %s => %s', "${refdisp}->{$index}", $valuedisp ) if $type eq 'HASH';
            $str = sprintf( '    closure %s => %s', "${refdisp}, $index", $valuedisp ) if $type eq 'CODE';

            push( @diags, $str );
        }
    };

    Devel::Cycle::find_cycle( $obj, $callback );

    return (wantarray) ? @diags : join("\n", @diags);
}

###
##  utility stuff below
#

sub create_devel_events_log {
    return Devel::Events::Handler::Log::Memory->new();
}

sub create_devel_events_log_filter {
    my $self = shift;
    my $log  = shift;

    return Devel::Events::Filter::Stringify->new(handler => $log);
}

sub create_devel_events_multiplexer {
    return Devel::Events::Handler::Multiplex->new();
}

sub create_devel_events_objects_event_generator {
    my $self = shift;
    my $filters = shift;

    return Devel::Events::Generator::Objects->new(handler => $filters);
}

sub create_devel_events_filter_chain {
    my $self = shift;
    my $multiplexer = shift;

    return Devel::Events::Filter::Stamp->new(
        handler => Devel::Events::Filter::RemoveFields->new(
            fields => [qw/generator/],
            handler => $multiplexer,
        )
    );
}




1;


=pod

=head1 NAME

Mojolicious::Plugin::LeakTracker - Helps you track down memory leaks in your code

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    $app->plugin('leak_tracker', \%options);

=head1 NAME

Mojolicious::Plugin::LeakTracker - Helps you track down memory leaks and circular references in your Mojolicious app    

=head1 PLUGIN OPTIONS

=head2 ignore_mode

When this is set to a true value, modes are ignored. By default the plugin will not install it's hooks or set up the tracking environment if you are in production mode. Setting ignore_mode to a true value will make the plugin run in production mode regardless.

=head2 loglevel

Can be set to any valid log method name applicable to $app->log (e.g. debug to log using $app->log->debug). By default set to 'debug' for development mode, and 'info' for production mode. Here as a way to override the default behaviour.

=head1 INTERPRETING THE RESULTS

At the beginning of each transaction (the C<after_build_tx> hook), an event handler is attached to the C<request> and C<finish> events that the transaction emits. Tracking of leaks is done between these two stages. 

If a transaction finishes, and there are still live objects present, this is reported in the app log. Each live object's class, package, file, and size are dumped, as well as a cycle report; the cycle report lists circular references. 

Note that this plugin is not a magic CSI bullet that will point you straight to the source of a leak, but it is a way to get a better idea of where to look and what may potentially be causing them. 

=head1 KNOWN ISSUES

=over 4

=item * This plugin was smacked together in a hurry, and has a lot of dead/loose/useless code floating around in it.

=item * Cyclic references may be falsely reported for modules that implement their own cyclic-reference-busting logic for when they are destroyed; also things like caching, and lazy-loaded objects may cause a false report.

=back

=head1 AUTHOR 

Ben van Staveren C<<madcat@cpan.org>>

=head1 BUG REPORTING/CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/benvanstaveren/Mojolicious-Plugin-LeakTracker/issues>. 
You can fork my Git repository at L<https://github.com/benvanstaveren/Mojolicious-Plugin-LeakTracker/> if you want to make changes or supply me with patches.

=head1 ACKNOWLEDGMENTS

Based in part on L<Catalyst::Plugin::LeakTracker>, with some additional beating to make it fit Mojolicious' request handling. 

=head1 AUTHOR

Ben van Staveren <madcat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ben van Staveren.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
