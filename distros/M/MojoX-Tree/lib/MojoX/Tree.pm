package MojoX::Tree;
use Mojo::Base -base;
use Mojo::Util qw(dumper);
use Mojo::Collection 'c';
use DBI;
use Carp qw(croak);
  
our $VERSION  = '0.06';

sub new {
	my $class = shift;
	my %args = @_;

	my $config = {};
	if(exists $args{'mysql'} && $args{'mysql'} && ref $args{'mysql'} eq 'MojoX::Mysql'){
		$config->{'mysql'} = $args{'mysql'};
	}
	else{
		croak qq/invalid MojoX::Mysql object/;
	}

	if(exists $args{'table'} && $args{'table'} && $args{'table'} =~ m/^[0-9a-z_-]+$/i){
		$config->{'table'} = $args{'table'};
	}
	else{
		croak qq/invalid table/;
	}

	if(exists $args{'column'} && $args{'column'} && ref $args{'column'} eq 'HASH'){
		$config->{'column'} = $args{'column'};
	}
	else{
		croak qq/invalid column/;
	}

	if(exists $args{'length'} && $args{'length'} && $args{'length'} =~ m/^[0-9]+$/){
		$config->{'length'} = $args{'length'};
	}
	else{
		croak qq/invalid column/;
	}


	return $class->SUPER::new($config);
}

sub mysql {
	return shift->{'mysql'};
}

sub add {
	my ($self,$name,$parent_id) = @_;

	my $table = $self->{'table'};
	my $column_id        = $self->{'column'}->{'id'};
	my $column_name      = $self->{'column'}->{'name'};
	my $column_path      = $self->{'column'}->{'path'};
	my $column_level     = $self->{'column'}->{'level'};
	my $column_parent_id = $self->{'column'}->{'parent_id'};

	my $parent_path = undef;
	if(defined $parent_id && $parent_id){
		my $get_id = $self->get_id($parent_id);
		$parent_path = $get_id->{$column_path};
	}

	croak "invalid name" if(!$name);

	# Создаем запись
	my ($insertid,$counter) = $self->mysql->do("INSERT INTO `$table` (`$column_name`) VALUES (?)", $name);

	# Формируем материлизованный путь
	my $path = $self->make_path($insertid);

	$path = $parent_path.$path if(defined $parent_path);
	my $level = $self->make_level($path); # Узнает текущий уровень

	my (undef,$update_counter) = $self->mysql->do(
		"UPDATE `$table` SET `$column_path` = ?, `$column_level` = ?, `$column_parent_id` = ? WHERE `$column_id` = ?;",
		$path,$level,$parent_id,$insertid
	);

	croak "invalid update table" if($update_counter != 1);
	return $insertid;
}

# Удаляет текущего элемент и детей
sub delete {
	my ($self,$id) = @_;

	my $path = undef;
	my $get_id = $self->get_id($id);
	if(defined $get_id){
		$path = $get_id->{'path'};
	}
	else{
		croak "invalid id:$id";
	}

	my $table       = $self->{'table'};
	my $column_path = $self->{'column'}->{'path'};
	my ($insertid,$counter) = $self->mysql->do("DELETE FROM `$table` WHERE `$column_path` LIKE '$path%';");
	if($counter > 0){
		return $counter;
	}
	else{
		croak "Unable to delete";
	}
}

sub move {
	my ($self,$id,$target_id) = @_;
	my $table = $self->{'table'};
	my $column_id        = $self->{'column'}->{'id'};
	my $column_name      = $self->{'column'}->{'name'};
	my $column_path      = $self->{'column'}->{'path'};
	my $column_level     = $self->{'column'}->{'level'};
	my $column_parent_id = $self->{'column'}->{'parent_id'};

	my $get_id = $self->get_id($id);
	croak "invalid id:$id" if(!defined $id);

	my $get_target_id = $self->get_id($target_id);
	croak "invalid id:$get_target_id" if(!defined $get_target_id);

	croak "Impossible to transfer to itself or children" if($id eq $target_id);

	my $path        = $get_id->{$column_path};
	my $path_target = $get_target_id->{$column_path};
	croak "Impossible to transfer to itself or children" if($path =~ m/^$path_target/);

	my $length = $self->{'length'};
	my $collection = $self->mysql->query("SELECT `$column_id` as `id`, `$column_path` as `path` FROM `$table` WHERE `$column_path` LIKE '$path%';");
	$collection->each(sub {
		my $e = shift;
		my $id = $e->{'id'};
		if($e->{'path'} =~ m/(?<path>($path\d*))/g){
			my $path = $path_target.$+{'path'};
			my $level = $self->make_level($path);

			my $parent_id = 'NULL';
			$parent_id = int $+{'parent_id'} if($path =~ m/(?<parent_id>(\d{$length}))\d{$length}$/);
			$self->mysql->do("UPDATE `$table` SET `$column_path` = ?, `level` = ?, `$column_parent_id` = ? WHERE `$column_id` = ?",$path,$level,$parent_id,$id);
		}
	});
}

# Получение очереди по id
sub get_id {
	my ($self,$id) = @_;

	my $table = $self->{'table'};
	my $column_id        = $self->{'column'}->{'id'};
	my $column_name      = $self->{'column'}->{'name'};
	my $column_path      = $self->{'column'}->{'path'};
	my $column_level     = $self->{'column'}->{'level'};
	my $column_parent_id = $self->{'column'}->{'parent_id'};

	my ($collection,$counter) = $self->mysql->query("SELECT `$column_id`, `$column_path`, `$column_name`, `$column_level`, `$column_parent_id` FROM `$table` WHERE `$column_id` = ? LIMIT 1", $id);
	croak "invalid id:$id" if($counter eq '0E0');

	my $result = $collection->last;

	# Получаем всех детей
	my $path  = $result->{$column_path};
	my $level = $result->{$column_level};
	$result->{'children'} = $self->mysql->query("
		SELECT `$column_id`, `$column_path`, `$column_name`, `$column_level`, `$column_parent_id` FROM `$table`
		WHERE `$column_path` LIKE '$path%' AND `$column_level` != ?
	",$level);

	# Получаем всех родителей
	my @parent = ();
	my $length = $self->{'length'};
	for(($path =~ m/(\d{$length})/g)){
		push(@parent, int $_);
	}
	@parent = grep(!/$id/, @parent);
	my $parent = join(",",@parent);

	if(defined $parent && $parent){
		$parent = $self->mysql->query("SELECT `$column_id`, `$column_path`, `$column_name`, `$column_level`, `$column_parent_id` FROM `$table` WHERE `$column_id` IN($parent)");
	}
	else {
		$parent = c();
	}

	$result->{'parent'} = $parent;
	return $result;
}

sub make_path {
	my ($self,$id) = @_;
	my $length = $self->{'length'};
	my $length_id = length $id;
	if($length_id < $length){
		my $zero = '0' x ($length - $length_id);
		$id = $zero.$id;
	}
	return $id;
}

sub make_level {
	my ($self,$path) = @_;
	my $length = $self->{'length'};
	my @counter = ($path =~ m/([0-9]{$length})/g);
	return scalar @counter;
}


1;

__END__

=encoding utf8

=head1 NAME

MojoX::Tree - Mojolicious ♥ Tree
 
=head1 SYNOPSIS

    use MojoX::Tree;
    use MojoX::Mysql;
    use Mojo::Util qw(dumper);

    my %config = (
        user=>'root',
        password=>undef,
        server=>[
            {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master'},
            {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
        ]
    );

    my $mysql = MojoX::Mysql->new(%config);
    my $tree = MojoX::Tree->new(
        mysql=>$mysql,
        table=>'tree',
        length=>10,
        column=>{
            id=>'tree_id',
            name=>'name',
            path=>'path',
            level=>'level',
            parent_id=>'parent_id'
        }
    );


=head1 DESCRIPTION

MojoX::Tree - Implementation of the materialized path for the Mojolicious real-time web framework.

=head1 METHODS

=head2 add

    my $id = $tree->add('name'); # create root branch

    $tree->add('name', $id); # sub branch

=head2 delete

    $tree->delete(1); # delete branch and sub branch

=head2 move

    $tree->move(1,2); # move branch (1) to branch (2)

=head2 get_id

    say dumper $tree->get_id(1); # get branch (1)

=head1 EXAMPLE TABLE

    CREATE TABLE `tree` (
        `tree_id` int(14) unsigned NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `path` mediumtext NOT NULL,
        `level` int(14) unsigned NOT NULL,
        `parent_id` int(14) unsigned NULL,
        PRIMARY KEY (`tree_id`),
        KEY `path` (`path`(30))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

=head1 Mojolicious Plugin

SEE ALSO L<Mojolicious::Plugin::Tree>

=head1 TODO

    1.Move root
    2.Get all tree

=head1 AUTHOR

Kostya Ten, C<kostya@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Kostya Ten.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache License version 2.0.

=cut

