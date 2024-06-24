package Net::Clacks::ClacksCache;
#---AUTOPRAGMASTART---
use v5.36;
use strict;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 29;
use autodie qw( close );
use Array::Contains;
use utf8;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use Data::Dumper;
use builtin qw[true false is_bool];
no warnings qw(experimental::builtin); ## no critic (TestingAndDebugging::ProhibitNoWarnings)
#---AUTOPRAGMAEND---

use Net::Clacks::Client;
use YAML::Syck;
use MIME::Base64;

sub new($proto, %config) {
    my $class = ref($proto) || $proto;

    my $self = bless \%config, $class;

    $self->reconnect();

    $self->{initfromhandle} = 0;

    if(!defined($self->{user})) {
        croak("User not defined!");
    }

    if(!defined($self->{password})) {
        croak("Password not defined!");
    }


    return $self;
}

sub newFromHandle($proto, $clacks) {
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    $self->{initfromhandle} = 1;
    $self->{clacks} = $clacks;

    $self->extraInits(); # Hook for application specific inits

    return $self;
}

sub reconnect($self) {
    return if($self->{initfromhandle});
    return if(defined($self->{clacks}));

    my $clacks;
    if(defined($self->{host}) && defined($self->{port})) {
        $clacks = Net::Clacks::Client->new($self->{host}, $self->{port}, 
                                            $self->{user}, $self->{password}, 
                                            $self->{APPNAME} . '/' . $VERSION, 0)
                or croak("Can't connect to Clacks server");
    } elsif(defined($self->{socketpath})) {
        $clacks = Net::Clacks::Client->newSocket($self->{socketpath}, 
                                            $self->{user}, $self->{password}, 
                                            $self->{APPNAME} . '/' . $VERSION, 0)
                or croak("Can't connect to Clacks server");
    } else {
        croak("No valid connection configured. Don't know where to connect to!");
    }
    $self->{clacks} = $clacks;

    $self->{clacks}->disablePing(); # Webclient doesn't know when it is called again

    $self->set("VERSION::" . $self->{APPNAME}, $VERSION);

    $self->{clacks}->activate_memcached_compat;
    $self->{clacks}->disablePing();

    $self->extraInits(); # Hook for application specific inits

    return;
}

sub extraInits($self) {
    # Hook for application specific inits
    return;
}

sub extraDestroys($self) {
    # Hook for application specific destroys
    return;
}

sub disconnect($self) {
    eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        $self->{clacks}->disconnect();
    };

    return;
}

DESTROY($self) {
    eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        $self->{clacks}->disconnect();
    };

    $self->extraDestroys();
    return;
};

sub get($self, $key) {
    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    my $value = $self->{clacks}->retrieve($key);
    return if(!defined($value));

    if($value =~ /^PAGECAMELCLACKSYAMLB64\:(.+)/o) {
        $value = decode_base64($1);
        $value = Load($value);
        $value = $self->deref($value);
    } elsif($value =~ /^PAGECAMELCLACKSB64\:(.+)/o) {
        $value = decode_base64($1);
    }
    return $value;
}

sub set($self, $key, $data) { ## no critic (NamingConventions::ProhibitAmbiguousNames)
    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    if(ref $data ne '') {
        #$data = 'PAGECAMELCLACKSYAMLB64: ' . encode_base64(Dump($data), '');
        $data = Dump($data);
        $data = 'PAGECAMELCLACKSYAMLB64: ' . encode_base64($data, '');
    } elsif($data =~ /^PAGECAMELCLACKSB64/o) {
        # Already encoded? Clacks injection alert? Just don't store the thing...
        return false;
    } elsif($data =~ /\n/o || $data =~ /\r/o) {
        $data = 'PAGECAMELCLACKSB64:' . encode_base64($data, '');
    }

    $self->{clacks}->store($key, $data);

    return true;
}

sub delete($self, $key) { ## no critic(BuiltinHomonyms)
    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    $self->{clacks}->remove($key);
    return true;
}

sub incr($self, $key, $stepsize = '') {
    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    if(!defined($stepsize) || $stepsize eq '') {
        $self->{clacks}->increment($key);
    } else {
        $self->{clacks}->increment($key, $stepsize);
    }
    return true;
}

sub decr($self, $key, $stepsize = '') {
    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    if(!defined($stepsize) || $stepsize eq '') {
        $self->{clacks}->decrement($key);
    } else {
        $self->{clacks}->decrement($key, $stepsize);
    }
    return true;
}

sub clacks_set($self, $key, $data) {
    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    $self->{clacks}->set($key, $data);

    return true;
}

sub clacks_notify($self, $key) {
    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    $self->{clacks}->notify($key);

    return true;
}

sub clacks_keylist($self) {
    $self->reconnect(); # Make sure we are connected

    return $self->{clacks}->keylist();
}


sub sanitize_key($self, $key) {
    # Certain chars are not allowed in keys for protocol reason.
    # We handle this by substituting them with a tripple underline

    $key =~ s/\ /___/go;
    $key =~ s/\=/___/go;

    return $key;
}

sub deref($self, $val) {
    return if(!defined($val));

    while(ref($val) eq "SCALAR" || ref($val) eq "REF") {
        $val = ${$val};
        last if(!defined($val));
    }

    return $val;
}

1;
__END__

=head1 NAME

Net::Clacks::ClacksCache - Clacks based Memcached replacement

=head1 SYNOPSIS

  use Net::Clacks::ClacksCache;

=head2 new

Makes a new instances if ClacksCache

=head2 newFromHandle

Takes a standard clacks instance and turns it into a ClacksCache instance.

=head2 set

Sets a key/value pair

=head2 get

Retrieve a value for the given key

=head2 incr

Increment a value. This behaves mostly according to standard Perl rules regarding scalars. If the value for the key
doesn't exist or is not numeric, it is assumed to be zero and then incremented.

=head2 decr

Decrement a value. This behaves mostly according to standard Perl rules regarding scalars. If the value for the key
doesn't exist or is not numeric, it is assumed to be zero and then decremented.

=head2 delete

Delete a key/value pair.

=head2 clacks_keylist

Provides a list of keys stored in ClacksCache.

=head2 clacks_notify

Provides the L<Net::Clacks::Client> notify function.

=head2 clacks_set

Provides the L<Net::Clacks::Client> set function.

=head2 extraInits

If you overload L<Net::Clacks::ClacksCache>, overloading extraInits() gives you a convenient places to add
your own initialization.

=head2 extraDestroys

If you overload L<Net::Clacks::ClacksCache>, overloading extraDestroys() gives you a convenient places to add
your own destroy functionality.

=head2 deref

Internal function

=head2 reconnect

Reconnect to the clacks server. This is mostly used internally, but you can call it if you suspect your connection is wonky or broken.

=head2 disconnect

Disconnect from the Server

=head2 sanitize_key

Internal function

=head1 DESCRIPTION

This implements the memcached-like client for the CLACKS interprocess messaging protocol.

=head1 IMPORTANT NOTE

Please make sure and read the documentations for L<Net::Clacks> as well as the L<Changes> file, as they contain
important information pertaining to upgrades and general changes!

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2024 Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
