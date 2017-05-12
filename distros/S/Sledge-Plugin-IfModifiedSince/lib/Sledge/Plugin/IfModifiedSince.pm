package Sledge::Plugin::IfModifiedSince;

use strict;
use vars qw($VERSION);
$VERSION = '0.05';

use HTTP::Date qw(str2time time2str);

use constant NOT_MODIFIED  => 304;

sub import {
    my $class = shift;
    my $pkg = caller;
    no strict 'refs';
    *{"$pkg\::not_modified"} = \&not_modified;
    *{"$pkg\::if_modified_since"} = \&if_modified_since;
    *{"$pkg\::set_last_modified"} = \&set_last_modified;
}

sub not_modified {
    my $self=shift;
	$self->r->status(NOT_MODIFIED);
	$self->send_http_header;
	$self->finished(1);
}

sub if_modified_since {
    my ($self, $thing) = @_;
    return 1 unless $thing;
    my $mtime = _get_epoch($thing);
    my $if_modified_since_epoch = str2time($ENV{'HTTP_IF_MODIFIED_SINCE'});
    return 1 unless $if_modified_since_epoch;
    return ( $mtime > $if_modified_since_epoch ) ? return 1 : 0;

}

sub set_last_modified {
    my ($self, $thing) = @_;
    my $mtime = _get_epoch($thing);
    $self->r->header_out('Last-Modified' => time2str($mtime))
    if $mtime;
}

sub _get_epoch {
    my $thing = shift;
    if ( $thing =~ /^\d+$/ ) { # treat as epoch
        return $thing;
    } elsif ( -e $thing ) { # treat as path
        return (stat($thing))[9];
    } else {
        warn "Argument must be a epochtime or filepath\n";
        return;
    }
}

1;
__END__

=head1 NAME

Sledge::Plugin::IfModifiedSince - Sledge plugin to control cache by If-Modified-Since header

=head1 SYNOPSIS

  package Your:Pages;
  use Sledge::Plugin::IfModifiedSince;

  sub dispatch_foo {
      my $self = shift;

      if ( $self->if_modified_since( time || '/path/to/file' ) ) {

          # set Last-Modified header by epoch time
          $self->set_last_modified( time );

          # or by path to file
          $self->set_last_modified( '/path/to/file' );

          # output content...

      } else {

          $self->not_modified;
          return;

      }


  }


=head1 DESCRIPTION

Sledge::Plugin::IfModifiedSince is Sledge plugin to control cache by If-Modified-Since header.
use this module in your Pages class, then if_modified_since, not_modified and set_last_modified methods are imported in it.

=head1 IMPORT METHODS

=over 4

=item if_modified_since

 # check by epoch time
 my $is_modified = $page->if_modified_since($epoch);

 # or by mtime
 my $is_modified = $page->if_modified_since('/path/to/file');

 Compare If-Modified-Since header to passed time.
 You can pass epoch time or path to file as argument.

=item not_modified

 $page->not_modified;

 Return 304 Not Modified.

=item set_last_modified

 # pass epoch time
 $self->set_last_modified( time );
 
 # or pass path to file
 $self->set_last_modified( '/path/to/file' );
 

 Set last modified time in Last-Modified header.
 You can pass epoch time or path to file as argument.

=back

=head1 AUTHOR

Yasuhiro Horiuchi E<lt>yasuhiro@hori-uchi.comE<gt>

=cut
