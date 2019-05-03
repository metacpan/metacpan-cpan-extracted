package Mojolicious::Plugin::AutoSecrets;
# ABSTRACT: Automatic, Rotating Mojolicious Secrets
$Mojolicious::Plugin::AutoSecrets::VERSION = '0.006';

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw(encode_json decode_json);
use Session::Token;
use Carp qw(croak);
use Fcntl qw(:DEFAULT :flock);
use IO::File;
use autodie;


sub register {
  my ($self, $app, $config) = @_;
  $config //= {};

  my $path        = $config->{path}        // $app->home->rel_file('.mojo-secrets');
  my $mode        = $config->{mode}        // 0600;
  my $expire_days = $config->{expire_days} // 60;
  my $prune       = $config->{prune}       // 3;
  my $generator   = $config->{generator}   // \&generator;

  my @secrets;

  sysopen my $fh, $path, O_RDWR | O_CREAT, $mode;
  flock $fh, LOCK_EX;

  my $rv;
  my $disk = '';
  while ($rv = $fh->sysread(my $buf, 4096, 0)) { $disk .= $buf }
  croak "Can't read from $path: $!"
    if !defined $rv;

  my $disk_secrets = $disk && decode_json($disk);

  unshift @secrets, @$disk_secrets
    if $disk_secrets;

  if (!@secrets || -z $path || -M _ > $expire_days) {
    unshift @secrets, $generator->();

    @secrets = @secrets[0 .. $prune - 1]
      if $prune && @secrets > $prune;

    $fh->seek(0, 0);
    $fh->syswrite(my $j = encode_json(\@secrets));
  }
  flock $fh, LOCK_UN;
  $fh->close;

  push @secrets, @{$app->{secrets}}
    if $app->{secrets};

  $app->secrets(\@secrets);
}


sub generator {
  Session::Token->new->get;
}



1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::AutoSecrets - Automatic, Rotating Mojolicious Secrets

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('AutoSecrets');

  $self->plugin('AutoSecrets' => {path => '/my/favorite/hiding/spot'});

  # Mojolicious::Lite
  plugin 'AutoSecrets';

=head1 DESCRIPTION

L<Mojolicious::Plugin::AutoSecrets> is a L<Mojolicious> plugin that takes care
of generating, storing, and rotating your L<Mojolicious/secrets>.

=head2 WARNING

Secrets are used to ensure integrity and trust L<Mojolicious> default session
cookies.  Letting code manage them means that code becomes part of your
security.  Read this documentation and review this code!

Take it from me, never trust a programmer.

=head1 OVERVIEW

L<Mojolicious::Plugin::AutoSecrets> requires no configuration, but does support
a few options:

=head2 path

Default: C<.mojo-secrets> in L<Mojolicious/home>

Accepts any file path for storing secrets and checking age.  It will be created
if it doesn't exist.

=head2 mode

Default: C<0600>

The file mode set when creating L</path>.

=head2 expire_days

Default: C<60>

After L</expire_days> days, generate a new secret and add it to the front of
the list.

=head2 prune

Default: C<3>

The secrets list will be pruned to this size as it is rotated.

=head2 generator

Default: C<Mojolicious::Plugin::AutoSecrets::generator>

Allows specifying a code ref that will be invoked with no arguments to generate
a new secret when necessary.

=head1 INHERITANCE

L<Mojolicious::Plugin::AutoSecrets> inherits all methods and attributes from
L<Mojolicious::Plugin> and implements the following.

=head1 METHODS

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.  Upon registration, this plugin
will generate, and store and rotate if necessary, secrets for the application.
An optional config hashref may tweak behavior, see L</OVERVIEW>.

If there are secrets already set at the time register executes, those secrets
B<will not> be stored as managed secrets in L</path>, and managed secrets will
be placed B<before> existing secrets.  This should make it easy to move to or
from AutoSecrets.

=head1 FUNCTIONS

=head2 generator

The default secret generator, using Session::Token

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious>

=item *

L<Mojolicious::Sessions>

=item *

L<Mojolicious::Controller/signed_cookie>

=back

=head1 AUTHOR

Meredith Howard <mhoward@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Meredith Howard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
