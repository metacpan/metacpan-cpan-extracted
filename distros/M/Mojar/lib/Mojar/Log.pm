package Mojar::Log;
use Mojo::Base 'Mojo::Log';

our $VERSION = 1.002;

use Mojo::Util 'encode';
use POSIX 'strftime';

sub import {
  my $pkg = shift;
  # Mixin
  if (@_) {
    my @args = @_;
    my $default = sub { Mojar::Log->new(@args) };
    eval sprintf
    'package %s; no strict q{refs}; sub log { $_[0]{log} //= $default->() }; 1',
        scalar caller
      or die 'Failed to create Mojar::Log mixin';
  }
}

# Attributes

has pattern => '%Y%m%d %H:%M:%S';

has format => sub {
  my $self = shift; weaken $self; sub {
    my ($time, $level, @lines) = @_;
    encode 'UTF-8', sprintf '%s[%s] %s', strftime($self->pattern,
        localtime($time)), $level, join "\n", @lines, ''
  }
};

1;
__END__

=head1 NAME

Mojar::Log - Simple logger

=head1 SYNOPSIS

  use Mojar::Log;

  # Log to STDERR without timestamps
  my $log = Mojar::Log->new(pattern => undef);

  # Customise log file location and timestamp pattern
  my $log = Mojar::Log->new(path => '/tmp/abc.log', pattern => '[%F %X] ');

  # Log messages
  $log->debug('Hmmm?');
  $log->info(q{We're charging per character});
  $log->warn('Uh-oh!');
  $log->error(q{You won't believe this});
  $log->fatal('OH NOES!');

=head1 DESCRIPTION

L<Mojar::Log> is a simple logger extending L<Mojo::Log>.  The additions are the
ability to set defaults at 'use' time (via a mixin) and a more ISO-ish timestamp
with support for customising that pattern.  (Mojo::Log now let's you customise
the format by passing a coderef/closure to the format attribute.)

=head1 USAGE

Standard usage is by creating a Log object as in the SYNOPSIS.  For shared code,
large codebases, or long-running processes, that is the only recommended usage.
In standalone classes and scripts it's often more convenient to set the
parameters via an implicit mixin.  In a standalone script this could be done as:

  use Mojar::Log (
    path => '/var/log/something.log',
    level => 'info',
    pattern => '%F %X...'
  );
  main->log->debug('Go!');

If the same 'use' is employed in a class then it could be done as:

  package MyClass;
  use Mojar::Log (...);

  my $o = MyClass->new(...);
  $o->log->debug('Go!');  # object method
  MyClass->log->debug('Go!');  # class method

Employing use-time parameters entails the implicit creation of a method (mixin)
and a hash entry.  The mixin works by assigning a Log object to the caller's
'log' hash key, so only works with objects implemented as hashrefs.  In other
words, only use the convenience of the mixin if that's what you were going to do
anyway.  [Using the package name to hold a hashref is considered hacky and makes
debugging a little trickier; creating a log object per caller object can be
considered sub-optimal.  If either of those trouble you, please re-read the
intro to this section then return to the SYNOPSIS.]

Thanks to L<Mojolicious> being so versatile, you can even use Mojar::Log in
those projects, taking advantage of the introduced 'pattern' attribute.

  package MyApp;
  use Mojo::Base 'Mojolicious';
  use Mojar::Log;
  sub startup {
    my $self = shift;
    $self->log(Mojar::Log->new(pattern => '...', path => '...'));
  }

And in a Lite app:

  use Mojolicious::Lite;
  use Mojar::Log;
  app->log(Mojar::Log->new(pattern => '...', path => '...'));

After which you can use the usual Mojolicious 'log' method.

=head1 ATTRIBUTES

L<Mojar::Log> inherits its attributes from L<Mojo::Log> and adds the following.

=head2 pattern

  $pattern = $log->pattern;
  $log     = $log->pattern('%Y%m%d %H:%M:%S');

Pattern to use for the timestamp.  The default pattern (above) is a fairly
minimal 17 characters.  The timestamp can be disabled altogether by setting it
to 'undef'.

  $log->pattern(undef)->info('Timeless!');  # $log then uses no timestamp

See L<Time::CTime> for the full list of specifiers, but a few common choices are
the following.

  $log->pattern('[%FT%X] ');  # ISO 8601 timestamp with secs and brackets
  $log->pattern('[%F %R] ');  # ISO 8601 timestamp omitting 'T' and secs
  $log->pattern('%y%m%d%H%M%S');  # A more minimal 12 chars

On a linux system, you can test your pattern by calling C<date>.

  date +'%Y.%m.%d %H.%M.%S'

=head1 LEGACY NEEDS

The current version of this requires at least v5 of Mojolicious.  If you need to
work with an older version of Mojolicious, consider using v1.062.

  cpanm Mojar@1.062

=head1 SEE ALSO

L<Mojo::Log>, the parent class which provides the majority of documentation.
