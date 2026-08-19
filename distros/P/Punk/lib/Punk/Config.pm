package Punk::Config;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.20';

# Capture a command's standard output, without a shell. Called from C for
# { $exec: [...] }; a non-zero exit is fatal, so a broken secret store stops
# the boot rather than yielding an empty password.
sub _exec {
    my (@cmd) = @_;
    open my $ph, '-|', @cmd
        or die "cannot run '$cmd[0]': $!\n";
    my $out = do { local $/; <$ph> };
    close $ph;
    die "'$cmd[0]' exited with " . ($? >> 8) . "\n" if $?;
    return defined $out ? $out : '';
}

1;

__END__

=head1 NAME

Punk::Config - YAML configuration with secrets kept out of the file

=head1 SYNOPSIS

    # config/punk.yml - safe to commit
    views:
      Stencil:
        template_dir: root/templates
        wrapper: layout.tmpl

    database:
      dsn:      dbi:Pg:dbname=myapp;host=db
      user:     myapp
      password: { $env: DB_PASSWORD }

    plugins:
      RequestId: {}

    # MyApp.pm
    package MyApp;
    use Punk;

    config 'config/punk.yml';        # loads, applies, freezes

    get '/' => 'Web::Book#home';

=head1 DESCRIPTION

Configuration is read once, at boot, from a YAML file; layered by
environment; and applied to the application before C<to_app> freezes it.
See L<Punk/config> for what the known blocks do.

Implemented in C (F<include/punk/punk_config.h>): the layering, the deep
merge, secret resolution, the guardrail and the redacted copy. Only YAML
parsing (one L<YAML::XS> call per file) and the C<$exec> resolver's
subprocess are Perl, both once per boot.

=head2 Secrets

A config file should say B<where> a secret comes from, never what it is.
A reference is a single-key hash whose key starts with C<$> - a shape
nothing else in a config has, and one that needs nothing from the parser:

    password: { $env:     DB_PASSWORD }
    password: { $file:    /run/secrets/db_password }
    password: { $exec:    [ vault, read, -field=password, secret/db ] }
    password: { $literal: not-actually-secret }

C<$env> reads an environment variable (missing is fatal - better than
starting with an empty password). C<$file> reads a file and trims one
trailing newline, which is exactly how Docker and Kubernetes deliver
secrets to a container. C<$exec> runs a command without a shell and takes
its standard output, for Vault, C<aws secretsmanager>, C<op read> and
friends; a non-zero exit is fatal. C<$literal> is a deliberate inline
value that bypasses the guardrail below.

Resolved secrets are kept apart from the public structure:
C<< $app->config >> has C<[redacted]> where each one was, so it can be
logged, dumped or serialised safely, and C<< $app->secret($path) >>
reaches the real value. Boot-time consumers are handed the real value
directly, so a database password never sits in a general-purpose hash at
all.

=head2 The guardrail

A plaintext value under a secret-shaped key (anything containing
C<pass>, C<secret>, C<token>, C<api_key>, C<private_key> or
C<credential>, the exact key C<auth>, or a C<dsn> with C<password=> in
it) is almost always a mistake. The loader notices and, by default,
warns:

    secrets: strict      # refuse to start
    secrets: warn        # the default
    secrets: off

C<auth> matches only as a whole key, so an C<author> field is left alone.

=head2 Layering

C<config/punk.yml> is read first, then C<config/punk.$PUNK_ENV.yml>
(C<production> unless C<PUNK_ENV> says otherwise), then
C<config/punk.local.yml>. Later layers win. Hashes merge key by key;
anything else replaces, so an array in an overlay is a replacement rather
than an append.

Add C<punk.local.yml> to C<.gitignore>: it is the one place a developer
may keep a throwaway value.

=head1 METHODS

=head2 load(file => $path, env => $name, secrets => $mode)

Read, layer, resolve and validate. Croaks if no layer exists, if a
reference cannot be resolved, or - in C<strict> mode - if the guardrail
fires.

=head2 config

The public structure: secrets replaced by C<[redacted]>.

=head2 resolved

The same structure with the real values. What the boot consumers read.

=head2 get($dotted_path)

The resolved value at a path, secrets included.

=head2 secret($dotted_path)

=head2 has_secret($dotted_path)

=head2 secret_paths

The resolved secrets.

=head2 env

=head2 files

The environment name, and the layers actually read.

=head1 SEE ALSO

L<Punk>, L<YAML::XS>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
