package Mojolicious::Plugin::SimpleSession;

use warnings;
use strict;

use base 'Mojolicious::Plugin';
use Digest;
use Storable qw/store retrieve freeze/;
use File::Spec::Functions qw/catfile tmpdir/;
use Carp qw/croak/;

my $max_time = 60 * 60;    # 1 hour


sub register {
    my ( $self, $app ) = @_;

    my $stash_key = 'session';

    $app->plugins->add_hook(
        before_dispatch => sub {
            my ( $self, $c ) = @_;

            # fetch session from cookie if it exists,
            # check for validity and load the data into
            # the data structure.

            # grab session hash from cookie, if we can.
            my $oldcookies = $c->tx->req->cookies;
            my $cookie_hash;
            foreach my $cookie (@$oldcookies) {
                if ( $cookie->name eq 'session' ) {
                    $cookie_hash = $cookie->value->to_string;
                    last;
                }
            }

            my $session_data = {};
            if ( _cookie_valid($cookie_hash) ) {
                eval {
                    $session_data = retrieve(_hash_filename($cookie_hash));
                };
                croak "Could not import session: $@" if $@;
            }

            # No cookie was given to us, or there was no file for it,
            # so create it.
            else {
                my $cookie_hash_value
                  = time() . rand(1) . $c->tx->remote_address;
                my $digester = Digest->new('SHA-1');
                $digester->add($cookie_hash_value);
                $cookie_hash = $digester->hexdigest;

                my $cookie = Mojo::Cookie::Response->new;
                $cookie->name('session');
                $cookie->path('/');
                $cookie->value($cookie_hash);
                $c->tx->res->cookies($cookie);

                # Create the disk file to match, and store a checksum in memory
                # so we can later determine if it has changed.
                delete $session_data->{_checksum};
                _dump_session( _hash_filename($cookie_hash), $session_data );
                $session_data->{_checksum} = _checksum_data($session_data);
            }

            $session_data->{cookie_hash} = $cookie_hash;
            $c->stash->{$stash_key} = $session_data;

        }
    );

    $app->plugins->add_hook(
        after_dispatch => sub {
            my ( $self, $c ) = @_;

            # Update the session data on-disk with the new
            # data from the data structure, if the data structure has
            # been changed.
            my $session_data = $c->stash->{$stash_key};

            # hash is in session data
            my $cookie_hash = $session_data->{cookie_hash};
            delete $session_data->{cookie_hash};

            my $checksum = $session_data->{_checksum} || '';
            delete $session_data->{_checksum};

            # Only store if we have changed the data.
            if ($cookie_hash && (_checksum_data($session_data) ne $checksum)) {
                $session_data->{_checksum} = _checksum_data($session_data);
                _dump_session( _hash_filename($cookie_hash), $session_data );

                # And while we are visiting the disk, clean up.
                _cull_sessions();
            }
        }
    );
}

# Calculate a checksum on some data.
sub _checksum_data {
    my $ref = shift;
    my $digester = Digest->new('SHA-1');
    $digester->add(freeze($ref));
    return $digester->hexdigest;
}

sub _cookie_valid {
    my $cookie_hash = shift;
    my $filename    = _hash_filename($cookie_hash);
    return 0 unless ( -e $filename );
    return 0 if ( _too_old( $filename ) );
    return 1;
}

sub _cull_sessions {
    my $dir = tmpdir();
    my $glob_pattern = catfile($dir, "*.ses");
    foreach my $session_file (glob $glob_pattern) {
        if (_too_old($session_file)) {
          unlink $session_file;
        }
    }
}

sub _too_old {
    my $file = shift;
    return 1 if ( ( time() - (stat($file))[8] ) > $max_time );
    return 0;
}

sub _dump_session {
    my ( $filename, $session_data ) = @_;
    my $tmp_filename = $filename . ".tmp.$$";
    store($session_data, $tmp_filename);
    rename $tmp_filename,
      $filename || croak "Could not rename $tmp_filename: $!";
}

sub _hash_filename {
    my $hash = shift;
    return catfile( tmpdir(), "$hash.ses" );
}

=head1 NAME

Mojolicious::Plugin::SimpleSession - Exceedingly Simple Mojolicious Sessions

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

In the C<handler> subroutine of your Mojolicious application, add:

    $self->plugin('simple_session');

That's it! 

Inside your application, you can now reference a hashref called 'session' in
the stash, like this:

    my $count = $self->stash->{session}->{count};

    $count++;
    $self->stash->{session}->{count} = $count;

Session data is preserved across requests for this user (identified by their
cookie).

If you need to be able to control expiry, use a database store, or basically
do anything more intelligent with your sessions, you probably want to look
at L<Mojolicious::Plugin::Session>.

=head1 FUNCTIONS

=over 4

=item register

Called by the Mojolicious framework when the plugin is registered.

=back

=head1 AUTHOR

Justin Hawkins, C<< <justin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-simplesession at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-SimpleSession>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::SimpleSession

You can also look for information at: http://hawkins.id.au/notes/perl/modules/mojolicious::plugin::simplesession

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-SimpleSession>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-SimpleSession>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-SimpleSession>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-SimpleSession/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Justin Hawkins.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Mojolicious::Plugin::SimpleSession
