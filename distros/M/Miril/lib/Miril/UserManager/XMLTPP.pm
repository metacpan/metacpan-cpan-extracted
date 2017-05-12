package Miril::UserManager::XMLTPP;

use strict;
use warnings;
use autodie;

use XML::TreePP;
use Digest::MD5;
use List::Util qw(first);
use Data::AsObject qw(dao);
use Ref::List qw(list);
use Try::Tiny qw(try catch);
use Miril::Exception;

sub new { 
	my $class = shift;
	my $miril = shift;

	my $self = bless {}, $class;

	$self->{miril} = $miril;
	my $cfg = $miril->cfg;


	my $tpp = XML::TreePP->new();
	$tpp->set( indent => 2 );
	$tpp->set( force_array => ['user'] );
    my $tree;

	try 
	{
		$tree = $tpp->parsefile( $cfg->users_data );
	} 
	catch 
	{
		Miril::Exception->throw(
			message  => "Could not parse users file", 
			errorvar => $_,
		);
	};

	my @users = dao list $tree->{xml}{user};
	$self->{users} = \@users;

	$self->{tree} = $tree;
	$self->{tpp} = $tpp;
	$self->{xml_file} = $cfg->users_data;

	return $self;
}

sub verification_callback {
	my $self = shift;

	return sub {
		my ($username, $password) = @_;
		my $user = $self->get_user($username);
	
		my $encrypted = $self->encrypt($password);

		if ( 
			   ( $encrypted eq $user->{password} ) 
			or ( $password  eq $user->{password} )
		) {
			return $username;
		} else {
			return;
		}
	}
}

sub get_user {
	my $self = shift;
	my $username = shift;

	my $user = first {$_->username eq $username} $self->users;
	return $user;
}

sub set_user {
	my $self = shift;
	my $user = shift;
	
	my $miril = $self->miril;

	my @users = $self->users;

	my $found = undef;
	
	# try update
	for my $u (@users) 
	{
		if ($u->username eq $user->username) 
		{
			$u->{password} = $user->password;
			$u->{name}     = $user->name;
			$found++;
			last;
		}
	}

	# try create
	if (!$found) {
		my $new_user = dao {
			username => $user->username,
			password => $user->password,
			name     => $user->name,
		};
		
		push @users, $new_user;
	}
	
	# update the xml file
	my $new_tree = $self->tree;
	$new_tree->{xml}->{user} = \@users;
	$self->{tree} = $new_tree;
	try 
	{
		$self->tpp->writefile($self->xml_file, $new_tree);
	} 
	catch 
	{
		Miril::Exception->throw(
			message  => "Could not update user info", 
			errorvar => $_,
		);
	};
}

sub delete_user {
	my $self = shift;
	my $username = shift;

	my $miril = $self->miril;

	my @users = $self->users;
	
	my $i = -1;
	for (@users) {
		$i++;
		last if $_->username eq $username;
	}
	
	if ($i != -1) {
		splice(@users, $i, 1);
	}

	my $new_tree = $self->tree;
	$new_tree->{xml}{user} = \@users;
	$self->{tree} = $new_tree;
	try 
	{
		$self->tpp->writefile($self->xml_file, $new_tree);
	} 
	catch 
	{
		Miril::Exception->throw(
			message  => "Could not delete user", 
			errorvar => $_,
		);
	};
}

sub encrypt 
{
	my $self = shift;
	my $password = shift;

	# only Digest::MD5 is available in core perl 5.8
	my $md5 = Digest::MD5->new;
	$md5->add($password);
	my $digest = $md5->b64digest; 
	return $digest;
}

### ACCESSORS ###

sub users    { @{ shift->{users} };  }
sub tree     { shift->{tree};        }
sub tpp      { shift->{tpp};         }
sub xml_file { shift->{xml_file};    }
sub miril    { shift->{miril};       }

1;
