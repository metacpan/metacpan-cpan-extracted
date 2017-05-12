package Mojolicious::Command::sql;
use Mojo::Base 'Mojolicious::Command';
use FindBin;
use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Util qw(dumper encode);
use Mojo::Date;
use Term::ANSIColor;
use Mojo::Loader qw(data_section load_class);

has description => encode 'UTF-8', "sql data migrations\n";
has usage => <<EOF;

    usage: $0 sql [create|delete|update]

EOF

sub run {
	my ($self, $action, $id) = @_;
	$id = '_default' if(!defined $id);
	my $migration_list = $self->app->mysql->{'migration'}->{$id};
	return $self if(ref $migration_list ne 'ARRAY');

	my $all = {};
	for my $item (@{$migration_list}){
		my $e = load_class $item;
		warn qq{Loading "$item" failed: $e} if ref $e;
		my $item = data_section($item);
		%{$all} = (%{$all},%{$item});
	}

	my @table = ();
	my @version = ();
	while(my ($id,$sql) = each(%{$all})){
		$sql =~ s/\t//g;
		$sql =~ s/\n//g;
		$sql =~ s/`//g;
		if($sql =~ m/^CREATE\s+TABLE\sIF\sNOT\sEXISTS\s(?<table>([\w]+))/i || $sql =~ m/^CREATE\s+TABLE\s(?<table>([\w]+))/i){
			push(@table,$+{'table'});
		}
		push(@version,$id);
	}

	if(defined $action && $action eq 'delete'){
		$self->app->mysql->id($id)->do("SET FOREIGN_KEY_CHECKS = 0;");
		$self->app->mysql->id($id)->do("DROP TABLE IF EXISTS `$_`;") for (@table);
		$self->app->mysql->id($id)->do("DROP TABLE IF EXISTS `_version`;");
		$self->app->mysql->id($id)->do("SET FOREIGN_KEY_CHECKS = 1;");
		$self->app->mysql->db->commit;
	}
	elsif(defined $action && $action eq 'create'){
		$self->app->mysql->id($id)->do('CREATE TABLE IF NOT EXISTS `_version` (`version_id` int unsigned NOT NULL, `date` datetime NOT NULL, PRIMARY KEY (`version_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;');
		$self->app->mysql->id($id)->do('INSERT INTO `_version` (`version_id`,`date`) VALUES(0,UTC_TIMESTAMP());');
		$self->app->mysql->db->commit;
	}
	elsif(defined $action && $action eq 'update'){
		my $collection = $self->app->mysql->query('SELECT `version_id` FROM `_version` ORDER BY `version_id` DESC LIMIT 1;');
		my $version_id = $collection->last->{'version_id'};
		say colored ['bright_yellow'],'current sql version:'.$version_id;

		for my $file_version (sort {$a <=> $b} @version){
			if($file_version > int $version_id){
				my $sql = $all->{$file_version};
				if(defined $sql){
					$sql =~ s/\t//g;
					$sql =~ s/\n//g;
					$self->app->mysql->id($id)->do($sql);
					$self->app->mysql->id($id)->do("INSERT INTO `_version` (`version_id`,`date`) VALUES($file_version,UTC_TIMESTAMP());");
					say colored ['bright_green'],'update sql version:'.$file_version;
				}
			}
			else {
				say colored ['bright_red'],'skip sql version:'.$file_version;
			}
		}
	}
	else{
		say $self->usage;
	}
	$self->app->mysql->db->commit;
	return $self;

}


sub run1 {
	my ($self, $action, $id) = @_;

	$id = '_default' if(!defined $id);
	my $migration_object = $self->app->mysql->{'migration'}->{$id};

	my $e = load_class $migration_object;
	warn qq{Loading "$migration_object" failed: $e} if ref $e;

	my $all = data_section($migration_object);
	my @table = ();
	my @version = ();
	while(my ($id,$sql) = each(%{$all})){
		$sql =~ s/\t//g;
		$sql =~ s/\n//g;
		$sql =~ s/`//g;
		if($sql =~ m/^CREATE\s+TABLE\sIF\sNOT\sEXISTS\s(?<table>([\w]+))/i || $sql =~ m/^CREATE\s+TABLE\s(?<table>([\w]+))/i){
			push(@table,$+{'table'});
		}
		push(@version,$id);
	}

	if(defined $action && $action eq 'delete'){
		$self->app->mysql->id($id)->do("SET FOREIGN_KEY_CHECKS = 0;");
		$self->app->mysql->id($id)->do("DROP TABLE IF EXISTS `$_`;") for (@table);
		$self->app->mysql->id($id)->do("DROP TABLE IF EXISTS `_version`;");
		$self->app->mysql->id($id)->do("SET FOREIGN_KEY_CHECKS = 1;");
		$self->app->mysql->db->commit;
	}
	elsif(defined $action && $action eq 'create'){
		$self->app->mysql->id($id)->do('CREATE TABLE IF NOT EXISTS `_version` (`version_id` int unsigned NOT NULL, `date` datetime NOT NULL, PRIMARY KEY (`version_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;');
		$self->app->mysql->id($id)->do('INSERT INTO `_version` (`version_id`,`date`) VALUES(0,UTC_TIMESTAMP());');
		$self->app->mysql->db->commit;
	}
	elsif(defined $action && $action eq 'update'){
		my $collection = $self->app->mysql->query('SELECT `version_id` FROM `_version` ORDER BY `version_id` DESC LIMIT 1;');
		my $version_id = $collection->last->{'version_id'};
		say colored ['bright_yellow'],'current sql version:'.$version_id;

		for my $file_version (sort {$a <=> $b} @version){
			if($file_version > int $version_id){
				my $sql = data_section($migration_object,$file_version);
				if(defined $sql){
					$sql =~ s/\t//g;
					$sql =~ s/\n//g;
					$self->app->mysql->id($id)->do($sql);
					$self->app->mysql->id($id)->do("INSERT INTO `_version` (`version_id`,`date`) VALUES($file_version,UTC_TIMESTAMP());");
					say colored ['bright_green'],'update sql version:'.$file_version;
				}
			}
			else {
				say colored ['bright_red'],'skip sql version:'.$file_version;
			}
		}
	}
	elsif(defined $action && $action eq 'insert'){
		my $insert_object = $self->app->mysql->{'insert'}->{$id};
		my $e = load_class $insert_object;
		warn qq{Loading "$insert_object" failed: $e} if ref $e;

		my @version = ();
		while(my ($id) = each(%{$all})){
			push(@version,$id);
		}

		for my $version (sort {$a <=> $b} @version){
			my $sql = data_section($insert_object,$version);
			if(defined $sql){
				$sql =~ s/\t//g;
				$sql =~ s/\n//g;
				$self->app->mysql->id($id)->do($sql);
				say colored ['bright_blue'],'insert sql version:'.$version;
			}
		}

	}
	else{
		say $self->usage;
	}
	$self->app->mysql->db->commit;
	return $self;
}

1;

__DATA__

=encoding utf8

=head1 SYNOPSIS

    my %config = (
	    user=>'root',
	    password=>undef,
	    server=>[
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master', migration=>'migration::default'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'master', migration=>'migration::default1'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'slave'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'master', migration=>'migration::default2'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'slave'},
	    ]
    );

    Usage: APPLICATION sql [ACTION] [ID]

        ./myapp.pl sql create # first create
        ./myapp.pl sql update # update sql
        ./myapp.pl sql delete # delete all table

        ./myapp.pl sql update 1 # update sql id 1

=head1 MIGRATION PACKAGE

    package migration::default;

    1;

    __DATA__

    @@ 1
    CREATE TABLE IF NOT EXISTS `test1` (
	    `test_id` int unsigned NOT NULL AUTO_INCREMENT,
	    `text` varchar(200) NOT NULL,
	    PRIMARY KEY (`test_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

    @@ 2
    CREATE TABLE IF NOT EXISTS `test2` (
	    `test_id` int unsigned NOT NULL AUTO_INCREMENT,
	    `text` varchar(200) NOT NULL,
	    PRIMARY KEY (`test_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

=cut

