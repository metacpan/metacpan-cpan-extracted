# $Id: Archive.pm 1306 2003-08-11 09:24:32Z richardc $
package Siesta::Plugin::Archive;
use strict;
use Siesta::Config;
use Siesta::Plugin;
use base 'Siesta::Plugin';
use Email::LocalDelivery;

sub description {
    "save a copy of the message to an archive."
}

sub process {
    my $self = shift;
    my $mail = shift;

    my $path = $self->pref('path');
    Email::LocalDelivery->deliver( $mail->as_string, $path )
        or die "local delivery into '$path' failed";
    return;
}

sub options {
    my $self = shift;
    my $name = $self->list->name;

    +{
        path => {
            description => "where to drop the archives",
            type        => "string",
            default     => "$Siesta::Config::ARCHIVE/$name/",
        },
    };
}

1;
