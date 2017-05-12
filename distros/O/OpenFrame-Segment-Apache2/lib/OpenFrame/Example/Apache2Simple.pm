package OpenFrame::Example::Apache2Simple;

use strict;
use warnings;

use Apache2;
use Apache::Const -compile => qw(OK DECLINED);
use File::Spec::Functions qw(catfile);
use Pipeline;
use OpenFrame::AppKit;
use OpenFrame::Example::Redirector;
use OpenFrame::Response;
use OpenFrame::Segment::Apache2;
use OpenFrame::Segment::Apache2::NoImages;
use OpenFrame::Segment::ContentLoader;

our $VERSION = '1.00';

sub handler {
  my $r = shift;

  my $dir = catfile($r->dir_config('cwd'), 'webpages');

  my $request = OpenFrame::Segment::Apache2::Request->new();
  my $session_loader = OpenFrame::AppKit::Segment::SessionLoader->new();
  my $response = OpenFrame::Segment::Apache2::Response->new();
  my $redirect = OpenFrame::Example::Redirector->new();
  my $noimages = OpenFrame::Segment::Apache2::NoImages->new()
    ->directory($dir);
  my $content = OpenFrame::Segment::ContentLoader->new()
    ->directory($dir);

  if ($r->dir_config('debug')) {
    # debugorama
    $request->debug(10);
    $redirect->debug(10);
    $noimages->debug(10);
    $content->debug(10);
    $response->debug(10);
  }

  my $pipeline = Pipeline->new();
  $pipeline->add_segment($request, $session_loader, $redirect, $noimages, $content);
  $pipeline->add_cleanup($response);

  # Store the request in the pipeline
  $pipeline->store->set($r);
  my $out = $pipeline->dispatch();

  if ($out->code == ofDECLINE) {
    return Apache::DECLINED;
  } else {
    return Apache::OK;
  }
}

1;

__END__

=head1 NAME

OpenFrame::Example::Apache2Simple - Demo Apache2 Pipeline

=head1 SYNOPSIS

  SetHandler  perl-script
  PerlSetVar  cwd /home/website/
  # PerlSetVar  debug 1
  PerlHandler OpenFrame::Example::Apache2Simple

=head1 DESCRIPTION

OpenFrame::Example::Apache2Simple is an example pipeline which loads
static content.

The actual handler is quite short. The important part is to set up a
pipeline which has a OpenFrame::Segment::Apache2::Request segment at
the beginning and a OpenFrame::Segment::Apache2::Response as a cleanup
segment. Also, remember to check for an ofDECLINE and return DECLINED
in that case, or OK otherwise.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd.
Licensed under the same terms as Perl itself.

=cut

