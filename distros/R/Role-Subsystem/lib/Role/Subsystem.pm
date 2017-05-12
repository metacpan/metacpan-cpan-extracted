package Role::Subsystem;
{
  $Role::Subsystem::VERSION = '0.101341';
}
use MooseX::Role::Parameterized;
# ABSTRACT: a parameterized role for object subsystems, helpers, and delegates


parameter ident => (isa => 'Str', required => 1);


parameter what => (
  isa      => 'Str',
  required => 1,
);


parameter what_id => (
  isa      => 'Str',
  lazy     => 1,
  default  => sub { $_[0]->what . '_id' },
);


parameter type    => (isa => 'Defined', required => 1);


parameter id_type => (isa => 'Defined', default => 'Defined');


parameter id_method => (isa => 'Str', default => 'id');


parameter getter => (
  isa     => 'CodeRef',
);


parameter weak_ref => (
  isa     => 'Bool',
  default => 1,
);

role {
  my ($p)  = @_;

  my $what      = $p->what;
  my $ident     = $p->ident;
  my $what_id   = $p->what_id;
  my $getter    = $p->getter;
  my $id_method = $p->id_method;
  my $weak_ref  = $p->weak_ref;

  my $w_pred    = "has_initialized_$what";
  my $wi_pred   = "has_initialized_$what_id";
  my $w_reader  = "_$what";
  my $w_clearer = "_clear_$what";

  confess "cannot use weak references for $ident without a getter"
    if $weak_ref and not $getter;

  has $what => (
    is        => 'bare',
    reader    => $w_reader,
    isa       => $p->type,
    lazy      => 1,
    predicate => $w_pred,
    clearer   => $w_clearer,
    default   => sub {
      # Basically, this should never happen.  We should not be generating the
      # for_what_id method if there is no getter, and we should be blowing up
      # if produced without a what without a getter.  Still, CYA.
      # -- rjbs, 2010-05-05
      confess "cannot get a $what based on $what_id; no getter" unless $getter;

      $getter->( $_[0]->$what_id );
    },
  );

  if ($weak_ref) {
    method $what => sub {
      my ($self) = @_;
      my $value = $self->$w_reader;
      return $value if defined $value;
      $self->$w_clearer;
      return $self->$w_reader;
    };
  } else {
    my $reader = "_$what";
    method $what => sub { $_[0]->$reader },
  }

  has $what_id => (
    is   => 'ro',
    isa  => $p->id_type,
    lazy => 1,
    predicate => $wi_pred,
    default   => sub { $_[0]->$what->$id_method },
  );

  method BUILD => sub {};

  after BUILD => sub {
    my ($self) = @_;

    # So, now we protect ourselves from pathological cases.  These are:
    # 1. neither $what nor $what_id given
    unless ($self->$w_pred or $self->$wi_pred) {
      confess "neither $what nor $what_id given in constructing $ident";
    }

    # 2. both $what and $what_id given, but not matching
    if (
      $self->$w_pred and $self->$wi_pred
      and $self->$what->$id_method ne $self->$what_id
    ) {
      confess "the result of $what->$id_method is not equal to the $what_id"
    }

    # 3. only $what_id given, but no getter
    if ($self->$wi_pred and ! $self->$w_pred and ! $getter) {
      confess "can't build $ident with only $what_id; no getter";
    }

    if ($weak_ref) {
      # We get the id immediately, if we have a weak ref, on the assumption
      # that if the ref expires, we will need the id for the getter
      # to function. -- rjbs, 2010-05-05
      $self->$what_id unless $self->$wi_pred;

      # We only *really* weaken this if we're starting off with an object from
      # outside, because if we got the object from our getter, nothing else is
      # likely to be holding a reference to it. -- rjbs, 2010-05-05
      Scalar::Util::weaken $self->{$what} if $self->$w_pred;
    }
  };

  method "for_$what" => sub {
    my ($class, $entity, $arg) = @_;
    $arg ||= {};

    $class->new({
      %$arg,
      $what => $entity,
    });
  };

  if ($getter) {
    method "for_$what_id" => sub {
      my ($class, $id, $arg) = @_;
      $arg ||= {};

      $class->new({
        %$arg,
        $what_id => $id,
      });
    };
  }
};

__END__

=pod

=head1 NAME

Role::Subsystem - a parameterized role for object subsystems, helpers, and delegates

=head1 VERSION

version 0.101341

=head1 DESCRIPTION

Role::Subsystem is a L<parameterized role|MooseX::Role::Parameterized>.  It's
meant to simplify creating classes that encapsulate specific parts of the
business logic related to parent classes.  As in the L<synopsis|/What?>
above, it can be used to write "helpers."  The subsystems it creates must have
a reference to a parent object, which might be referenced by id or with an
actual object reference.  Role::Subsystem tries to guarantee that no matter
which kind of reference you have, the other kind can be obtained and stored for
use.

=head2 What??

Okay, imagine you have a big class called Account.  An Account is the central
point for a lot of behavior, and rather than dump all that logic in one place,
you partition it into subsytems.  Let's say we want to write a subsystem that
handles all of an Account's Services.  We might write this:

  package Account::ServiceManager;
  use Moose;
  use Account;

  with 'Role::Subsystem' => {
    ident  => 'acct-service-mgr',
    type   => 'Account',
    what   => 'account',
    getter => sub { Account->retrieve_by_id( $_[0] ) },
  };

  sub add_service {
    my ($self, @args) = @_;

    # ... do some preliminary business logic

    $self->account->insert_related_rows(...);

    # ... do some cleanup business logic
  }

Then you might add to F<Account.pm>:

  package Account;
  sub service_mgr {
    my ($self) = @_;
    return Account::ServiceManager->for_account($self);
  }

Then, to add a service you can write:

  $account->service_mgr->add_service(...);

You could also just grab the service manager object and use it as a handle for
performing operations.

If you don't have an Account object, just a reference to its id, you could get
the service manager like this:

  my $service_mgr = Account::ServiceManager->for_account_id( $account_id );

=head2 Why?

Here's an overview of everything this role will do for you, in terms of the
Account::ServiceManager example above.

It will create the C<for_account> and C<for_account_id> constructors on your
subsystem.  (The C<for_account_id> constructor will only be created if a
C<getter> is supplied.)

It will defer retrieval of C<account> objects if you construct with only a
C<account_id>, so that if you never need the full object, you never waste time
getting it.

It will ensure that any C<account> and C<account_id> encountered match the
C<type> and C<id_type> types, respectively.  This will prevent a bogus
identifier from being accepted, only to die later when it can't be used for
lazy retrieval.

If you create a subsystem object by passing in the parent object (the
C<account>), it will take a weak reference to it to prevent cyclical references
from interfering with garbage collection.  If the reference goes away, or if
you did not start with a reference, a strong reference will be constructed to
allow the subsystem to function efficiently afterward.  (This behavior can be
disabled, if you never want to take a weak reference.)

=head3 Swappable Subsystem Implementations

You can also have multiple implementations of a single kind of subsystem.  For
example, you may eventually want to do something like this:

  package Account::ServiceManager;
  use Moose::Role;

  with 'Role::Subsystem' => { ... };

  requries 'add_service';
  requries 'remove_service';
  requries 'service_summary';

...and then...

  package Account::ServiceManager::Legacy;
  with 'Account::ServiceManager';

  sub add_service { ... };

...and...

  package Account::ServiceManager::Simple;
  with 'Account::ServiceManager';

  sub add_service { ... };

...and finally...

  package Account;

  sub settings_mgr {
    my ($self) = @_;

    my $mgr_class = $self->schema_version > 1
                  ? 'Account::ServiceManager::Simple'
                  : 'Account::ServiceManager::Legacy';

    return $mgr_class->for_account($self);
  }

This requires a bit more work, but lets you replace subsystem implementations
as fairly isolated units.

=head1 PARAMETERS

These parameters can be given when including Role::Subsystem; these are in
contrast to the L<attributes|/ATTRIBUTES> and L<methods|/METHODS> below, which
are added to the classe composing this role.

=head2 ident

This is a simple name for the role to use when describing itself in messages.
It is required.

=head2 what

This is the name of the attribute that will hold the parent object, like the
C<account> in the synopsis above.

This attribute is required.

=head2 what_id

This is the name of the attribute that will hold the parent object's
identifier, like the C<account_id> in the synopsis above.

If not given, it will be the value of C<what> with "_id" stuck on the end.

=head2 type

This is the type that the C<what> must be.  It may be a stringly Moose type or
an L<MooseX::Types> type.  (Or anything else, right now, but anything else will
probably cause runtime failures or worse.)

This attribute is required.

=head2 id_type

This parameter is like C<type>, but is used to check the C<what>'s id,
discussed more below.  If not given, it defaults to C<Defined>.

=head2 id_method

This is the name of a method to call on C<what> to get its id.  It defaults to
C<id>.

=head2 getter

This (optional) attribute supplied a callback that will produce the parent
object from the C<what_id>.

=head2 weak_ref

If true, when a subsytem object is created with a defined parent object (that
is, a value for C<what>), the reference to the object will be weakened.  This
allows the parent and the subsystem to store references to one another without
creating a problematic circular reference.

If the parent object is subsequently garbage collected, a new value for C<what>
will be retreived and stored, and it will B<not> be weakened.  To allow this,
setting C<weak_ref> to true requires that C<getter> be supplied.

C<weak_ref> is true by default.

=head1 ATTRIBUTES

The following attributes are added classes composing Role::Subsystem.

=head2 $what

This will refer to the parent object of the subsystem.  It will be a value of
the C<type> type defined when parameterizing Role::Subsystem.  It may be lazily
computed if it was not supplied during creation or if the initial value was
weak and subsequently garbage collected.

If the value of C<what> when parameterizing Role::Subsystem was C<account>,
that will be the name of this attribute, as well as the method used to read it.

=head2 $what_id

This method gets the id of the parent object.  It will be a defined value of
the C<id_type> provided when parameterizing Role::Subsystem.  It may be lazily
computed by calling the C<id_method> on C<what> as needed.

=head1 METHODS

=head2 for_$what

  my $settings_mgr = Account::ServiceManager->for_account($account);

This is a convenience constructor, returning a subsystem object for the given
C<what>.

=head2 for_$what_id

  my $settings_mgr = Account::ServiceManager->for_account_id($account_id);

This is a convenience constructor, returning a subsystem object for the given
C<what_id>.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
