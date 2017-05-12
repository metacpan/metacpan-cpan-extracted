package TM::ResourceAble::BDB::main;

use strict;
use warnings;

use Tie::Hash;
use base qw(Tie::StdHash);

sub FETCH {
    my ($self, $key) = @_;
#warn "FETCH main  $key";
    if ($key eq 'assertions' || $key eq 'mid2iid') {
	return $self->{$key};                                              # where the BDB is tied to
    } elsif ($key eq 'index') {                                            # not part of this game
	return $self->{'index'};
    } elsif ($key eq 'variants') {                                         # not part of this game
	return $self->{'variants'};
    } elsif ($key eq '__main') {                                           # dont like being asked about that
	return $self->{'__main'};
    } else {
	return $self->{'__main'}->{$key};                                  # get it from the secret store
    }
}

sub STORE {
    my ($self, $key, $val) = @_;
#warn "STORE main $key $val";
    if ($key eq 'assertions' || $key eq 'mid2iid') {
	$self->{$key} = $val;                                              # those go directly into the hash
    } elsif ($key eq 'index') {                                            # not part of this game
	$self->{'index'} = $val;
    } elsif ($key eq 'variants') {                                         # not part of this game
	$self->{'variants'} = $val;      # memory-only, will not be persisted, THIS IS A BUG
    } elsif ($key eq '__main') {                                           # this is *directly* store (the value being a tied hash)
	$self->{'__main'} = $val;
    } else {
	$self->{'__main'}->{$key} = $val;                                  # those will be redirected into the tied store
    }
}

1;

package TM::ResourceAble::BDB;

use strict;
use warnings;

use Data::Dumper;

use TM;
use base qw(TM);
use Class::Trait ('TM::ResourceAble');


sub new {
    my $class = shift;
    my %options = @_;

    my $file = delete $options{file} or die "file?";
    $options{url} = "file:$file";

    my %self;
    tie %self, 'TM::ResourceAble::BDB::main', "$file.main";

    use BerkeleyDB;
    my %flags = (-Flags => DB_CREATE ) unless -e "$file.main" && -s "$file.main";

#    warn Dumper \%flags;

    my $dbm = tie %{ $self{'__main'} },   'BerkeleyDB::Hash',
                                          -Filename => "$file.main", %flags;

#    $dbm->filter_store_value ( sub { 
#	warn "really storing $_ into __main";
#	$_;
#			       } ) ;
#    $dbm->filter_fetch_value ( sub { 
#	warn "really getting $_ from __main";
#	$_;
#			       } ) ;


    my $dba = tie %{ $self{assertions} }, 'BerkeleyDB::Hash',
                                          -Filename => "$file.assertions", %flags;

    $dba->filter_store_value ( sub { 
	use Storable qw(freeze);
	$_ = freeze ($_);
			       } ) ;
    $dba->filter_fetch_value ( sub { 
	use Storable qw(thaw);
	$_ = thaw ($_);
			       } ) ;
    my $dbt = tie %{ $self{mid2iid} },    'BerkeleyDB::Hash',
                                          -Filename => "$file.toplets", %flags;

    $dbt->filter_store_value ( sub { 
	use Storable qw(freeze);
	$_ = freeze ($_);
			       } ) ;
    $dbt->filter_fetch_value ( sub { 
	use Storable qw(thaw);
	$_ = thaw ($_);
			       } ) ;

    unless (defined $self{last_mod}) { # empty? => careful cloning from prototypical TM
#warn "initializing BDB";
	my $tmp = bless $class->SUPER::new (%options), $class;
	foreach my $k (keys %$tmp) {
	    if ($k eq 'mid2iid') {
		my $mid2iid = $self{mid2iid}; # fetch once
		$mid2iid->{$_} = $tmp->{mid2iid}->{$_} for keys %{ $tmp->{mid2iid} };
		$self{mid2iid} = $mid2iid;

	    } elsif ($k eq 'assertions') {
		my $asserts = $self{assertions};
		$asserts->{$_} = $tmp->{assertions}->{$_} for keys %{ $tmp->{assertions} };
		$self{assertions} = $asserts;

	    } else {
		$self{$k} = $tmp->{$k};
	    }
	}
    }
    return bless \%self, $class;
}

1;

__END__

sub xDESTROY {
    my $self = shift;
    warn "DESTROY BDB";
    untie %{ $self->{mid2iid} };
    untie %{ $self->{assertions} };
    untie %{ $self->{'__main'} };
}

