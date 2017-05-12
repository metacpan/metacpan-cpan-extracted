package OpenPlugin::Utility;

# $Id: Utility.pm,v 1.7 2003/04/03 01:51:24 andreychek Exp $

use strict;

$OpenPlugin::Utility::VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);
use Digest::MD5();

# Given an expiration in one of various formats, convert it to seconds
# This code was inspired by, and largely taken from, CGI.pm

# The format for expire can be in any of the forms...
# "now" -- expire immediately
# "+180s" -- in 180 seconds
# "+2m" -- in 2 minutes
# "+12h" -- in 12 hours
# "+1d"  -- in 1 day
# "+3M"  -- in 3 months
# "+2y"  -- in 2 years
# "-3m"  -- 3 minutes ago(!)
# You may also sent in an exact time in seconds.  Anything else is
# considered invalid.
sub expire_calc {
    my ( $self, $expire, $time ) = @_;

    $time ||= time;

    my ( %mult ) = ('s'=>1,
                    'm'=>60,
                    'h'=>60*60,
                    'd'=>60*60*24,
                    'M'=>60*60*24*30,
                    'y'=>60*60*24*365);

    my ( $offset );

    if (lc( $expire ) eq 'now') {
        $offset = 0;
    }
    elsif ( $expire =~ /^\d+/ ) {
        return $expire;
    }
    elsif ( $expire =~ /^([+-]?(?:\d+|\d*\.\d*))([mhdMy]?)/ ) {
        $offset = ($mult{$2} || 1) * $1;
    }
    else {
        return 0;
    }

    return ( $time + $offset );
}

# Generate a random id
# Not perfect, but it'll give us reasonable ID's
sub generate_rand_id {
    my ( $self, $length ) = @_;

    $length ||= '32';

    return substr(Digest::MD5::md5_hex(Digest::MD5::md5_hex(time(). {}. rand(). $$)), 0, $length);

}

1;

__END__

=pod

=head1 NAME

OpenPlugin::Utility - Utility methods for OpenPlugin objects

=head1 SYNOPSIS

=head1 DESCRIPTION

This class contains utility methods which can be used from OpenPlugin
objects or from OpenPlugin classes.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut

