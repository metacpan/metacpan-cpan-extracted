#
# This file is part of Test-Corpus-Audio-MPD
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Test::Corpus::Audio::MPD;
{
  $Test::Corpus::Audio::MPD::VERSION = '1.120990';
}
# ABSTRACT: automate launching of fake mdp for testing purposes

use File::Copy                qw{ copy     };
use File::ShareDir::PathClass qw{ dist_dir };
use File::Temp                qw{ tempdir  };
use Path::Class;
use Readonly;

use base qw{ Exporter };
our @EXPORT = qw{
    customize_test_mpd_configuration
    playlist_dir
    start_test_mpd stop_test_mpd
};

Readonly my $SHAREDIR    => dist_dir('Test-Corpus-Audio-MPD');
Readonly my $TEMPLATE    => $SHAREDIR->file( 'mpd.conf.template' );
Readonly my $TMPDIR      => dir( tempdir( CLEANUP=>1 ) );
Readonly my $CONFIG      => $TMPDIR->file( 'mpd.conf' );
Readonly my $PLAYLISTDIR => $TMPDIR->subdir( 'playlists' );


{ # this will be run when module will be use-d

    # check if mpd (the real music player daemon, not freebsd's
    # multilink ppp daemon
    my $output = qx{ mpd --version 2>&1 } or die "mpd not installed";
    die "installed mpd is not music player daemon"
        unless $output =~ /Music Player Daemon/;

    my $restart = 0;
    my $stopit  = 0;

    $restart = _stop_user_mpd_if_needed();
    customize_test_mpd_configuration();
    $stopit  = start_test_mpd();

    END {
        stop_test_mpd() if $stopit;
        return unless $restart;       # no need to restart
        system 'mpd 2>/dev/null';     # restart user mpd
        sleep 1;                      # wait 1 second to let mpd start.
    }
}


# -- public subs


sub customize_test_mpd_configuration {
    my ($port) = @_;
    $port ||= 6600;

    # open template and config.
    open my $in,  '<',  $TEMPLATE or die "can't open [$TEMPLATE]: $!";
    open my $out, '>',  $CONFIG   or die "can't open [$CONFIG]: $!";

    # replace string and fill in config file.
    while ( defined( my $line = <$in> ) ) {
        $line =~ s!PWD!$SHAREDIR!;
        $line =~ s!TMP!$TMPDIR!;
        $line =~ s!PORT!$port!;
        print $out $line;
    }

    # clean up.
    close $in;
    close $out;

    # copy the playlists. playlist need to be in a writable directory,
    # since tests will create and remove some playlists.
    $PLAYLISTDIR->mkpath;
    copy( glob("$SHAREDIR/playlists/*"), $PLAYLISTDIR );
}



sub playlist_dir { $PLAYLISTDIR }



sub start_test_mpd {
    my $output = qx{ mpd $CONFIG 2>&1 };
    my $rv = $? >>8;
    die "could not start fake mpd: $output\n" if $rv;
    sleep 1;   # wait 1 second to let mpd start.
    return 1;
}



sub stop_test_mpd {
    system "mpd --kill $CONFIG 2>/dev/null";
    sleep 1;   # wait 1 second to free output device.
    unlink "$TMPDIR/state", "$TMPDIR/music.db";
}


# -- private subs

#
# my $was_running = _stop_user_mpd_if_needed()
#
# This sub will check if mpd is currently running. If it is, force it to
# a full stop (unless MPD_TEST_OVERRIDE is not set).
#
# In any case, it will return a boolean stating whether mpd was running
# before forcing stop.
#
sub _stop_user_mpd_if_needed {
    # check if mpd is running.
    my $is_running = grep { /\s+mpd$/ } qx{ ps -e };

    return 0 unless $is_running; # mpd does not run - nothing to do.

    # check force stop.
    die "mpd is running\n" unless $ENV{MPD_TEST_OVERRIDE};
    system( 'mpd --kill 2>/dev/null') == 0 or die "can't stop user mpd: $?\n";
    sleep 1;  # wait 1 second to free output device
    return 1;
}


1;


=pod

=head1 NAME

Test::Corpus::Audio::MPD - automate launching of fake mdp for testing purposes

=head1 VERSION

version 1.120990

=head1 SYNOPSIS

    use Test::Corpus::Audio::MPD; # die if error
    [...]
    stop_test_mpd();

=head1 DESCRIPTION

This module will try to launch a new mpd server for testing purposes.
This mpd server will then be used during L<POE::Component::Client::MPD>
or L<Audio::MPD> tests.

In order to achieve this, the module will create a fake F<mpd.conf> file
with the correct pathes (ie, where you untarred the module tarball). It
will then check if some mpd server is already running, and stop it if
the C<MPD_TEST_OVERRIDE> environment variable is true (die otherwise).
Last it will run the test mpd with its newly created configuration file.

Everything described above is done automatically when the module
is C<use>-d.

Once the tests are run, the mpd server will be shut down, and the
original one will be relaunched (if there was one).

Note that the test mpd will listen to C<localhost>, so you are on the
safe side. Note also that the test suite comes with its own ogg files.
Those files are 2 seconds tracks recording my voice saying ok, and are
freely redistributable under the same license as the code itself.

In case you want more control on the test mpd server, you can use the
supplied public methods. This might be useful when trying to test
connections with mpd server.

=head1 METHODS

=head2 customize_test_mpd_configuration( [$port] );

Create a fake mpd configuration file, based on the file
F<mpd.conf.template> located in F<share> subdir. The string PWD will be
replaced by the real path (ie, where the tarball has been untarred),
while TMP will be replaced by a new temp directory. The string PORT will
be replaced by C<$port> if specified, 6600 otherwise (MPD's default).

=head2 my $dir = playlist_dir();

Return the temp dir where the test playlists will be stored.

=head2 start_test_mpd();

Start the fake mpd, and die if there were any error.

=head2 stop_test_mpd();

Kill the fake mpd.

=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Corpus-Audio-MPD>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Corpus-Audio-MPD>

=item * Mailing-list (same as L<Audio::MPD>)

L<http://groups.google.com/group/audio-mpd>

=item * Git repository

L<http://github.com/jquelin/test-corpus-audio-mpd>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Corpus-Audio-MPD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Corpus-Audio-MPD>

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

