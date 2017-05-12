package SQL::Template::Command;

=head1 NAME

SQL::Template::Command - Commands supported by SQL::Template

=cut

use strict;


sub new_from {
	my $p = shift;
	my $type      = $p->{XMLTYPE};
	my $params    = $p->{PARAMS};
	my $parent    = $p->{PARENT};
	my $previous  = $p->{PREVIOUS};
	my $container = $p->{CONTAINER};
	
	my $command;
	
	$command = SQL::Template::Command::Sql->new($params, $container, $parent, $previous)    if( $type eq 'st:sql' );
	$command = SQL::Template::Command::Select->new($params, $container, $parent, $previous) if( $type eq 'st:select' );
	$command = SQL::Template::Command::Do->new($params, $container, $parent, $previous)     if( $type eq 'st:do' );
	$command = SQL::Template::Command::List->new($params, $container, $parent, $previous)   if( $type eq 'st:list' );
	$command = SQL::Template::Command::If->new($params, $container, $parent, $previous)     if( $type eq 'st:if' );
	$command = SQL::Template::Command::Else->new($params, $container, $parent, $previous)   if( $type eq 'st:else' );
	$command = SQL::Template::Command::Param->new($params, $container, $parent, $previous)  if( $type eq 'st:param' );
	$command = SQL::Template::Command::Fragment->new($params, $container, $parent, $previous)  if( $type eq 'st:fragment' );
	$command = SQL::Template::Command::Include->new($params, $container, $parent, $previous)  if( $type eq 'st:include' );
	
	if( $command ) {
		##print "new command: ", ref($command), " parent=", ref($parent), "\n";
		return $command;
	}
	
	die "Unknown command: $type";
}

sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	my $self = bless {
					_PARENT    => $parent, 
					_LEVEL     => 0, 
					_COMMANDS  => [], 
					_DYNAMIC   => 0,
					_SQL       => '',
					_CONTAINER => $container,
					_PREVIOUS  => $previous
				}, $class;
	if( 'HASH' eq ref($params) ) {
		foreach my $key( keys %$params ) {
			$self->{uc($key)} = $params->{$key};
		}
	}
	$parent->add_command($self) if( $parent );
	#$self->previous($previous);
	return $self;
}

sub name {
	return $_[0]->{NAME};
}

sub container {
	return $_[0]->{_CONTAINER};
}

sub dynamic {
	if( @_ == 2 ) {
		$_[0]->{_DYNAMIC} = $_[1]; 
	}
	return $_[0]->{_DYNAMIC};
}

sub level {
	if( @_ == 2 ) {
		$_[0]->{_LEVEL} = $_[1]; 
	}
	return $_[0]->{_LEVEL};
}

sub previous {
	return $_[0]->{_PREVIOUS};
}

sub parent {
	my $self = shift;
	my $parent = shift;
	if( eval { $parent->isa("SQL::Template::Command") } ) {
		$self->{_PARENT} = $parent;
		$self->level( 1 + $parent->level() );
	}
	return $self->{_PARENT};
}

sub add_command {
	my $self = shift;
	my $command = shift;
	die "Invalid command: $command" if( !$command or eval {!$command->isa('SQL::Template::Command')} );
	$command->parent($self);
	$command->container( $self->container );
	##print "add command: ", ref($command), " level: ", $command->level, 
	##	" parent=", ref($self), " container=", ref($self->container), "\n";
	push @{ $self->{_COMMANDS} }, $command;
}

sub bindings {
	my $self = shift;
	my $params = shift;
	my $bindings = shift || {};
	
	$self->_iterate_childs( 
		sub {
			my $command = shift;
			$command->bindings($params, $bindings);
			return 1;
	});
	
	return $bindings;
}

sub sql {
	my ($self, $params) = @_;
	my $sql = $self->{_SQL};
	
	if( $self->dynamic or ($self->{_SQL} eq '') ) {
		$sql = '';
		$self->_iterate_childs( 
			sub {
				my $command = shift;
				$sql .= $command->sql($params, $sql);
				return 1;
		});
		$self->{_SQL} = $sql;
	}
	return $sql;
}

sub get_commands {
	return @{ $_[0]->{_COMMANDS} };
}

sub find_command {
	my $self = shift;
	my $name = shift;
	my $find = undef;
	$self->_iterate_childs( 
			sub {
				my $command = shift;
				if( $name eq $command->name ) {
					$find = $command;
					return 0;
				}
				return 1;
	});
	return $find;
}



sub dump {
	my $self = shift;
	my $padding = '  ' x $self->level();
	my $str;
	map {$str.= "$_: $self->{$_}; ";} grep /^[^_]/, keys(%$self);
	print $padding, ref($self), " $str\n";

	foreach my $command($self->get_commands) {
		$command->dump;
	}
}

sub _iterate_childs {
	my $self = shift;
	my $visit_sub = shift;
	if( $visit_sub ) {
		foreach my $command($self->get_commands) {
			my $continue = &$visit_sub($command);
			last if !$continue;
		}
	}
	
}

sub _iterate_parent_chain {
	my $self = shift;
	my $visit_sub = shift;
	if( $visit_sub ) {
		while( my $next_parent = $self->parent ) {
			my $continue = &$visit_sub($next_parent);
			last if !$continue;
		}
	}
}

#******************************************************************************

package SQL::Template::Command::Composite;
use base 'SQL::Template::Command';

sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	return $class->SUPER::new($params, $container, $parent, $previous);
}


#******************************************************************************

package SQL::Template::Command::Leaf;
use base 'SQL::Template::Command';

sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	return $class->SUPER::new($params, $container, $parent, $previous);
}

#******************************************************************************

package SQL::Template::Command::Sql;
use base 'SQL::Template::Command::Composite';

#******************************************************************************

package SQL::Template::Command::Sentence;
use base 'SQL::Template::Command::Composite';

#******************************************************************************

package SQL::Template::Command::Select;
use base 'SQL::Template::Command::Sentence';

sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	die "name parameter is mandatory" if( !exists $params->{name} );
	return $class->SUPER::new($params, $container, $parent, $previous);
}

#******************************************************************************

package SQL::Template::Command::Do;
use base 'SQL::Template::Command::Sentence';


sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	die "name parameter is mandatory" if( !exists $params->{name} );
	return $class->SUPER::new($params, $container, $parent, $previous);
}

#******************************************************************************

package SQL::Template::Command::Fragment;
use base 'SQL::Template::Command::Composite';


sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	die "name parameter is mandatory" if( !exists $params->{name} );
	return $class->SUPER::new($params, $container, $parent, $previous);
}

sub clone {
	my $self = shift;
	my $fragment = {};
	foreach my $key( keys %$self ) {
		$fragment->{$key} = $self->{$key};
	}
	bless $fragment, __PACKAGE__;
	return $fragment;
}


#******************************************************************************

package SQL::Template::Command::Text;
use base 'SQL::Template::Command::Leaf';

sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	my $self = $class->SUPER::new($params, $container, $parent, $previous);
	#Sustitution of params
	#$self->{TEXT} =~ s!\${\w+}\b!#$1#!g;
	return $self;
}

sub bindings {
	my $self = shift;
	my $params = shift;
	my $bindings = shift || {};
	my @matches = $self->sql =~ /\$\{\s*(\w+)\s*\}/g;
	map { $bindings->{'${' . $_ . '}'} = $params->{$_}; } @matches;
	return $bindings;
}

sub sql {
	my ($self, $params, $sql) = @_;
	return " " . $self->{TEXT};
}

#******************************************************************************

package SQL::Template::Command::List;
use base 'SQL::Template::Command::Leaf';

sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	return $class->SUPER::new($params, $container, $parent, $previous);
}

sub _get_array_param {
	my ($self, $params) = @_;
	my $pname = $self->name;
	$pname =~ s!\$\{(\w+)\}!$1!;
	my $array = $params->{ $pname };
	die "parameter $pname must be an array reference with 1 or more elements" if( "ARRAY" ne ref($array) or @$array<1);
	return @$array
}

sub bindings {
	my $self = shift;
	my $params = shift;
	my $bindings = shift || {};
 	my @array = $self->_get_array_param($params);
	my $i = 0;
	map {$i++; $bindings->{ $self->name . "_$i"} = $_;} @array;
	return $bindings;
}

sub sql {
	my ($self, $params) = @_;
	
	my @array = $self->_get_array_param($params);
	my $i = 0;
	my $sql = " (" . join(", ", map {$i++; $self->name . "_$i"} @array) . ") ";
}

#******************************************************************************

package SQL::Template::Command::If;
use base 'SQL::Template::Command::Composite';

sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	my $self = $class->SUPER::new($params, $container, $parent, $previous);
	$self->_iterate_parent_chain( 
			sub { 
				#Set the parent chain to dynamic for performance purposes
				my $parent = shift;
				$parent->dynamic(1);
				return $parent->isa('SQL::Template::Command::Sentence') ? 0 : 1
	} );
	return $self
}

sub _test {
	my $self = shift;
	my $params = shift;
	my $test = $self->{TEST};
	no warnings 'uninitialized';
	$test =~ s!\$\{\s*(\w+)\s*\}!if( defined($1) && exists($params->{$1}) ) {$params->{$1}} else {undef}!ge;
	my $rc = eval "$test;";
	return $rc;
}

sub sql {
	my ($self, $params) = @_;
	return "" if( ! $self->_test($params) );
	my $sql;
	foreach my $command($self->get_commands) {
		$sql .= $command->sql($params);
	}
	$sql = " ($sql) "; 
	
	if( exists $self->{PREPEND} ) {
		$sql = " " . $self->{PREPEND} . $sql; 
	}
	
	return $sql;
}

#******************************************************************************

package SQL::Template::Command::Else;
use base 'SQL::Template::Command::Composite';

sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	my $self = $class->SUPER::new($params, $container, $parent, $previous);
	unless( eval { $self->previous->isa('SQL::Template::Command::If'); } ) {
		die "sm:else command must be after a sm:if command";
	}
	return $self;
}

sub sql {
	my ($self, $params) = @_;
	return "" if( $self->previous->_test($params) );
	my $sql;
	foreach my $command($self->get_commands) {
		$sql .= $command->sql($params);
	}
	if( exists $self->previous->{PREPEND} ) {
		$sql = " " . $self->previous->{PREPEND} . " ($sql) "; 
	}
	else {
		$sql = " ($sql) "; 
	}
	return $sql;
}

#******************************************************************************

package SQL::Template::Command::Param;
use base 'SQL::Template::Command';

sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	my $self = $class->SUPER::new($params, $container, $parent, $previous);
	$self->{NAME} =~ s!(:\w+)\b!#$1#!g;
	return $self;
}

sub bindings {
	my $self = shift;
	my $params = shift;
	my $bindings = shift || {};
	$self->name =~ /^#:(\w+)#/;
	my $key = $1;
	if( (! exists($bindings->{"#:$1#"})) or (ref($bindings->{"#:$1#"}) ne "ARRAY") ) { 
		$bindings->{"#:$1#"} = [$params->{$1}, $self->{TYPE} ];
	}
	return $bindings;
}

sub sql {
	my ($self, $params, $sql) = @_;
	return $self->name;
}

#******************************************************************************

package SQL::Template::Command::Include;
use base 'SQL::Template::Command';

sub new {
	my ($class, $params, $container, $parent, $previous) = @_;
	die "name parameter is mandatory" if( !exists $params->{name} );
	my $fragment = $parent->container->find_command($params->{name});
	die "fragment '" . $params->{name} . "' not found" if( !$fragment );
	
	my $include = $fragment->clone();
	$parent->add_command($include);
	return $include;
}



#******************************************************************************
#******************************************************************************

1;
