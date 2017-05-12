package Redis::Script;
use 5.008005;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = ('redis_eval');

our $VERSION = "0.02";

use Digest::SHA qw(sha1_hex);
use Carp qw/croak/;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        use_evalsha => 1,
        %args,
    }, $class;

    return $self;
}

sub eval {
    my ($self, $redis, $keys, $args) = @_;
    if ($self->{use_evalsha}) {
        my $sha = $self->sha1;
        my $ret = eval { $redis->evalsha($sha, scalar(@$keys), @$keys, @$args) };
        if (my $err = $@) {
            croak $err if $err !~ /\[evalsha\] NOSCRIPT No matching script/i;
        } else {
            return (wantarray && ref $ret eq 'ARRAY') ? @$ret : $ret;
        }
    }

    my $ret = eval {
        $redis->eval($self->{script}, scalar(@$keys), @$keys, @$args);
    };
    if (my $err = $@) {
        croak $@;
    }

    return (wantarray && ref $ret eq 'ARRAY') ? @$ret : $ret;
}

sub exists {
    my ($self, $redis) = @_;
    return $redis->script_exists($self->sha1)->[0];
}

sub load {
    my ($self, $redis) = @_;
    my $sha = $self->sha1;
    my $redis_sha = $redis->script_load($self->{script});
    if (lc $sha ne lc $redis_sha) {
        croak "SHA is unmatch (expected $sha but redis returns $redis_sha)";
    }
    return $sha;
}

sub sha1 {
    my $self = shift;
    return $self->{sha} ||= sha1_hex($self->{script});
}

sub redis_eval {
    my ($redis, $script, $keys, $args) = @_;
    return __PACKAGE__->new(script => $script)->eval($redis, $keys, $args);
}

1;
__END__

=encoding utf-8

=head1 NAME

Redis::Script - wrapper class for Redis' script

=head1 SYNOPSIS

    # OO-interface
    use Redis;
    use Redis::Script;
    my $script = Redis::Script->new(script => "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}");
    my ($key1, $key2, $arg1, $arg2) = $script->eval(Redis->new, ['key1', 'key2'], ['arg1', 'arg2']);
    
    # Functional
    use Redis::Script qw/redis_eval/;
    my ($key1, $key2, $arg1, $arg2) = redis_eval(Redis->new, "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}", ['key1', 'key2'], ['arg1', 'arg2']);

=head1 DESCRIPTION

Redis::Script is wrapper class for Redis' script.


=head1 FUNCTIONS

=head2 C<< $script->eval($redis:Redis, $keys:ArrayRef, $args:ArrayRef) >>

C<eval> executes the script by C<EVALSHA> command.
If C<EVALSHA> reports "No matching script", use C<EVAL> instead of C<EVALSHA>.
Redis will cache the script of C<EVAL> command, so C<EVALSHA> will succeed next time.

If C<use_evalsha> option is false, C<eval> does not use C<EVALSHA> command.

=head2 C<< $script->exists($redis:Redis) >>

C<exists> reports if C<$redis> caches the script.

=head2 C<< $script->load($redis:Redis) >>

Load a script into the scripts cache, without executing it.

=head1 SEE ALSO

=over 4

=item *

L<Redis.pm|https://metacpan.org/pod/Redis>

=item *

L<Redis::Fast|https://metacpan.org/pod/Redis::Fast>

=item *

L<Description of EVAL|http://redis.io/commands/eval#bandwidth-and-evalsha>

=back

=head1 LICENSE

Copyright (C) Ichinose Shogo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ichinose Shogo E<lt>shogo82148@gmail.comE<gt>

=cut

