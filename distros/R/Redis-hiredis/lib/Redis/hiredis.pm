package Redis::hiredis;

use strict;
our $VERSION = "0.11.0";
require XSLoader;
XSLoader::load('Redis::hiredis', $VERSION);

our $AUTOLOAD;

sub new {
    my($class, %args) = @_;

    if(!exists $args{utf8}) {
        $args{utf8} = 1;
    }

    my $self = $class->_new($args{utf8});

    if(exists $args{host}) {
        $self->connect($args{host}, defined $args{port} ? $args{port} : 6379);
    }
    elsif (exists $args{path}) {
        $self->connect_unix($args{path});
    }

    return $self;
}

sub AUTOLOAD {
    (my $method = $AUTOLOAD) =~ s/.*:://;

    # cache method for future calls
    my $sub =  sub { shift->command($method, @_) };
    no strict 'refs';
    *$AUTOLOAD = $sub;

    goto $sub;
}

1;
__END__

=head1 NAME

Redis::hiredis - interact with Redis using the hiredis client.

=head1 SYNOPSIS

  use Redis::hiredis;
  my $redis = Redis::hiredis->new();
  $redis->connect('127.0.0.1', 6379);
  $redis->command('set foo bar');
  $redis->command(["set", "foo", "bar baz"]); # values with spaces
  my $val = $redis->command('get foo');

  # to pipeline commands
  $redis->append_command('set abc 123');
  $redis->append_command('get abc');
  my $set_status = $redis->get_reply(); # 'OK'
  my $get_val = $redis->get_reply(); # 123

=head1 DESCRIPTION

C<Redis::hiredis> is a simple wrapper around Salvatore Sanfilippo's
L<hiredis|https://github.com/antirez/hiredis> C client that allows connecting 
and sending any command just like you would from a command line Redis client.

B<NOTE> Versions >= 0.9.2 and <= 0.9.2.4 are not compatible with prior versions

=head2 METHODS

=over 4

=item new([utf8 => 1], [host => "localhost"], [port => 6379], [path => "/tmp/redis.sock"])

Creates a new Redis::hiredis object.

If the host attribute is provided the L</connect> method will automatically be
called.

If the path attribute is provided the L</connect_unix> method will automatically be
called.

=item connect( $hostname, $port )

C<$hostname> is the hostname of the Redis server to connect to

C<$port> is the port to connect on.  Default 6379

=item connect_unix( $path )

C<$path> is the path to the unix socket

=item command( $command_and_args )

=item command( [ $command, $arg, ... ] )

=item command( $command, $arg, ... )

command supports multiple types of calls to be backwards compatible and provide
more convenient use.  Examples of how to pass arguments are:

  $redis->command('set foo bar');
  $redis->command(["set", "foo", "bar baz"]);
  $redis->command("set", "foo", "bar baz");

Note that if you have spaces in your values, you must use one of the last 2 forms.

command will return a scalar value which will either be an integer, string
or an array ref (if multiple values are returned).

=item append_command( $command )

For performance reasons, it's sometimes useful to pipeline commands.  When
pipelining, muiltple commands are sent to the server at once and the results
are read as they become available.  hiredis supports this via append_command()
and get_reply().  Commands passed to append_command() are buffered locally
until the first call to get_reply() when all the commands are sent to the
server at once.  The results are then returned one at a time via calls to
get_reply().

See the hiredis documentation for a more detailed explanation.

=item get_reply()

See append_command().

=back

=head2 Autoloaded Methods

Autoload is used to allow an interface like $redis->set("foo", "bar").  The method
name you provide will be passed blindly to Redis, so any supported command should work.

Note that to use any autoloaded method, you must pass arguments as an array, the string
and array ref forms supported by command will not work.

=head1 SEE ALSO

The Redis command reference can be found here:
L<http://redis.io/commands>

A discusion of pipelining can be found here:
L<http://redis.io/topics/pipelining>

Documentation on the hiredis client can be found here:
L<https://github.com/antirez/hiredis>

Redis::hiredis on github:
L<https://github.com/neophenix/redis-hiredis>

=cut
