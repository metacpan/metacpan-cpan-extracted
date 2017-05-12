package Redis::ScriptCache;
use strict;
use warnings;
use 5.10.0;

our $VERSION = '0.05';

use File::Basename;
use File::Spec qw(
    catdir
    splitdir
);
use Carp;
use Digest::SHA1 'sha1_hex';

use Class::XSAccessor {
    getters => [qw(
        redis_conn
        script_dir
        _script_cache
    )],
};

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;

    # initialize the cache
    $self->{_script_cache} = {};
    # redis_conn is compulsory
    $self->redis_conn
        or croak('Need Redis connection');
    # canonicalize script_dir
    $self->_set_script_dir;

    return $self;
}

sub _set_script_dir {
    my( $self, $script_dir ) = @_;
    my $script_dir_to_set = $script_dir // $self->script_dir // undef;
    $self->{script_dir} = File::Spec->catdir( File::Spec->splitdir( $script_dir_to_set ) )
        if $script_dir_to_set;
    return $self;
}

sub register_all_scripts {
    my $self = shift;
    my %args = @_;

    $self->_set_script_dir( $args{script_dir} )
        if $args{script_dir};

    if ( $self->script_dir ) {
        for my $file (glob($self->script_dir . '/*.lua')) {
            $self->register_file(basename($file));
        }
        return $self->scripts;
    } else {
        croak('No script_dir specified');
    }
}

sub register_script {
    my ($self, $script_name, $script) = @_;
    $script = $$script if ref($script);

    $self->{_script_cache}{$script_name} = [ sha1_hex($script), $script ];

    return $script_name;
}

sub run_script {
    my ($self, $script_name, $args) = @_;

    my $conn = $self->redis_conn;
    my $script = $self->_script_cache->{$script_name}
        // croak("Unknown script $script_name");

    my @result;
    my $try = sub {
        $conn->evalsha($$script[0], $args ? @$args : (0));
    };
    my $wantarray = wantarray;
    if ( $wantarray ) {
        @result = eval { $try->() };
    }
    elsif ( defined $wantarray ) {
        $result[0] = eval { $try->() };
    }
    else {
        eval { $try->() };
    }
    if ( $@ ) {
        croak $@ unless $@ =~ /NOSCRIPT/;
        return $conn->eval($$script[1], $args ? @$args : (0));
    };

    return unless defined $wantarray;
    return $wantarray ? @result : $result[0];
}

sub register_file {
    my ($self, $path_to_file) = @_;
    open my $fh, '<', File::Spec->catdir( $self->script_dir, $path_to_file )
        or croak "error opening $path_to_file: $!";

    my $script_name = basename( $path_to_file );
    $script_name =~ s/\.lua$//;
    my $script = do { local $/; <$fh> };
    return $self->register_script($script_name, $script);
}

sub scripts {
    my ($self) = @_;
    return keys %{ $self->_script_cache };
}

sub flush_all_scripts {
    my ($self) = @_;
    eval {
        $self->redis_conn->script_flush();
        $self->{_script_cache} = {};
    };
    if ( $@ ) {
        croak "redis script_flush failed: $@";
    };
    return $self;
}

1;

__END__

=head1 NAME

Redis::ScriptCache - Cached Lua scripts on a Redis server

=head1 SYNOPSIS

  use Redis;
  use Redis::ScriptCache;

  my $conn = Redis->new(server => ...);
  my $cache = Redis::ScriptCache->new(redis_conn => $conn);

  # some Lua script to execute on the server
  my $script = q{
    local x = redis.call('get', KEYS[1]);
    redis.call('set', 'temp', x);
    return x;
  };
  my $script_name = $cache->register_script('myscript', $script);

  # later:
  my ($value) = $cache->run_script('myscript', [1, 'somekey']);

  # alternatively, if you have a script_dir
  my $cache = Redis::ScriptCache->new(
    redis_conn => $conn,
    script_dir => 'path/to/lua/scripts',
  );
  $cache->register_all_scripts();
  # path/to/lua/scripts/*.lua gets registered
  $cache->run_script('myscript1', [1, 'somekey']); # myscript1.lua

=head1 DESCRIPTION

Recent versions of Redis can execute Lua scripts on the server.  This appears
to be the most effective and efficient way to group interactions with Redis
atomically. In order to avoid having to re-transmit (and compile) the scripts
themselves on every request, Redis has a set of commands related to executing
previously seen scripts again using the SHA-1 as identification.

This module offers a way to avoid re-transmission of the full script without
checking for script existence on the server manually each time.  For that
purpose, it offers an interface that will load the given script onto the Redis
server and on subsequent uses avoid doing so.

Do not use this module if it can happen that all scripts are flushed from the
Redis instance during the life time of a script cache object.

=head1 METHODS

=head2 new

Expects key/value pairs of options.  The only mandatory option is
C<redis_conn>, an instance of the L<Redis> module to use to talk to the Redis
server.

C<script_dir> is optional, and can also be specified in C<register_all_scripts> as
well (see below).

=head2 register_script

Given a Lua script (as a scalar, or scalar ref) to register as the first
argument, this makes sure that the script is available via its SHA-1 on the
Redis server.

Returns the script's name, which will be used to invoke the script using
C<run_script>, see below.  The SHA-1 is opaque to the user and is internally
cached to avoid repeat registration and unnecessary roundtrips.

=head2 run_script

Given a registered script's name as first argument and an array reference as
second argument, executes the corresponding Lua script on the Redis server and
passes the contents of the array reference as parameters to the
C<$redis-E<gt>evalsha($sha, ...)> call. Refer to
L<http://redis.io/commands/evalsha> for details.

If the second parameter is omitted, it's assumed to be a script
call without parameters, so that

  $cache->run_script($script_name);

is the same as:

  $cache->run_script($script_name, [0]);

It is expected that the script is pre-registered via C<register_script>,
C<register_file>, or C<register_all_scripts>.

Returns the results of the C<evalsha> call.

=head2 register_all_scripts

Given a C<script_dir> (specified in C<new> or C<register_all_scripts>), will
register them all under their Lua script names.

Returns an array of names all registered scripts.

=head2 register_file

Given a filename under C<script_dir> will register that file and return the
name of that script. Handy if you don't want to register everything, but just a
select script on disk.

=head2 scripts

Returns an array of all scripts registered in the script cache.

=head2 flush_all_scripts

Flushes the Redis script cache, and the local script cache.

=head1 SEE ALSO

L<Redis>

L<http://redis.io>

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

=head1 CONTRIBUTORS

Iftekharul Haque, C<iftekhar@cpan.org>

Tom Rathborne, C<lsd@acm.org>

Omar Othman, C<omar.m.othman@gmail.com>

Marc Mims, C<marc@questright.com>

=head1 COPYRIGHT AND LICENSE

 (C) 2012-2016 Steffen Mueller. All rights reserved.

 This code is available under the same license as Perl version
 5.8.1 or higher.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

