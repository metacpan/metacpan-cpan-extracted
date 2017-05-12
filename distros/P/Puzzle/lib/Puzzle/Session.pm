package Puzzle::Session;

our $VERSION = '0.02';


use Params::Validate qw(:types);;
use base 'Class::Container';

our $mod_version;

eval { require Apache2::Cookie };
$modperl_version = $@ ? undef : 2;
unless ($modperl_version) {
	eval {require Apache::Cookie };
	$modperl_version = $@ ? undef : 1;
}
unless ($modperl_version) {
	die 'Prerequisite Apache::Cookie or Apache2::Cookie not found';
}


BEGIN {
	__PACKAGE__->valid_params(
		user 		=> { isa 		=> 'Puzzle::Session::User' },
		auth 		=> { isa 		=> 'Puzzle::Session::Auth' },
	);

	__PACKAGE__->contained_objects (
		user		=> 'Puzzle::Session::User',
		auth		=> 'Puzzle::Session::Auth',
	);
}

# all new valid_params are read&write methods
use HTML::Mason::MethodMaker(
				read_only		=> [qw(_session_id user internal_session auth)],
				read_write => [ 
					[date => { parse => 'string' , type => SCALAR }],
				]
				
);

sub AUTOLOAD {
	my $self	= shift;
	my $key = $AUTOLOAD;
	$key =~ s/.*:://;
	if (@_) {
		$self->{internal_session}->{$key} = shift;
	} else {
		return $self->{internal_session}->{$key};
	}
}

sub save {
	my $self			= shift;
	# chiamo la stessa funzione sui contained objects
	$self->date(localtime() . '');
	$self->_obj2hash;
	$self->user->save;
	untie %{$self->{internal_session}};
}

sub load {
	my $self					= shift;
	my $dbcfg	= $self->container()->cfg->db;
	my $session_name  = "puzzle.$ENV{SERVER_NAME}";
	my $r = $self->container->_mason->apache_req or die "Unable to get Apache request handler";
	my %c = $modperl_version == 2 ? Apache2::Cookie->fetch($r) : Apache::Cookie->fetch;
	my $sid = exists $c{$session_name} ? $c{$session_name}->value : undef;
	my %db_params = (
		Handle		=> $self->container()->dbh->storage->dbh,
		LockHandle	=> $self->container()->dbh->storage->dbh
	);
	# will get an existing session from a cookie, or create a new session
	# and cookie if needed
	eval {
		tie %{$self->{internal_session}}, 'Apache::Session::MySQL',$sid,\%db_params;
	};
	if ($@) {
		die $@ unless $@ =~ /Object does not exist/;
		# L'id non esiste piu' nel database, creo un nuovo id;
		undef $sid;
		tie %{$self->{internal_session}}, 'Apache::Session::MySQL', $sid,\%db_params
	}
	if ($modperl_version == 2) {
		Apache2::Cookie->new( 	$r,
								name	=> $session_name,
								value	=> $self->{internal_session}->{_session_id},
								path	=> '/',
							)->bake($r) unless (defined $sid);
	} else {
		Apache::Cookie->new( 	$r,
								name	=> $session_name,
								value	=> $self->{internal_session}->{_session_id},
								path	=> '/',
							)->bake unless (defined $sid);
	}
	# sync tied hash with object methods
	$self->_hash2obj;
	# call same funzion on contained objects
	$self->user->load;
}

sub delete {
	my $self	= shift;
	my $key		= shift;
	delete $self->internal_session->{$key};
}

sub _hash2obj {
	my $self			= shift;
	foreach (qw/_session_id date/) {
		if (exists $self->internal_session->{$_}) {
			$self->{$_}		= $self->internal_session->{$_};
		} else {
			delete $self->{$_};
		}
	}
}

sub _obj2hash {
	my $self			= shift;
	foreach (qw/date/) {
		if (exists $self->{$_}) {
			$self->internal_session->{$_}		= $self->{$_};
		} else {
			delete $self->internal_session->{$_};
		}
	}
}
1;
