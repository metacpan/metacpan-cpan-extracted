package Mojolicious::Plugin::BootstrapAlerts;

# ABSTRACT: Bootstrap alerts for your web app

use strict;
use warnings;

use parent 'Mojolicious::Plugin';

use Mojo::ByteStream;

our $VERSION = 0.06;

sub register {
    my ($self, $app, $config) = @_;

    my $dismissable = !( $config && exists $config->{dismissable} && $config->{dismissable} == 0 );

    $app->helper( notify => sub {
        my $c = shift;
        push @{ $c->stash->{__NOTIFICATIONS__} }, [ @_ ];
    } );

    $app->helper( notifications => sub {
        my $c                    = shift;
        my $notifications_config = shift;

        my $output = '';

        for my $notification ( @{ $c->stash('__NOTIFICATIONS__') || [] } ) {
            my ($type, $message, $config) = @{ $notification };

            my ($dismissable_class, $dismissable_button) = ("","");
            if ( $config->{dismissable} || (!exists $config->{dismissable} && $dismissable) ) {
                $dismissable_class  = 'alert-dismissable';
                $dismissable_button = '<button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>';
            }

            if ( ref $message and ref $message eq 'ARRAY' ) {
                my $items     = join '', map{ "<li>$_</li>" }@{ $message };
                my $list_type = $config->{ordered_list} ? 'ol' : 'ul';

                $message = "<$list_type>$items</$list_type>";
            }

            $type = 'danger' if $type eq 'error';

            $output .= qq~
                <div class="alert $dismissable_class alert-$type">
                    $dismissable_button
                    $message
                </div>
            ~;
        }

        return Mojo::ByteStream->new( $output );
    } );

    if ( $config && $config->{auto_inject} && ($config->{before} || $config->{after}) ) {
        $app->hook( after_render => sub {
            my ($c, $content, $format) = @_;

            return if $format ne 'html';

            my $notifications = $c->notifications->to_string;

            return if !$notifications;

            my $dom           = Mojo::DOM->new( ${$content} );
            my $selector      = $config->{before} || $config->{after};
            my $element       = $dom->at( $selector );

            if ( !$element ) {
                $c->app->log->debug( 'no matching element found (' . $selector . ')' );
                return;
            }

            my @elems         = $config->{before} ? ($notifications, "$element") : ("$element", $notifications);
            my $replacement   = sprintf "%s%s", @elems;
            my $temp          = "$element";

            ${$content}       =~ s/\Q$temp\E/$replacement/;
        });
    }
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::BootstrapAlerts - Bootstrap alerts for your web app

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your C<startup>:

    sub startup {
        my $self = shift;
  
        # do some Mojolicious stuff
        $self->plugin( 'BootstrapAlerts' );

        # more Mojolicious stuff
    }

In your controller:

    $self->notify( 'success', 'message' );
    $self->notify( 'danger', [qw/item1 item2/] );

In your template:

    <%= notifications() %>

=head1 HELPERS

This plugin adds two helper methods to your web application:

=head2 notify

Add a new notification. The first parameter is the notification type, one of these

=over 4

=item * success

=item * info

=item * warning

=item * danger (alias: error)

=back

The second parameter is the notification message. If it is a plain string, that's the message. If
the parameter is an array reference an unordered list will be created.

A third parameter is optional. That is a hashreference to configure the notification:

    # this notification is not dismissable
    $self->notify( 'success', 'message', { dismissable => 0 } );

    # this notification has an ordered list
    $self->notify( 'danger', [qw/item1 item2/], { ordered_list => 1 } );

=head2 notifications

Creates the HTML for the notifications. The C<notifications> call in the SYNOPSIS will create

    <div class="alert alert-success alert-dismissable">
      <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
      message
    </div>
    <div class="alert alert-danger alert-dismissable">
      <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
      <ul>
          <li>item1</li>
          <li>item2</li>
      </ul>
    </div>

=head1 METHODS

=head2 register

Called when registering the plugin. On creation, the plugin accepts a hashref to configure the plugin.

    # load plugin, alerts are dismissable by default
    $self->plugin( 'BootstrapAlerts' );

=head3 Configuration

    $self->plugin( 'BootstrapAlerts' => {
        dismissable => 0,          # notifications aren't dismissable by default anymore
        auto_inject => 1,          # inject notifications into your HTML output, no need for "notifications()" anymore
        after       => $selector,  # CSS selector to find the element after that the notifications should be injected
        before      => $selector,  # CSS selector to find the element before that the notifications should be injected
    });

=head1 NOTES

You have to include the Bootstrap CSS and JavaScript yourself!

This plugin uses the I<stash> key C<__NOTIFICATIONS__>, so you should avoid using
this stash key for your own purposes.

=head2 Known Issues

C<Mojo::DOM> I<html_unescapes> HTML entities when the HTML is parsed. So the injection might fail if you have
a HTML entity in the element before/after that the notifications are injected.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
