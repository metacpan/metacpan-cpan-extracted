use strict;
use warnings;
package Rubric::CLI::Command::user 0.157;
# ABSTRACT: Rubric user management commands

use parent qw(Rubric::CLI::Command);

use Digest::MD5 qw(md5_hex);
use Rubric::User;

sub usage_desc { "rubric user %o [username]" }

sub opt_spec {
  return (
    [ "new-user|n",        "add a user (requires --email and --password)" ],
    [ "activate|a",        "activate an existing user"                    ],
    [ "password|pass|p=s", "set user's password"                          ],
    [ "email|e=s",         "set user's email address"                     ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  die $self->usage->text unless @$args == 1;
}

sub run {
  my ($self, $opt, $args) = @_;

  my $username = $args->[0];

  die "--new-user and --activate are mutually exclusive"
    if $opt->{new_user} and $opt->{activate};

  if ($opt->{new_user}) {
    die "--new-user requries --email and --password"
      unless $opt->{email} and $opt->{password};

    my $user = Rubric::User->create({
      username => $username,
      password => md5_hex($opt->{password}),
      email    => $opt->{email},
    });

    die "couldn't create user" unless $user;

    print "created user $user";
    exit;
  }

  my $user = Rubric::User->retrieve($username);

  die "couldn't find user for '$username'" unless $user;

  if ($opt->{activate}) {
    $user->verification_code(undef);
    print "activated user account\n";
  }

  if ($opt->{email}) {
    $user->email($opt->{email});
    print "changed email\n";
  }

  if ($opt->{password}) {
    $user->password(md5_hex($opt->{password}));
    print "changed password\n";
  }

  $user->update;

  print "username: ", $user->username, "\n";
  print "email   : ", $user->email,    "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::CLI::Command::user - Rubric user management commands

=head1 VERSION

version 0.157

=head1 PERL VERSION

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)
This means that whatever version of perl is currently required is unlikely to
change -- but also that it might change at any new maintainer's whim.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
