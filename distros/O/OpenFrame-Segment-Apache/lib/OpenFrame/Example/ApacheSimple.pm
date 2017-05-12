package OpenFrame::Example::ApacheSimple;

use strict;
use warnings;

use Apache;
use Apache::Constants qw(:response);
use File::Spec::Functions qw(catfile);
use Pipeline;
use OpenFrame::Example::Redirector;
use OpenFrame::Response;
use OpenFrame::Segment::Apache;
use OpenFrame::Segment::Apache::NoImages;
use OpenFrame::Segment::ContentLoader;

our $VERSION = '1.02';

sub handler {
  my $r = shift;

  my $dir = catfile($r->dir_config('cwd'), 'webpages');

  my $request = OpenFrame::Segment::Apache::Request->new();
  my $response = OpenFrame::Segment::Apache::Response->new();
  my $redirect = OpenFrame::Example::Redirector->new();
  my $noimages = OpenFrame::Segment::Apache::NoImages->new()
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
  $pipeline->add_segment($request, $redirect, $noimages, $content);
  $pipeline->cleanups->add_segment($response);

  my $store = Pipeline::Store::Simple->new();
  $pipeline->store($store->set($r));

  my $out = $pipeline->dispatch();
  if ($out->code == ofDECLINE) {
    return DECLINED;
  } else {
    return OK;
  }
}

1;

__END__

=head1 NAME

OpenFrame::Example::ApacheSimple - Demo Apache Pipeline

=head1 SYNOPSIS

  SetHandler  perl-script
  PerlSetVar  cwd /home/website/
  # PerlSetVar  debug 1
  PerlHandler OpenFrame::Example::ApacheSimple

=head1 DESCRIPTION

OpenFrame::Example::ApacheSimple is an example pipeline which loads
static content.

The actual handler is quite short. The important part is to set up a
pipeline which has a OpenFrame::Segment::Apache::Request segment at
the beginning and a OpenFrame::Segment::Apache::Response as a cleanup
segment. Also, remember to check for an ofDECLINE and return DECLINED
in that case, or OK otherwise.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd.
Licensed under the same terms as Perl itself.

=cut

