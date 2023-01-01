package Role::HasMessage::Errf 0.007;
use MooseX::Role::Parameterized;
# ABSTRACT: a thing with a String::Errf-powered message

#pod =head1 SYNOPSIS
#pod
#pod In your class...
#pod
#pod   package Errfy;
#pod   use Moose;
#pod
#pod   with 'Role::HasMessage::Errf';
#pod
#pod   has payload => (
#pod     is  => 'ro',
#pod     isa => 'HashRef',
#pod     required => 1,
#pod   );
#pod
#pod Then...
#pod
#pod   my $thing = Errfy->new({
#pod     message => "%{error_count;error}n encountered at %{when}t",
#pod     payload => {
#pod       error_count => 2,
#pod       when        => time,
#pod     },
#pod   });
#pod
#pod   # prints: 2 errors encountered at 2010-10-20 19:23:42
#pod   print $thing->message;
#pod
#pod =head1 DESCRIPTION
#pod
#pod Role::HasMessage::Errf is an implementation of L<Role::HasMessage> that uses
#pod L<String::Errf> to format C<sprintf>-like message strings.  It adds a
#pod C<message_fmt> attribute, initialized by the C<message> argument.  The value
#pod should be a String::Errf format string.
#pod
#pod When the provided C<message> method is called, it will fill in the format
#pod string with the hashref returned by calling the C<payload> method, which I<must
#pod be implemented by the including class>.
#pod
#pod Role::HasMessage::Errf is a L<parameterized role|MooseX::Role::Parameterized>.
#pod The C<default> parameter lets you set a default format string or callback.  The
#pod C<lazy> parameter sets whether or not the C<message_fmt> attribute is lazy.
#pod Setting it lazy will require that a default is provided.
#pod
#pod =cut

use String::Errf qw(errf);
use Try::Tiny;

use namespace::clean -except => 'meta';

parameter default => (
  isa => 'CodeRef|Str',
);

parameter lazy => (
  isa     => 'Bool',
  default => 0,
);

role {
  my $p = shift;

  requires 'payload';

  my $msg_default = $p->default;
  has message_fmt => (
    is   => 'ro',
    isa  => 'Str',
    lazy => $p->lazy,
    required => 1,
    init_arg => 'message',
    (defined $msg_default ? (default => $msg_default) : ()),
  );

  # The problem with putting this in a cached attribute is that we need to
  # clear it any time the payload changes.  We can do that by making the
  # Payload trait add a trigger to clear the message, but I haven't done so
  # yet. -- rjbs, 2010-10-16
  # has message => (
  #   is       => 'ro',
  #   lazy     => 1,
  #   init_arg => undef,
  #   default  => sub { __stringf($_[0]->message_fmt, $_[0]->data) },
  # );

  method message => sub {
    my ($self) = @_;
    return try {
      errf($self->message_fmt, $self->payload)
    } catch {
      sprintf '%s (error during formatting)', $self->message_fmt;
    }
  };

  with 'Role::HasMessage';
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::HasMessage::Errf - a thing with a String::Errf-powered message

=head1 VERSION

version 0.007

=head1 SYNOPSIS

In your class...

  package Errfy;
  use Moose;

  with 'Role::HasMessage::Errf';

  has payload => (
    is  => 'ro',
    isa => 'HashRef',
    required => 1,
  );

Then...

  my $thing = Errfy->new({
    message => "%{error_count;error}n encountered at %{when}t",
    payload => {
      error_count => 2,
      when        => time,
    },
  });

  # prints: 2 errors encountered at 2010-10-20 19:23:42
  print $thing->message;

=head1 DESCRIPTION

Role::HasMessage::Errf is an implementation of L<Role::HasMessage> that uses
L<String::Errf> to format C<sprintf>-like message strings.  It adds a
C<message_fmt> attribute, initialized by the C<message> argument.  The value
should be a String::Errf format string.

When the provided C<message> method is called, it will fill in the format
string with the hashref returned by calling the C<payload> method, which I<must
be implemented by the including class>.

Role::HasMessage::Errf is a L<parameterized role|MooseX::Role::Parameterized>.
The C<default> parameter lets you set a default format string or callback.  The
C<lazy> parameter sets whether or not the C<message_fmt> attribute is lazy.
Setting it lazy will require that a default is provided.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
