package Rudesind::Handler;

use strict;

use Apache::Constants qw( DECLINED REDIRECT );
use Apache::URI;

use Rudesind;
use Rudesind::WebApp;


sub handler
{
    my $config = Rudesind::Config->new;

    my $apr = Apache::Request->new( shift,
                                    POST_MAX => $config->max_upload,
                                    TEMP_DIR => $config->temp_dir,
                                  );


    my $uri = $apr->uri;

    my $uri_root = $config->uri_root;
    $uri =~ s,^\Q$uri_root\E,,
        or return DECLINED;

    $apr->uri($uri);

    $apr->filename( $config->main_comp_root . $uri );

    # Need to set this or Mason will append it to the comp path and
    # everything gets hosed
    $apr->path_info('');

    return DECLINED if $uri =~ m{^/plain};

    my $ah = _apachehandler($config);
    my $args = $ah->request_args($apr);

    my $app = Rudesind::WebApp->new( apache_req => $apr,
                                     args       => $args,
                                   );

    return REDIRECT if $app->redirected;

    local $HTML::Mason::Commands::App = $app;

    my $return = eval { $ah->handle_request($apr) };
    my $e = $@;

    $app->clean_session;

    die $e if $e;

    return $return;
}

sub _apachehandler
{
    my $config = shift;

    my %p = ( comp_root     => $config->comp_root,
              error_mode    => $config->error_mode,
              decline_dirs  => 0,
              allow_globals => [ '$App' ],
            );

    my $data_dir = $config->data_dir;
    $p{data_dir} = $data_dir if defined $data_dir && length $data_dir;

    return MasonX::WebApp::ApacheHandler->new(%p);
}



1;

__END__

=pod

=head1 NAME

Rudesind::Handler - The mod_perl handler for Rudesind

=head1 SYNOPSIS

  <Location /Rudesind>
    SetHandler perl-script
    PerlHandler Rudesind::Handler
  </Location>

=head1 DESCRIPTION

This module provides a C<handler()> subroutine for mod_perl.  It
fudges the URI so that Mason's standard resolver works even though the
incoming URI may not match a path on the filesystem.

=cut
