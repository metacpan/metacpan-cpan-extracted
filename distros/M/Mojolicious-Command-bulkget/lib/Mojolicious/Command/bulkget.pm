package Mojolicious::Command::bulkget;
use Mojo::Base 'Mojolicious::Command';
use Mojo::UserAgent;
use Mojo::Promise;
use Mojo::File 'path';
use Mojo::Util qw(getopt);

our $VERSION = '0.01';

my $MAXREQ = 20;

has description => 'Perform bulk get requests';
has usage => sub { shift->extract_usage . "\n" };

sub run {
  my ($self, @args) = @_;
  getopt \@args,
    'v|verbose'              => \my $verbose;
  my ($urlbase, $outdir, $suffixesfile) = @args;
  die $self->usage . "No URL" if !$urlbase;
  die $self->usage . "$outdir: $!" if ! -d $outdir;
  die $self->usage . "$suffixesfile: $!" if ! -f $suffixesfile;
  my $ua = Mojo::UserAgent->new;
  # Detect proxy for absolute URLs
  $urlbase !~ m!^/! ? $ua->proxy->detect : $ua->server->app($self->app);
  my $outpath = path($outdir);
  my @suffixes = _getsuffixes($suffixesfile, $outpath);
  my @promises = map _makepromise($urlbase, $ua, \@suffixes, $outpath, $verbose), (1..$MAXREQ);
  Mojo::Promise->all(@promises)->wait if @promises;
}

sub _makepromise {
  my ($urlbase, $ua, $suffixes, $outpath, $verbose) = @_;
  my $s = shift @$suffixes;
  return if !defined $s;
  my $url = $urlbase . $s;
  warn "getting $url\n" if $verbose;
  $ua->get_p($url)->then(sub {
    my ($tx) = @_;
    _handle_result($outpath, $tx, $s, $verbose);
    _makepromise($urlbase, $ua, $suffixes, $outpath, $verbose);
  });
}

sub _handle_result {
  my ($outpath, $tx, $s, $verbose) = @_;
  if ($tx->res->is_success) {
    warn "got $s\n" if $verbose;
    $outpath->child($s)->spurt($tx->res->body);
  } else {
    warn "error $s\n" if $verbose;
  }
}

sub _getsuffixes {
  my ($suffixesfile, $outpath) = @_;
  open my $fh, '<', $suffixesfile or die $!;
  grep { !-f $outpath->child($_); } map { chomp; $_ } <$fh>;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::bulkget - Perform bulk get requests

=head1 SYNOPSIS

  Usage: APPLICATION bulkget urlbase outdir suffixesfile

    # suffixes contains lines with 1, 2, 3
    # fetches /pets/1, /pets/2, ...
    # stores results in outputdir/1, outputdir/2, ...
    mojo bulkget http://example.com/pets/ outputdir suffixes

  Options:
    -v, --verbose                        Print progress information

=head1 DESCRIPTION

L<Mojolicious::Command::bulkget> is a command line interface for
bulk-fetching URLs.

Each line of the "suffixes" file is a suffix.  It gets appended to the URL
"base", then a non-blocking request is made. Only 20 requests will be
active at the same time. When ready, the result is stored in the output
directory with the suffix as the filename.

This command uses the relatively new Mojolicious feature, Promises. The
code may be considered worth examining for lessons on what to do, and/or
what not to do.

=head1 ATTRIBUTES

=head2 description

  $str = $self->description;

=head2 usage

  $str = $self->usage;

=head1 METHODS

=head2 run

  $get->run(@ARGV);

Run this command.

=head1 AUTHOR

Ed J

Based heavily on L<Mojolicious::Command::openapi>.

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
