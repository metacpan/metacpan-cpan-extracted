package Password::OnePassword::OPCLI 0.001;
# ABSTRACT: get items out of 1Password with the "op" CLI

use v5.36.0;

use Carp ();
use IPC::Run qw(run timeout);
use JSON::MaybeXS qw(decode_json);

#pod =head1 SYNOPSIS
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
#pod   my $hashref = $one_pw->get_item($item_str, \%arg);
#pod
#pod This looks up an item in 1Password, using the C<op item get> command.  The
#pod locator C<$item_str> can be I<either> the item id I<or> two-part C<op://> URL.
#pod The way the URL works is like this:  If you use the "Copy Secret Reference"
#pod feature of 1Password, you'll end up with a string like this on your clipboard:
#pod
#pod   op://Private/Super Mario Fan Club/password
#pod
#pod This refers to a single I<field> in the vault item.  (You can get that field's
#pod value with C<get_field>, below.)  You can't presently use a URL like this with
#pod the C<op> command, but this library fakes it for you.  If you provide only the
#pod first two path parts of the URL above, like this:
#pod
#pod   op://Private/Super Mario Fan Club
#pod
#pod …then C<get_item> will get the "Super Mario Fan Club" item out of the "Private"
#pod vault.
#pod
#pod The reference to a C<%arg> hash is optional.  If given, it can contain a
#pod C<vault> entry, giving the name of the vault to look in.  This is only useful
#pod when giving an item id, rather than a URL.
#pod
#pod The method returns a reference to a hash in 1Password's documented internal
#pod format.  For more information, consult the 1Password developer tools
#pod documentation.  Alternatively, use this method and pretty-print the results.
#pod
#pod If the item can't be found, or the C<op> command doesn't exit zero, or in any
#pod case other than the best case, this method will throw an exception.
#pod
#pod =cut

sub get_item ($self, $item_str, $arg={}) {
  my $vault = $arg->{vault};

  unless (length $item_str) {
    Carp::croak('required argument $item_str was empty');
  }

  my $item;

  if ($item_str =~ m{\Aop://([^/]+)/([^/]+)/?\z}) {
    $vault = $1;
    $item  = $2;
  } elsif ($item_str =~ m{\Aop:}) {
    Carp::croak("The given item id looks like an op: URL, but isn't in the format op://VAULT/ITEM");
  } else {
    $item = $item_str;
  }

  my @op_command = (
    qw(op item get),
    (length $vault ? ('--vault', $vault) : ()),
    ('--format', 'json'),
    $item,
  );

  open(my $proc, '-|', @op_command) or Carp::croak("can't spawn op: $!");

  my $json = join q{}, <$proc>;

  # TODO: Log $? and $!, do something better. -- rjbs, 2024-05-03
  close($proc) or Carp::croak("problem running $proc");

  return decode_json($json);
}

#pod =method get_field
#pod
#pod   my $str = $one_pw->get_field($field_ref_str);
#pod
#pod This looks up an item in 1Password, using the C<op read> command.  The locator
#pod C<$field_ref_str> should be an C<op://> URL, like you'd get using the "Copy
#pod Secret Reference" feature of 1Password.
#pod
#pod It will return the string form of whatever is stored in that field.  If it
#pod can't find the field, if it can't authenticate, or in any case other than
#pod "everything worked", it will raise an exception.
#pod
#pod =cut

sub get_field ($self, $field_ref_str) {
  unless (length $field_ref_str) {
    Carp::croak('required argument $field_ref_str was empty');
  }

  if ($field_ref_str =~ /^-/) {
    Carp::croak('$field_ref_str starts with a dash, which is not permitted');
  }

  my @op_command = (
    qw(op read),
    $field_ref_str,
  );

  open(my $proc, '-|', @op_command) or Carp::croak("can't spawn op: $!");

  my $str = join q{}, <$proc>;

  # TODO: Log $? and $!, do something better. -- rjbs, 2024-05-03
  close($proc) or Carp::croak("problem running $proc");

  chomp $str;
  return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::OnePassword::OPCLI - get items out of 1Password with the "op" CLI

=head1 VERSION

version 0.001

=head1 SYNOPSIS

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

  my $hashref = $one_pw->get_item($item_str, \%arg);

This looks up an item in 1Password, using the C<op item get> command.  The
locator C<$item_str> can be I<either> the item id I<or> two-part C<op://> URL.
The way the URL works is like this:  If you use the "Copy Secret Reference"
feature of 1Password, you'll end up with a string like this on your clipboard:

  op://Private/Super Mario Fan Club/password

This refers to a single I<field> in the vault item.  (You can get that field's
value with C<get_field>, below.)  You can't presently use a URL like this with
the C<op> command, but this library fakes it for you.  If you provide only the
first two path parts of the URL above, like this:

  op://Private/Super Mario Fan Club

…then C<get_item> will get the "Super Mario Fan Club" item out of the "Private"
vault.

The reference to a C<%arg> hash is optional.  If given, it can contain a
C<vault> entry, giving the name of the vault to look in.  This is only useful
when giving an item id, rather than a URL.

The method returns a reference to a hash in 1Password's documented internal
format.  For more information, consult the 1Password developer tools
documentation.  Alternatively, use this method and pretty-print the results.

If the item can't be found, or the C<op> command doesn't exit zero, or in any
case other than the best case, this method will throw an exception.

=head2 get_field

  my $str = $one_pw->get_field($field_ref_str);

This looks up an item in 1Password, using the C<op read> command.  The locator
C<$field_ref_str> should be an C<op://> URL, like you'd get using the "Copy
Secret Reference" feature of 1Password.

It will return the string form of whatever is stored in that field.  If it
can't find the field, if it can't authenticate, or in any case other than
"everything worked", it will raise an exception.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
