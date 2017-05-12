#
#  Copyright 2009 10gen, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

package MongoDB::Async::Pool;
our $VERSION = '0.2';

use MongoDB::Async;
use Scalar::Util qw/weaken/;
use strict;
use Devel::GlobalDestruction;
use EV;
use Coro;

=head1 NAME

MongoDB::Async::Pool - Pool of connections

=head1 SYNOPSIS

You can't use one connection in several coro's because one coro can try send query while other coro waiting for response from already running query. Creating new connection for every coroutine might be slow, so this module caches connections for you.

	
	my $pool = MongoDB::Async::Pool->new({}, { timeout => 0, max_conns => 50 });
	
	async { 
		my $big_data = $pool->get->testdb->testcoll->find({ giveme => 'large dataset'})->data;
	};
	
	async { 
		my $big_data = $pool->get->testdb->testcoll->find({ giveme => 'another large dataset'})->data;
	};
	
	#it's good idea to cache connection in variable if you going to use it several times
	
	async {	
		my $connection = $pool->get;
		
		# do queries
	};
	
	
	
	EV::run;
	

=head1 METHODS

=head2 new({ MongoDB::Async::MongoClient args }, { MongoDB::Async::Pool attrs });

Creates pool of L<MongoDB::Async::Connection> objects

=head2 $pool->get;

Returns L<MongoDB::Async::MongoClient> object from pool or creates new connection if pool is empty. Might block current coro until some coro return connection if pool is empty and "max_conns" connections currently in use. You needn't think about returning object to pool, it`ll be returned on DESTROY 

ATTRIBUTES:

=head3 ->max_conns , ->max_conns(new value)

Max connection count. ->get will block current coroutine when max_conns reached. Not recomended to change it in runtime. Default: 0 - no limit

=head3 ->timeout , ->timeout(new value)
One unused connection will be closed every "timeout" sec. 0 - don`t close Default: 10. Requries running EV::loop

=head3 ->connections_in_use

=head3 ->connections_in_pool

=cut


sub connections_in_use {$_[0]->{connections_in_use}}
sub connections_in_pool {$_[0]->{connections_in_pool}}

sub max_conns { 
	my $retval = $_[0]->{max_conns}; 
	
	if(defined $_[1]){
		$_[0]->{max_conns} = $_[1];
		$_[0]->{max_conns_sem} = $_[0]->{max_conns} ? Coro::Semaphore->new($_[0]->{max_conns}) : undef;
	}
	
	$retval;
 }
 
sub timeout { 
	my $self = $_[0];
	my $retval = $self->{timeout};
	if(defined $_[1]){
		$self->{timeout_watcher} =
			$self->{timeout} ? 
				(EV::timer $self->{timeout}, $self->{timeout}, sub {
					my $conn;
					if( $conn = shift @{$self->{pool}}){
						delete $conn->{_parent_pool}
					} else {
						$self->{timeout_watcher}->stop;
					}
					
					$self->{connections_in_pool} = int @{$self->{pool}};
				})
				:
				undef;
	}
	$retval
}


sub new {
	my $self = bless( ($_[2] || {}), $_[0] );
	
	$self->{conn_args} = $_[1] || {};
	
	$self->timeout($self->{timeout} // 0);
	$self->max_conns($self->{max_conns} // 0);
	
	$self->{connections_in_use} = 0;
	$self->{connections_in_pool} = 0;
	
	
	$self->{pool} = [];
	
	$self;
}


sub pop {
	my ($self) = @_;
	
	
	$self->{max_conns_sem}->down if $self->{max_conns_sem};
	
	my $conn;
	unless( $conn = pop @{$self->{pool}} ){
		
		$conn = MongoDB::Async::MongoClient->new($self->{conn_args});
		
	
		$conn->{_parent_pool} = $self;
		weaken( $conn->{_parent_pool} );
		
		
		$self->{init}->($conn) if($self->{init});
	}
	
	$self->{connections_in_use}++;	
	$self->{connections_in_pool} = int @{$self->{pool}};
	
	return $conn;
}


sub return {
	my ($self, $conn) = @_;
	
	push @{$self->{pool}}, $conn;
	$self->{connections_in_use}--;
	$self->{connections_in_pool}++;
	
	$self->{timeout_watcher}->start if $self->{timeout_watcher};
	$self->{max_conns_sem}->up if $self->{max_conns_sem};
}



*get = \&pop;
*AUTOLOAD = \&pop;

1;