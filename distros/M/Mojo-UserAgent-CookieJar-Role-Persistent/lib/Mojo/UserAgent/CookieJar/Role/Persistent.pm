package Mojo::UserAgent::CookieJar::Role::Persistent;
use Mojo::Base '-role';

use Mojo::Cookie::Response;
use Mojo::File;

our $VERSION = '0.002';

has file    => 'cookies.txt';
has session => 1;

has expires_in => sub { sub {time + (60*10)} };

requires qw(add all);

sub load {
  my $self = shift;

  my $file = Mojo::File->new($self->file);
  return $self if !-e $file;

  foreach my $cookie (map {[split /\t/]} split /\R/, $file->slurp) {
    next if $#$cookie != 6;
    my %cookie;
    @cookie{qw[domain flag path secure expires name value]}
      = @{$cookie};
    delete $cookie{flag};
    $cookie{secure} = $cookie{secure} eq 'TRUE' ? 1 : 0;
    $self->add(Mojo::Cookie::Response->new(%cookie));
  }

  return $self;
}

sub save {
  my $self = shift;

  my $session = $self->session;

  my @cookies;
  foreach my $cookie (@{$self->all}) {
    push @cookies, [
      $cookie->domain // ($session ? $cookie->origin : next),
      ($session) ? 'TRUE' : 'FALSE',
      $cookie->path,
      ($cookie->secure) ? 'TRUE' : 'FALSE',
      $cookie->expires // ($session ? $self->expires_in->() : next),
      $cookie->name,
      $cookie->value,
    ];
  }

  Mojo::File->new($self->file)->spurt(join "\n",
    '# Netscape HTTP Cookie File',
    '',
    map { join "\t", @{$_} } @cookies
  );

  return $self;
}

1;
