package Mojo::File::ChangeNotify::WatcherProcess 0.03;
use 5.020;
use experimental 'signatures';
use feature 'postderef';
use feature 'try';
use Exporter 'import';
use File::ChangeNotify;
our @EXPORT_OK = 'watch';

# We keep this in a separate module file as to minimize any variables
# shared over into this context

=head1 NAME

Mojo::File::ChangeNotify::WatcherProcess - helper module for the subprocess

=head1 SYNOPSIS

  my $w = Mojo::File::ChangeNotify->instantiate_watcher(
      directories => ['.'],
      on_change => sub($s,$ev) {
          for my $e ($ev->@*) {
            print "$e->{type} $e->{path}\n";
          }
      }
  );
  # note that the watcher might need about 1s to start up

=cut

sub watch( $subprocess, $args ) {
    my $watcher = File::ChangeNotify->instantiate_watcher( $args->%* );
    RESTART:
    try {
      # File::ChangeNotify dies when it gets an empty string back from Inotify :/
      while( my @events = $watcher->wait_for_events ) {
          for my $list (@events) {
              $subprocess->progress( [ map {;
                                        defined $_->path
                                        ? +{ path => $_->path, type => $_->type }
                                        : ()
                                      } $list ]);
          }
      }
    } catch( $e ) {
      goto RESTART
    }
}

1;
