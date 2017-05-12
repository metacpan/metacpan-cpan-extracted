use strict;
use warnings;

package Mojolicious::Plugin::DigestAuth::DB;

sub get
{
    my ($self, $realm, $user) = @_;    
    return unless defined $realm and defined $user;
    $self->{users}->{$realm}->{$user};
}

package Mojolicious::Plugin::DigestAuth::DB::File;

our @ISA = 'Mojolicious::Plugin::DigestAuth::DB';
use Carp 'croak';

sub new
{
    my ($class, $file) = @_;
    croak 'usage: ', __PACKAGE__, '->new(FILE)' unless $file;
   
    local $_;
    my $users = {};

    open my $passwords, '<', $file or croak "error opening digest file '$file': $!";

    while(<$passwords>) {
	chomp;
	next unless $_;
	
	# user:realm:hashed_password
	my @user = split ':', $_, 3;
	if(@user != 3 || length $user[1] == 0) {
	    croak "password file '$file' contains an invalid entry: $_";
	}
	
	$users->{$user[1]}->{$user[0]} = $user[2];	    
    }

    bless { users => $users }, $class;
}

package Mojolicious::Plugin::DigestAuth::DB::Hash;

our @ISA = 'Mojolicious::Plugin::DigestAuth::DB';

use Carp 'croak';
use Mojolicious::Plugin::DigestAuth::Util 'checksum';

sub new
{
    my ($class, $config) = @_;
    croak 'usage: ', __PACKAGE__, '->new(HASH)' unless $config and ref $config eq 'HASH';

    my $users;
    for my $realm (keys %$config) {
	croak "config for realm '$realm' is invalid: values must be a HASH" unless ref $config->{$realm} eq 'HASH';
	while(my ($user, $password) = each %{$config->{$realm}}) {
	  $users->{$realm}->{$user} = checksum($user, $realm, $password);
	}
    }

    bless { users => $users }, $class;
}

1;
