package Role::Kerberos;

use 5.014;
use strict;
use warnings FATAL => 'all';

use Moo::Role;
#use namespace::clean;

use Authen::Krb5 ();
use Scalar::Util ();
use Carp         ();
#use Try::Tiny    ();

# Authen::Krb5 contains a global, presumably non-threadsafe pointer to
# this execution context. This is the best way I can muster dealing
# with it.

BEGIN {
    Authen::Krb5::init_context();
}

END {
    Authen::Krb5::free_context();
}

sub _is_really {
    my ($x, $class) = @_;
    defined $x and ref $x and Scalar::Util::blessed($x) and $x->isa($class);
}

sub _k5err {
    Carp::croak(@_, ': ', Authen::Krb5::error());
}

=head1 NAME

Role::Kerberos - A role for managing Kerberos 5 credentials

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  package My::Kerbject;

  use Moo;
  with 'Role::Kerberos';

  has other_stuff => (
      # ...
  );

  # go nuts...

  # ...elsewhere:

  package Somewhere::Else;

  my $krb = My::Kerbject->new(
      principal   => 'robot@ELITE.REALM',
      keytab      => '/etc/robot/creds.keytab',
      ccache      => '/var/lib/robot/krb5cc',
      other_stuff => 'derp',
  );

=head1 DESCRIPTION

L<Authen::Krb5> is kind of unwieldy. L<Authen::Krb5::Simple> is too
simple (no keytabs). L<Authen::Krb5::Effortless> requires too much
effort (can't specify keytabs/ccaches outside of environment
variables) and L<Authen::Krb5::Easy> hasn't been touched in 13 years.

The purpose of this module is to enable you to strap onto an existing
L<Moo>(L<se|Moose>) object the functionality necessary to acquire and
maintain a Kerberos TGT. My own impetus for writing this module
involves making connections authenticated via L<Authen::SASL> and
GSSAPI where the keys come from a keytab in a non-default location and
the consistency of C<%ENV> is not reliable (that is, in a Web app).

=head1 METHODS

=head2 new %PARAMS

As with all roles, these parameters get integrated into your class's
constructor, and also serve as accessor methods. Every one is
read-only, and every one is optional except L</principal>.

=over 4

=item realm

The default realm. Taken from the default principal, or otherwise the
system default realm if not defined.

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %p;
    if (@_ and ref $_[0] eq 'HASH') {
        %p = %{$_[0]};
    }
    else {
        %p = @_;
    }

    Carp::croak('Must supply at least a principal')
          unless defined $p{principal} and $p{principal} ne '';

    if ($p{principal} =~ /@/) {
        $p{principal} = _coerce_principal($p{principal});
        $p{realm} ||= $p{principal}->realm;
    }
    else {
        $p{realm} ||= Authen::Krb5::get_default_realm();
        $p{principal} = sprintf '%s@%s', @p{qw(principal realm)};
    }

    if (defined $p{keytab}) {
        $p{keytab} = _coerce_kt($p{keytab});
    }

    if (defined $p{ccache}) {
        $p{ccache} = _coerce_cc($p{ccache});
    }

    $orig->($class, %p);
};

has realm => (
    is      => 'rw',
    lazy    => 1,
    default => sub { Authen::Krb5::get_default_realm(); },
);

=item principal

The default principal. Can (should) also contain a realm. If a realm
is missing from the principal, it will be added from
L</realm>. Coerced from a string into a
L<Authen::Krb5/Authen::Krb5::Principal> object. B<Required>.

=cut

sub _coerce_principal {
    my $n = shift;
    return $n if _is_really($n, 'Authen::Krb5::Principal');

    my $r = shift || Authen::Krb5::get_default_realm();

    $n = sprintf '%s@%s', $n, $r unless $n =~ /@/;

    Authen::Krb5::parse_name($n)
          or _k5err("Could not resolve principal $n");
}

has principal => (
    is       => 'ro',
    isa      => sub { _is_really(shift, 'Authen::Krb5::Principal') },
    required => 1,
    trigger  => sub { $_[0]->realm($_[0]->principal->realm) },
    coerce   => \&_coerce_principal,
);

=item keytab

A keytab, if other than C<$ENV{KRB5_KTNAME}>. Will default to that or
the system default (e.g. C</etc/krb5.keytab>). Coerced from a file
path into an L<Authen::Krb5/Authen::Krb5::Keytab> object.

=cut

sub _coerce_kt {
    my $val = shift;
    #warn 'YO DAWG COERCING KEYTAB';
    return $val if _is_really($val, 'Authen::Krb5::Keytab');

    $val = "FILE:$val" unless $val =~ /^[^:]+:/;

    Authen::Krb5::kt_resolve($val) or _k5err("Could not load keytab $val");
}

has keytab => (
    is      => 'ro',
    isa     => sub { _is_really(shift, 'Authen::Krb5::Keytab') },
    lazy    => 1,
    coerce  => \&_coerce_kt,
    default => sub {
        Authen::Krb5::kt_default() or _k5err("Could not load default keytab");
    },
);

=item password

The password for the default principal. Don't use this. Use a keytab.

=cut

has password => (
    is      => 'ro',
);

=item ccache

The locator (e.g. file path) of a credential cache, if different from
C<$ENV{KRB5CCNAME}> or the system default. Coerced into an
L<Authen::Krb5/Authen::Krb5::Ccache> object.

=cut

sub _coerce_cc {
    my $val = shift;
    return $val if _is_really($val, 'Authen::Krb5::Ccache');

    $val = "FILE:$val" unless $val =~ /^FILE:/i;

    Authen::Krb5::cc_resolve($val)
        or _k5err("Could not load credential cache $val");
}

has ccache => (
    is      => 'ro',
    isa     => sub { _is_really(shift, 'Authen::Krb5::Ccache') },
    lazy    => 1,
    coerce  => \&_coerce_cc,
    default => sub {
        Authen::Krb5::cc_default()
              or _k5err("Could not resolve default credentials cache");
    },
);

=back

=head2 kinit %PARAMS

Log in to Kerberos. Parameters are optional.

=over 4

=item principal

The principal, if different from that in the constructor.

=item realm

The realm, if different from that in the constructor. Ignored if the
principal contains a realm.

=item password

The Kerberos password, if logging in with a password. (See
L<Term::ReadPassword> for a handy way of ingesting a password from the
command line.)

=item keytab

A keytab, if different from that in the constructor or
C<$ENV{KRB5_KTNAME}>. Will be coerced from a file name.

=item service

A service principal, if different from C<krbtgt/REALM@REALM>.

=back

=cut

sub kinit {
    my $self = shift;
    my %p = @_;

    $p{realm} ||= $self->realm;
    $p{principal} = $p{principal}
        ? _coerce_principal(@p{qw(principal realm)}) : $self->principal;

    my $tgt;
    if (defined $p{password} or defined $self->password) {
        warn 'using a password you schlub';
        my $password = defined $p{password} ? $p{password} : $self->password;
        my @a = ($p{principal}, $password);
        push @a, $p{service} if defined $p{service};

        $tgt = Authen::Krb5::get_init_creds_password(@a)
            or _k5err('Failed to get TGT');
    }
    else {
        $p{keytab} = $p{keytab} ? _coerce_kt($p{keytab}) : $self->keytab;
        my @a = @p{qw(principal keytab)};
        push @a, $p{service} if defined $p{service};

        $tgt = Authen::Krb5::get_init_creds_keytab(@a)
            or _k5err('Failed to get TGT');
    }

    my $cc = $self->ccache;
    $cc->initialize($p{principal});
    $cc->store_cred($tgt);
}

=head2 klist %PARAMS

=cut

sub klist {
    my $self = shift;

    my $cc = $self->ccache;
    #my $p  = $self->principal;
    my @out;
    if (my $cursor = $cc->start_seq_get) {
        while (my $cred = $cc->next_cred($cursor)) {
            push @out, {
                principal => $cred->client,
                service   => $cred->server,
                auth      => $cred->authtime,
                start     => $cred->starttime,
                end       => $cred->endtime,
                renew     => $cred->renew_till,
                ticket    => $cred->ticket,
                # this segfaults when Authen::Krb5::Keyblock->DESTROY
                # is called with the key content memory out of bounds,
                # keyblock  => $cred->keyblock,
            };
        }
        $cc->end_seq_get($cursor);
    }

    return unless @out;
    wantarray ? @out : \@out;
}

=head2 kexpired

Returns true if any tickets in the cache are expired.

=cut

sub kexpired {
    my $self = shift;
    my $now  = time;

    my @tickets = $self->klist;
    return 1 unless @tickets;

    return scalar grep { $_->{end} < $now } @tickets;
}


# wishful thinking: Authen::Krb5 does not at the moment expose either
# ticket flags or krb5_get_renewed_creds.

# =head2 krenew

# Checks the TGT and reauthenticates  if expired. This is I<not>

# =cut

=head2 kdestroy

Destroy the credentials cache (if there is something to destroy).

=cut

sub kdestroy {
    my $self = shift;
    $self->ccache->destroy if $self->klist;
}

# XXX do we actually want this to happen?
# sub DEMOLISH {
#     $_[0]->kdestroy;
# }

# XXX more sensible?
sub DEMOLISH {
    my $self = shift;
    for my $entry ($self->klist) {
        delete $entry->{keyblock};
    }
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 SEE ALSO

=over 4

=item L<Authen::Krb5>

=item L<Moo::Role>

=back


=head1 BUGS

Please report any bugs or feature requests to C<bug-role-kerberos at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Role-Kerberos>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Role::Kerberos
