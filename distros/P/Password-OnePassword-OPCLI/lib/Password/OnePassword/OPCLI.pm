package Password::OnePassword::OPCLI 0.002;
# ABSTRACT: get items out of 1Password with the "op" CLI

use v5.36.0;

use Carp ();
use IPC::Run qw(run timeout);
use JSON::MaybeXS qw(decode_json);

#pod =head1 SYNOPSIS
#pod
#pod B<Achtung!>  The interface for this library might change a lot.  The author is
#pod still figuring out how to make it make sense.  That's partly because he doesn't
#pod want to think too hard about errors, and partly because the C<op://> URL scheme
#pod used by 1Password isn't really sufficient for his use.  Still, this is roughly
#pod how you can use it:
#pod
#pod   my $one_pw = Password::OnePassword::OPCLI->new;
#pod
#pod   # Get the string found in one field in your 1Password storage:
#pod   my $string = $one_pw->get_field("op://Private/PAUSE API/credential");
#pod
#pod   # Get the complete document for an item, as a hashref:
#pod   my $pw_item = $one_pw->get_item("op://Work/GitHub");
#pod
#pod =cut

#pod =method new
#pod
#pod   my $one_pw = Password::OnePassword::OPCLI->new;
#pod
#pod This is a do-almost-nothing constructor.  It's only here so that methods are
#pod instance methods, not class methods.  Someday, there may be more arguments to
#pod this, but for now, there are not.
#pod
#pod =cut

sub new ($class, @rest) {
  Carp::croak("too many arguments given to constructor, which takes none")
    if @rest;

  bless {}, $class;
}

#pod =method get_item
#pod
#pod   my $hashref = $one_pw->get_item($locator);
#pod
#pod This looks up an item in 1Password, returning a hashref representing the secret
#pod from 1Password.
#pod
#pod The C<$locator> should be I<either> a Password::OnePassword::OPCLI::Locator
#pod object or a string that coerced into one, for which see L</LOCATOR STRINGS>.
#pod
#pod If the locator specifies a field name, an exception will be raised.
#pod
#pod =cut

sub get_item ($self, $locator) {
  unless (ref $locator) {
    $locator = Password::OnePassword::OPCLI::Locator->_from_string($locator);
  }

  if (defined $locator->field) {
    Carp::croak("passed field-level locator to get_item; drop the field part or use get_field");
  }

  my @op_command = (
    qw(op item get),
    (defined $locator->vault ? ('--vault', $locator->vault) : ()),
    ('--format', 'json'),
    $locator->item,
  );

  local $ENV{OP_ACCOUNT} = $locator->account // $ENV{OP_ACCOUNT};
  open(my $proc, '-|', @op_command) or Carp::croak("can't spawn op: $!");

  my $json = join q{}, <$proc>;

  # TODO: Log $? and $!, do something better. -- rjbs, 2024-05-03
  close($proc) or Carp::croak("problem running 'op item get'");

  return decode_json($json);
}

#pod =method get_field
#pod
#pod   my $str = $one_pw->get_field($locator);
#pod
#pod This looks up an item in 1Password, using the C<op read> command.
#pod
#pod The C<$locator> should be I<either> a Password::OnePassword::OPCLI::Locator
#pod object or a string that coerced into one, for which see L</LOCATOR STRINGS>.
#pod The string you get from using the "Copy Secret Reference" feature of 1Password,
#pod as long as the 1Password account is not ambiguous at runtime.
#pod
#pod If the locator does not specify a field name, an exception will be raised.
#pod
#pod It will return the string form of whatever is stored in that field.  If it
#pod can't find the field, if it can't authenticate, or in any case other than
#pod "everything worked", it will raise an exception.
#pod
#pod =cut

sub get_field ($self, $locator) {
  $self->_call_op_read_for_field_ref($locator);
}

sub _call_op_read_for_field_ref ($self, $locator, $arg = {}) {
  unless (ref $locator) {
    $locator = Password::OnePassword::OPCLI::Locator->_from_string($locator);
  }

  unless (defined $locator->field) {
    Carp::croak("locator provided to get_field does not specify a field name");
  }

  my $url = $locator->_as_op_url;

  # I don't like this.  The problem, *in part*, is that you can't just pass the
  # op:// URI through URI.pm, because its ->as_string will encode spaces to
  # %20, but that isn't permitted in "op read".  This probably has a better
  # workaround, but the goal right now is just to make the method work.
  # -- rjbs, 2024-06-09
  if ($arg->{attribute}) {
    $url .= "?attribute=$arg->{attribute}";
  }

  my @op_command = (
    qw(op read),
    $url,
  );

  local $ENV{OP_ACCOUNT} = $locator->account // $ENV{OP_ACCOUNT};
  open(my $proc, '-|', @op_command) or Carp::croak("can't spawn op: $!");

  my $str = join q{}, <$proc>;

  # TODO: Log $? and $!, do something better. -- rjbs, 2024-05-03
  close($proc) or Carp::croak("problem running 'op read'");

  chomp $str;
  return $str;
}

#pod =method get_otp
#pod
#pod   my $otp = $one_pw->get_otp($locator);
#pod
#pod This looks up an item in 1Password, using the C<op read> command.  The item is
#pod assumed to be an OTP-type field.  Instead of returning the field's value, which
#pod would be the TOTP secret, this method will return the one-time password for the
#pod current time.
#pod
#pod The C<$locator> argument works the same as the argument to the C<get_field>
#pod method.
#pod
#pod If C<op> can't find the field, if the field isn't an OTP field, if it can't
#pod authenticate, or in any case other than "everything worked", the library will
#pod raise an exception.
#pod
#pod =cut

sub get_otp ($self, $locator) {
  $self->_call_op_read_for_field_ref($locator, {
    # This is stupid, see _call_op_read_for_field_ref.
    attribute => 'otp',
  });
}

#pod =head1 LOCATOR STRINGS
#pod
#pod 1Password offers C<op://> URLs for fetching things via C<op>, but they're not
#pod quite good enough, at least for this author's needs.  First off, if you use the
#pod "Copy Secret Reference" feature of 1Password, you'll end up with a string like
#pod this on your clipboard:
#pod
#pod   op://Private/Super Mario Fan Club/password
#pod
#pod This refers to a single I<field> in the vault item.  You can pass this to the
#pod C<op read> command.  If you want to fetch the whole secret item, though, you
#pod I<can't> just drop the third part of the path to pass to C<op item get>.  If
#pod you have that URL and want to get the whole item, you need to parse it and
#pod build a command-line invocation yourself.
#pod
#pod There's a worse problem, too.  A two-part (item, not field) URL makes sense
#pod because you just drop one piece of data from the three-part URL.  But these
#pod URLs are also I<missing> a place for the account.  If you've got more than one
#pod 1Password account on your laptop, like both work and personal, you can't
#pod unambiguously specify a credential with only a string.  This really undercuts
#pod the value of the C<op://> URIs as (for example) environment variables.  You end
#pod up having to set a I<second> environment variable indicating which account to
#pod use, and if you need to access more than one vault in a program, the complexity
#pod piles up.
#pod
#pod Password::OnePassword::OPCLI works with "locator" objects, which the user
#pod shouldn't really need to think about.  The user of the library can pass in a
#pod string that can be parsed into a locator, either as a normal three-part
#pod C<op://> URL, or as a bogus-but-comprehensible two-part URL, or as an
#pod OPCLI-specific string like this:
#pod
#pod   opcli:a=${Account}:v=${Vault}:i=${Item}:f=${Field}
#pod
#pod Order is not important and only the item property is required.  To represent
#pod the URL above (C<op://Private/Super Mario Fan Club/password>) in this format,
#pod you'd write:
#pod
#pod   opcli:v=Private:i=Super Mario Fan Club:f=password
#pod
#pod Later, if you realized that you need to specify an account, you could tack it
#pod on the end:
#pod
#pod   opcli:v=Private:i=Super Mario Fan Club:f=password:a=Personal
#pod
#pod The value of property will be URI-decoded before use.  This won't matter,
#pod generally, but you'll need to know if it you want to use locators with C<%> or
#pod C<:> in property values, at least.
#pod
#pod =cut

package Password::OnePassword::OPCLI::Locator 0.002 {
  use Moo;
  use v5.36.0;

  use URI::Escape ();

  has account => (is => 'ro');
  has vault   => (is => 'ro');
  has item    => (is => 'ro');
  has field   => (is => 'ro');

  sub _as_op_url ($self) {
    return sprintf "op://%s/%s/%s",
      $self->vault // Carp::confess("tried to build op:// URL without vault name"),
      $self->item  // Carp::confess("tried to build op:// URL without item identifier"),
      $self->field // Carp::confess("tried to build op:// URL without field name");
  }

  sub _from_string ($class, $str) {
    my $account;
    my $vault;
    my $item;
    my $field;

    if ($str =~ m{\Aop://([^/]+)/([^/]+)(/([^/]*))?\z}) {
      $vault = $1;
      $item  = $2;
      $field = $3;
    } elsif ($str =~ m{\Aopcli:}) {
      # opcli:a=${Account}:v=${Vault}:i=${Item}:f=${Field}
      my (undef, @hunks) = split /:/, $str;
      my %got;
      state %known_k = map {; $_ => 1 } qw(a v i f);

      for my $hunk (@hunks) {
        my ($k, $v) = split /=/, $hunk, 2;
        $known_k{$k}    || Carp::croak("unknown key in 1Password locator: $hunk");
        exists $got{$k} && Carp::croak("saw $k= twice in 1Password locator");
        length $v       || Carp::croak("empty $k= value in 1Password locator");

        $got{$k} = $v;
      }

      ($account, $vault, $item, $field)
        = map {; length $_ ? URI::Escape::uri_unescape($_) : $_ }
          @got{ qw( a v i f ) };
    } else {
      $item = $str;
    }

    unless (length $item) {
      Carp::confess("empty item identifier in 1Password locator string");
    }

    return $class->new({
      account => $account,
      vault   => $vault,
      item    => $item,
      field   => $field,
    });
  }

  no Moo;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::OnePassword::OPCLI - get items out of 1Password with the "op" CLI

=head1 VERSION

version 0.002

=head1 SYNOPSIS

B<Achtung!>  The interface for this library might change a lot.  The author is
still figuring out how to make it make sense.  That's partly because he doesn't
want to think too hard about errors, and partly because the C<op://> URL scheme
used by 1Password isn't really sufficient for his use.  Still, this is roughly
how you can use it:

  my $one_pw = Password::OnePassword::OPCLI->new;

  # Get the string found in one field in your 1Password storage:
  my $string = $one_pw->get_field("op://Private/PAUSE API/credential");

  # Get the complete document for an item, as a hashref:
  my $pw_item = $one_pw->get_item("op://Work/GitHub");

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 new

  my $one_pw = Password::OnePassword::OPCLI->new;

This is a do-almost-nothing constructor.  It's only here so that methods are
instance methods, not class methods.  Someday, there may be more arguments to
this, but for now, there are not.

=head2 get_item

  my $hashref = $one_pw->get_item($locator);

This looks up an item in 1Password, returning a hashref representing the secret
from 1Password.

The C<$locator> should be I<either> a Password::OnePassword::OPCLI::Locator
object or a string that coerced into one, for which see L</LOCATOR STRINGS>.

If the locator specifies a field name, an exception will be raised.

=head2 get_field

  my $str = $one_pw->get_field($locator);

This looks up an item in 1Password, using the C<op read> command.

The C<$locator> should be I<either> a Password::OnePassword::OPCLI::Locator
object or a string that coerced into one, for which see L</LOCATOR STRINGS>.
The string you get from using the "Copy Secret Reference" feature of 1Password,
as long as the 1Password account is not ambiguous at runtime.

If the locator does not specify a field name, an exception will be raised.

It will return the string form of whatever is stored in that field.  If it
can't find the field, if it can't authenticate, or in any case other than
"everything worked", it will raise an exception.

=head2 get_otp

  my $otp = $one_pw->get_otp($locator);

This looks up an item in 1Password, using the C<op read> command.  The item is
assumed to be an OTP-type field.  Instead of returning the field's value, which
would be the TOTP secret, this method will return the one-time password for the
current time.

The C<$locator> argument works the same as the argument to the C<get_field>
method.

If C<op> can't find the field, if the field isn't an OTP field, if it can't
authenticate, or in any case other than "everything worked", the library will
raise an exception.

=head1 LOCATOR STRINGS

1Password offers C<op://> URLs for fetching things via C<op>, but they're not
quite good enough, at least for this author's needs.  First off, if you use the
"Copy Secret Reference" feature of 1Password, you'll end up with a string like
this on your clipboard:

  op://Private/Super Mario Fan Club/password

This refers to a single I<field> in the vault item.  You can pass this to the
C<op read> command.  If you want to fetch the whole secret item, though, you
I<can't> just drop the third part of the path to pass to C<op item get>.  If
you have that URL and want to get the whole item, you need to parse it and
build a command-line invocation yourself.

There's a worse problem, too.  A two-part (item, not field) URL makes sense
because you just drop one piece of data from the three-part URL.  But these
URLs are also I<missing> a place for the account.  If you've got more than one
1Password account on your laptop, like both work and personal, you can't
unambiguously specify a credential with only a string.  This really undercuts
the value of the C<op://> URIs as (for example) environment variables.  You end
up having to set a I<second> environment variable indicating which account to
use, and if you need to access more than one vault in a program, the complexity
piles up.

Password::OnePassword::OPCLI works with "locator" objects, which the user
shouldn't really need to think about.  The user of the library can pass in a
string that can be parsed into a locator, either as a normal three-part
C<op://> URL, or as a bogus-but-comprehensible two-part URL, or as an
OPCLI-specific string like this:

  opcli:a=${Account}:v=${Vault}:i=${Item}:f=${Field}

Order is not important and only the item property is required.  To represent
the URL above (C<op://Private/Super Mario Fan Club/password>) in this format,
you'd write:

  opcli:v=Private:i=Super Mario Fan Club:f=password

Later, if you realized that you need to specify an account, you could tack it
on the end:

  opcli:v=Private:i=Super Mario Fan Club:f=password:a=Personal

The value of property will be URI-decoded before use.  This won't matter,
generally, but you'll need to know if it you want to use locators with C<%> or
C<:> in property values, at least.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
