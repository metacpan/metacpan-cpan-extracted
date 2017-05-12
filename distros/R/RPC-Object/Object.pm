package RPC::Object;
use constant DEFAULT_PORT => 8049;
use constant RETRY_MAX => 10;
use constant RETRY_WAIT => 2;
use strict;
use warnings;
use Carp;
use Storable qw(nfreeze thaw);
use RPC::Object::Transport;

our $VERSION = '0.31';

sub new {
    my ($class, $url) = splice @_, 0, 2;
    my ($host, $port) = $url =~ /([^:]+)(?::(\d+))?/;
    croak 'usage: ' . __PACKAGE__ . qq(->new("host:port", ...)) unless defined $host;
    $port = DEFAULT_PORT unless defined $port;
    my $obj = _invoke($host, $port, @_);
    my $self = \"$host:$port:$obj";
    return bless $self, $class;
}

sub get_instance {
    my ($class, $url) = splice @_, 0, 2;
    return $class->new($url, '_rpc_object_find_instance', 'RPC::Object::Broker', @_);
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $name = [split '::', $AUTOLOAD]->[-1];
    return unless __PACKAGE__ eq substr($AUTOLOAD, 0, -(length "::$name"));
    my ($host, $port, $obj) = split ':', $$self;
    if ($name eq 'DESTROY') {
        return;
    }
    elsif (defined $obj) {
        return _invoke($host, $port, $name, $obj, @_);
    }
    return;
}

sub _invoke {
    my ($host, $port) = splice @_, 0, 2;
    my $context = wantarray;
    my $res = _request($host, $port, 'a' . nfreeze([$context, @_]));
    my $id = $res;
    my @ret;
    while (1) {
        $res = _request($host, $port, 'r' . $id);
        next if $res eq '';
        @ret = @{thaw($res)};
        last if @ret;
    }
    continue {
        sleep 1;
    }
    my $state = shift @ret;
    croak @ret if $state eq 'e';
    return unless defined $context;
    return $context ? @ret : $ret[0];
}

sub _request {
    my ($host, $port, $cmd) = @_;
    return RPC::Object::Transport->new({PeerAddr => $host,
                                        PeerPort => $port,
                                        Proto => 'tcp',
                                       })->request($cmd);
}

1;
__END__

=head1 NAME

RPC::Object - A lightweight implementation for remote procedure calls

=head1 SYNOPSIS

B<On server>

  use RPC::Object::Broker;
  $b = $RPC::Object::Broker->new(preload => \@preload_modules);
  $b->start();

B<On client>

  use RPC::Object;
  $o = RPC::Object->new("$host:$port", 'method_a', 'TestModule');
  my $ans1 = $o->method_b($arg1, $arg2);
  my @ans2 = $o->method_c($arg3, $arg4);

  # To access the global instance
  # allocate and initialize first,
  RPC::Object->new("$host:$port", 'method_a', 'TestModule');
  ...
  $global = RPC::Object->get_instance("$host:$port", 'TestModule');

B<TestModule>

  package TestModule;
  use threads;
  ...
  sub method_a {
      my $class = shift;
      my $self : shared;
      ...
      return bless $self, $class;
  }  }

Please see more examples in the test scripts.

=head1 DESCRIPTON

C<RPC::Object> is designed to be very simple and only works between
Perl codes, This makes its implementation only need some core Perl
modules, e.g. Socket and Storable.

Other approaches like SOAP or XML-RPC are too heavy for simple tasks.

B<Thread awareness>

All modules and objects invoked by C<RPC::Object> should aware the
multi-threaded envrionment.

B<Constructor and Destructor>

The Module could name its constructor any meaningful name. it do not
have to be C<new>, or C<create>, etc...

There is no guarantee that the destructor will be called as expected.

B<Global instance>

To allocate global instances, use the C<RPC::Object::new()>
method. Then use the C<RPC::Object::get_instance()> method to access
them.

=head1 KNOW ISSUES

B<Scalars leaked warning>

This is expected for now. The walkaround is to close STDERR.

B<Need re-bless RPC::Object>

C<threads::shared> prior to 0.95 does not support bless on shared
refs, if an <RPC::Object> is passed across threads, it may need
re-bless to C<RPC::Object>.

=head1 AUTHORS

Jianyuan Wu <jwu@cpan.org>

=head1 COPYRIGHT

Copyright 2006 -2007 by Jianyuan Wu <jwu@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
