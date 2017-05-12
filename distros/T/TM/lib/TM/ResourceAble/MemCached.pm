package TM::ResourceAble::MemCached::mid2iid;

use Tie::Hash;
use base qw(Tie::StdHash);

sub TIEHASH {
    my $class = shift;
    my $memd = shift;

#    warn "TIEHASH toplet";
    my $self = bless { memd => $memd }, $class;
    $self->{mid2iid} = $self->{memd}->get ("mid2iid_all");
    return $self;
}

sub STORE {
    my ($self, $key, $val) = @_;
#    warn "STORE toplet $key";
    $self->{memd}->set ("mid2iid:$key", $val);
    $self->{mid2iid}->{$key}++;
}

sub FETCH {
    my ($self, $key) = @_;
#    warn "FETCH toplet $key";
    return $self->{memd}->get ("mid2iid:$key");
}

sub FIRSTKEY {
    my ($self) = @_;
#    warn "FIRSTKEY toplet";
    my $a = keys %{$self->{mid2iid}};          # reset each() iterator
    each %{$self->{mid2iid}}
}

sub NEXTKEY {
    my ($self, $key) = @_;
#    warn "NEXTKEY toplet $key";
    return each %{$self->{mid2iid}}
}

sub DESTROY {
    my ($self) = @_;
#    warn "DESTROYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY";

#    warn Dumper $self->{assertions};
    $self->{memd}->set ("mid2iid_all", $self->{mid2iid});
}

1;

package TM::ResourceAble::MemCached::assertions;

use Tie::Hash;
use base qw(Tie::StdHash);

use Data::Dumper;

sub TIEHASH {
    my $class = shift;
    my $memd = shift;

#    warn "TIEHASH assert";
    my $self = bless { memd => $memd }, $class;
    $self->{assertions} = $self->{memd}->get ("assertions_all");
#    warn "after tie ".Dumper $self->{assertions};
    return $self;
}

sub STORE {
    my ($self, $key, $val) = @_;
#    warn "STORE assert $key";
    $self->{memd}->set ("assertions:$key", $val);
    $self->{assertions}->{$key}++;
}

sub FETCH {
    my ($self, $key) = @_;
#    warn "FETCH assert $key";
    return $self->{memd}->get ("assertions:$key");
}

sub FIRSTKEY {
    my ($self) = @_;
#    warn "FIRSTKEY assert";
    my $a = keys %{$self->{assertions}};          # reset each() iterator
    each %{$self->{assertions}}
}

sub NEXTKEY {
    my ($self, $key) = @_;
#    warn "NEXTKEY assert $key";
    return each %{$self->{assertions}}
}

sub DESTROY {
    my ($self) = @_;
#    warn "DESTROYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY";
#    warn Dumper $self->{assertions};
    $self->{memd}->set ("assertions_all", $self->{assertions});
}

1;

package TM::ResourceAble::MemCached::main;

use Tie::Hash;
use base qw(Tie::StdHash);

use Data::Dumper;

sub TIEHASH {
    my $class = shift;
    my $memd = shift;

#    warn "TIEHASH main";
    return bless { memd => $memd }, $class;
}

sub FETCH {
    my ($self, $key) = @_;
#    warn "main FETCH $key";
    if ($key eq 'assertions') {
	$self->{__assertions} ||= {};
	return $self->{__assertions};

    } elsif ($key eq 'mid2iid') {
	$self->{__mid2iid} ||= {};
	return $self->{__mid2iid};

    } else {
	return $self->{memd}->get ($key);
    }
}

sub STORE {
    my ($self, $key, $val) = @_;
#    warn "main STORE $key";
    if ($key eq 'assertions') {
	$self->{__assertions} = $val;

    } elsif ($key eq 'mid2iid') {
	$self->{__mid2iid} = $val;

    } else {
	$self->{memd}->set ($key, $val);
    }
}

1;

package TM::ResourceAble::MemCached;

use strict;
use warnings;

use Data::Dumper;

use TM;
use base qw(TM);
use Class::Trait qw(TM::ResourceAble);

=pod

=head1 NAME

TM::ResourceAble::MemCached - Topic Maps, Memcached server backend

=head1 SYNOPSIS

    use TM::ResourceAble::MemCached;
    use Fcntl;
    # create/reset new map
    my $tm = new TM::ResourceAble::MemCached (
                baseuri => 'http://whereever/', 
		servers => [ localhost:11211 ],
		mode    => O_TRUNC | O_CREAT,
	     );

    # use TM interface
    
    # open existing map
    my $tm = new TM::ResourceAble::MemCached (
                 baseuri => 'http://whereever/', 
		 servers => [ localhost:11211 ],
             );

=head1 DESCRIPTION

This package implements L<TM> using a memcached server farm as backend. You should be able (without
much testing, mind you, so it is EXPERIMENTAL) to perform all operations according to the L<TM>
interface. 

B<NOTE>: The implementation is using the TIE technique (L<perltie> via L<Tie::StdHash>), so maybe
there are problems lurking.

Of course, a set of memcacheds can store any number of maps. To keep them separate, the baseuri
is used, so make sure every map gets its own baseuri.

=head1 INTERFACE

=head2 Constructor

The constructor expects a hash with the following keys:

=over

=item B<servers> (default: none)

The value must be a reference to an array of strings, each of the form I<host>:I<port>. If there
is no such list, then the constructor will fail.

=item B<mode> (default: O_CREAT)

The value must be a value from L<Fcntl> to control

=over

=item

whether the map should be created (C<O_CREAT>) when it does not exist, and/or

=item

whether the map should be cleared (C<O_TRUNC>) when it existed before.

=back

=back

All other options are passed to the constructor chain of traits (L<TM::ResourceAble>) and
superclasses (L<TM>).

=cut

sub new {
    my $class = shift;
    my %options = @_;

    my $servers = delete $options{servers} || die "no servers specified";
    use Fcntl;
    my $mode    = delete $options{mode}    || O_CREAT;
    my $tmp     = bless $class->SUPER::new (%options), $class;

    use Cache::Memcached;
    my $memd = new Cache::Memcached {
	'servers'   => $servers,
	'namespace' => $tmp->baseuri,
    };

    my %self;
    tie %self,                  'TM::ResourceAble::MemCached::main',       $memd;
    tie %{ $self{assertions} }, 'TM::ResourceAble::MemCached::assertions', $memd;
    tie %{ $self{mid2iid} },    'TM::ResourceAble::MemCached::mid2iid',    $memd;

#    warn "in new ".Dumper \%self;

    if ($self{baseuri}) {                                                        # there are already values there
	if ($mode & O_TRUNC) {                                                   # if we want an empty slate
	    $self{assertions} = {};
	    map { $self{assertions}->{$_} = $tmp->{assertions}->{$_} }
		    keys %{ $tmp->{assertions} };
	    $self{mid2iid} = {};
	    map { $self{mid2iid}->{$_} = $tmp->{mid2iid}->{$_} }
		    keys %{ $tmp->{mid2iid} };
	}

    } elsif ($mode & O_CREAT) {                                                  # careful cloning from prototypical TM
        foreach my $k (keys %$tmp) {
	    if ($k eq 'assertions') {
		map { $self{assertions}->{$_} = $tmp->{assertions}->{$_} }
		    keys %{ $tmp->{assertions} };

	    } elsif ($k eq 'mid2iid') {
		map { $self{mid2iid}->{$_} = $tmp->{mid2iid}->{$_} }
		    keys %{ $tmp->{mid2iid} };

	    } else {
		$self{$k} = $tmp->{$k};
	    }
        }
    } else {
	die "no map on servers";
    }

    return bless \%self, $class;
}

=pod

=head1 SEE ALSO

L<TM>, L<TM::ResourceAble>

=head1 AUTHOR INFORMATION

Copyright 2010, Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.02';

1;

__END__
