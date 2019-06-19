package Net::Clacks::ClacksCache;
#---AUTOPRAGMASTART---
use 5.010_001;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp;
our $VERSION = 6.0;
use Fatal qw( close );
use Array::Contains;
#---AUTOPRAGMAEND---

use Net::Clacks::Client;
use YAML::Syck;
use MIME::Base64;

sub new {
    my ($proto, %config) = @_;
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

sub newFromHandle {
    my ($proto, $clacks) = @_;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    $self->{initfromhandle} = 1;
    $self->{clacks} = $clacks;

    $self->extraInits(); # Hook for application specific inits

    return $self;
}

sub reconnect {
    my ($self) = @_;

    return if($self->{initfromhandle});
    return if(defined($self->{clacks}));

    my $clacks = Net::Clacks::Client->new($self->{host}, $self->{port}, $self->{user}, $self->{password}, $self->{APPNAME} . '/' . $VERSION, 0)
            or croak("Can't connect to Clacks server");
    $self->{clacks} = $clacks;

    $self->{clacks}->disablePing(); # Webclient doesn't know when it is called again

    $self->set("VERSION::" . $self->{APPNAME}, $VERSION);

    $self->{clacks}->activate_memcached_compat;
    $self->{clacks}->disablePing();

    $self->extraInits(); # Hook for application specific inits

    return;
}

sub extraInits {
    my ($self) = @_;

    # Hook for application specific inits
    return;
}

sub extraDestroys {
    my ($self) = @_;

    # Hook for application specific destroys
    return;
}

DESTROY {
    my ($self) = @_;

    $self->extraDestroys();
    return;
};

sub get {
    my ($self, $key) = @_;

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

sub set { ## no critic (NamingConventions::ProhibitAmbiguousNames)
    my ($self, $key, $data) = @_;

    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    if(ref $data ne '') {
        #$data = 'PAGECAMELCLACKSYAMLB64: ' . encode_base64(Dump($data), '');
        $data = Dump($data);
        $data = 'PAGECAMELCLACKSYAMLB64: ' . encode_base64($data, '');
    } elsif($data =~ /^PAGECAMELCLACKSB64/o) {
        # Already encoded? Clacks injection alert? Just don't store the thing...
        return 0;
    } elsif($data =~ /\n/o || $data =~ /\r/o) {
        $data = 'PAGECAMELCLACKSB64:' . encode_base64($data, '');
    }

    $self->{clacks}->store($key, $data);

    return 1;
}

sub delete { ## no critic(BuiltinHomonyms)
    my ($self, $key) = @_;

    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    $self->{clacks}->remove($key);
    return 1;
}

sub incr {
    my ($self, $key, $stepsize) = @_;

    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    if(!defined($stepsize)) {
        $self->{clacks}->increment($key);
    } else {
        $self->{clacks}->increment($key, $stepsize);
    }
    return 1;
}

sub decr {
    my ($self, $key, $stepsize) = @_;

    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    if(!defined($stepsize)) {
        $self->{clacks}->decrement($key);
    } else {
        $self->{clacks}->decrement($key, $stepsize);
    }
    return 1;
}

sub clacks_set {
    my ($self, $key, $data) = @_;

    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    $self->{clacks}->set($key, $data);

    return 1;
}

sub clacks_notify {
    my ($self, $key) = @_;

    $self->reconnect(); # Make sure we are connected

    $key = $self->sanitize_key($key);

    $self->{clacks}->set($key);

    return 1;
}

sub clacks_keylist {
    my ($self) = @_;

    $self->reconnect(); # Make sure we are connected

    return $self->{clacks}->keylist();
}


sub sanitize_key {
    my ($self, $key) = @_;

    # Certain chars are not allowed in keys for protocol reason.
    # We handle this by substituting them with a tripple underline

    $key =~ s/\ /___/go;
    $key =~ s/\=/___/go;

    return $key;
}

sub deref {
    my ($self, $val) = @_;

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



=head1 DESCRIPTION

This implements the memcached-like client for the CLACKS interprocess messaging protocol.

=head1 IMPORTANT NOTE

Please make sure and read the documentations for L<Net::Clacks> as it contains important information
pertaining to upgrades and general changes!

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2019 Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
