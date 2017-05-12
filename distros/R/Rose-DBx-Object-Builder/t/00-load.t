#!perl -T

use Test::More tests => 6;

BEGIN {
	use_ok( 'Rose::DBx::Object::Builder' );
}

# MySQL

my $builder = Rose::DBx::Object::Builder->new(config => {db => {tables_are_singular => 1}});

my $text = 'Employees have first name, last name, email (unique), password, age(integer), salary (money), and position (has a title and description).
			Tasks have title, rating (number) and start time.
 			Projects have name, start date, created on (timestamp), main task (reference task).
			A project has many tasks.
			Employee has task as current task.
			Employees have many projects and vice versa.';

my $expected_mysql = 'CREATE TABLE position (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,title VARCHAR(255),description TEXT) TYPE=INNODB;CREATE TABLE employee (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,first_name VARCHAR(255),last_name VARCHAR(255),email VARCHAR(255) UNIQUE,password VARCHAR(255),age INTEGER,salary DECIMAL(13,2),position_id INTEGER,FOREIGN KEY (position_id) REFERENCES position (id) ON UPDATE CASCADE ON DELETE CASCADE) TYPE=INNODB;CREATE TABLE task (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,title VARCHAR(255),rating NUMERIC,start_time TIME) TYPE=INNODB;CREATE TABLE project (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,name VARCHAR(255),start_date DATE,created_on TIMESTAMP,main_task INTEGER,FOREIGN KEY (main_task) REFERENCES task (id) ON UPDATE CASCADE ON DELETE CASCADE) TYPE=INNODB;ALTER TABLE task ADD project_id INTEGER;ALTER TABLE task ADD FOREIGN KEY (project_id) REFERENCES project (id) ON UPDATE CASCADE ON DELETE CASCADE;ALTER TABLE employee ADD current_task_id INTEGER;ALTER TABLE employee ADD FOREIGN KEY (current_task_id) REFERENCES task (id) ON UPDATE CASCADE ON DELETE CASCADE;CREATE TABLE employee_project_map (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,employee_id INTEGER,project_id INTEGER,FOREIGN KEY (employee_id) REFERENCES employee (id) ON UPDATE CASCADE ON DELETE CASCADE,FOREIGN KEY (project_id) REFERENCES project (id) ON UPDATE CASCADE ON DELETE CASCADE) TYPE=INNODB;';

my $expected_mysql_with_prefix = 'CREATE TABLE test_position (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,title VARCHAR(255),description TEXT) TYPE=INNODB;CREATE TABLE test_employee (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,first_name VARCHAR(255),last_name VARCHAR(255),email VARCHAR(255) UNIQUE,password VARCHAR(255),age INTEGER,salary DECIMAL(13,2),test_position_id INTEGER,FOREIGN KEY (test_position_id) REFERENCES test_position (id) ON UPDATE CASCADE ON DELETE CASCADE) TYPE=INNODB;CREATE TABLE test_task (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,title VARCHAR(255),rating NUMERIC,start_time TIME) TYPE=INNODB;CREATE TABLE test_project (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,name VARCHAR(255),start_date DATE,created_on TIMESTAMP,main_task INTEGER,FOREIGN KEY (main_task) REFERENCES test_task (id) ON UPDATE CASCADE ON DELETE CASCADE) TYPE=INNODB;ALTER TABLE test_task ADD test_project_id INTEGER;ALTER TABLE test_task ADD FOREIGN KEY (test_project_id) REFERENCES test_project (id) ON UPDATE CASCADE ON DELETE CASCADE;ALTER TABLE test_employee ADD current_task_id INTEGER;ALTER TABLE test_employee ADD FOREIGN KEY (current_task_id) REFERENCES test_task (id) ON UPDATE CASCADE ON DELETE CASCADE;CREATE TABLE test_employee_test_project_map (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,test_employee_id INTEGER,test_project_id INTEGER,FOREIGN KEY (test_project_id) REFERENCES test_project (id) ON UPDATE CASCADE ON DELETE CASCADE,FOREIGN KEY (test_employee_id) REFERENCES test_employee (id) ON UPDATE CASCADE ON DELETE CASCADE) TYPE=INNODB;';

my $expected_mysql_pretty = 'CREATE TABLE position (
	id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
	title VARCHAR(255),
	description TEXT
) TYPE=INNODB;

CREATE TABLE employee (
	id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
	first_name VARCHAR(255),
	last_name VARCHAR(255),
	email VARCHAR(255) UNIQUE,
	password VARCHAR(255),
	age INTEGER,
	salary DECIMAL(13,2),
	position_id INTEGER,
	FOREIGN KEY (position_id) REFERENCES position (id) ON UPDATE CASCADE ON DELETE CASCADE
) TYPE=INNODB;

CREATE TABLE task (
	id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
	title VARCHAR(255),
	rating NUMERIC,
	start_time TIME
) TYPE=INNODB;

CREATE TABLE project (
	id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255),
	start_date DATE,
	created_on TIMESTAMP,
	main_task INTEGER,
	FOREIGN KEY (main_task) REFERENCES task (id) ON UPDATE CASCADE ON DELETE CASCADE
) TYPE=INNODB;

ALTER TABLE task ADD project_id INTEGER;

ALTER TABLE task ADD FOREIGN KEY (project_id) REFERENCES project (id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE employee ADD current_task_id INTEGER;

ALTER TABLE employee ADD FOREIGN KEY (current_task_id) REFERENCES task (id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TABLE employee_project_map (
	id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
	employee_id INTEGER,
	project_id INTEGER,
	FOREIGN KEY (employee_id) REFERENCES employee (id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (project_id) REFERENCES project (id) ON UPDATE CASCADE ON DELETE CASCADE
) TYPE=INNODB;';

# test 2
my $mysql = $builder->parse($text);
ok($mysql eq $expected_mysql, 'Generate MySQL tables');

# test 3
$builder->{SCHEMA} = ''; # clear the schema;
my $config = $builder->config();
$config->{db}->{table_prefix} = 'test_';
my $mysql_with_prefix = $builder->parse($text);
ok($mysql_with_prefix eq $expected_mysql_with_prefix, 'Generate MySQL tables with prefix');

# test 4
$builder->{SCHEMA} = '';
delete $config->{db}->{table_prefix};
my $mysql_pretty = $builder->show($text);
ok($mysql_pretty eq $expected_mysql_pretty, 'Generate pretty MySQL tables');

# Postgres

my $expected_postgres = 'CREATE TABLE position (id SERIAL PRIMARY KEY,title VARCHAR(255),description TEXT);CREATE TABLE employee (id SERIAL PRIMARY KEY,first_name VARCHAR(255),last_name VARCHAR(255),email VARCHAR(255) UNIQUE,password VARCHAR(255),age INTEGER,salary DECIMAL(13,2),position_id INTEGER,FOREIGN KEY (position_id) REFERENCES position (id) ON UPDATE CASCADE ON DELETE CASCADE);CREATE TABLE task (id SERIAL PRIMARY KEY,title VARCHAR(255),rating NUMERIC,start_time TIME);CREATE TABLE project (id SERIAL PRIMARY KEY,name VARCHAR(255),start_date DATE,created_on TIMESTAMP,main_task INTEGER,FOREIGN KEY (main_task) REFERENCES task (id) ON UPDATE CASCADE ON DELETE CASCADE);ALTER TABLE task ADD project_id INTEGER;ALTER TABLE task ADD FOREIGN KEY (project_id) REFERENCES project (id) ON UPDATE CASCADE ON DELETE CASCADE;ALTER TABLE employee ADD current_task_id INTEGER;ALTER TABLE employee ADD FOREIGN KEY (current_task_id) REFERENCES task (id) ON UPDATE CASCADE ON DELETE CASCADE;CREATE TABLE employee_project_map (id SERIAL PRIMARY KEY,employee_id INTEGER,project_id INTEGER,FOREIGN KEY (employee_id) REFERENCES employee (id) ON UPDATE CASCADE ON DELETE CASCADE,FOREIGN KEY (project_id) REFERENCES project (id) ON UPDATE CASCADE ON DELETE CASCADE);';

# test 5
$builder->{SCHEMA} = '';
$config->{db}->{type} = 'Pg';
my $postgres = $builder->parse($text);

ok($postgres eq $expected_postgres, 'Generate Postgres tables');


# SQLite

my $expected_sqlite = 'CREATE TABLE position (id INTEGER NOT NULL PRIMARY KEY,title VARCHAR(255),description TEXT);CREATE TABLE employee (id INTEGER NOT NULL PRIMARY KEY,first_name VARCHAR(255),last_name VARCHAR(255),email VARCHAR(255) UNIQUE,password VARCHAR(255),age INTEGER,salary DECIMAL(13,2),position_id INTEGER,FOREIGN KEY (position_id) REFERENCES position (id) ON UPDATE CASCADE ON DELETE CASCADE);CREATE TABLE task (id INTEGER NOT NULL PRIMARY KEY,title VARCHAR(255),rating NUMERIC,start_time TIME);CREATE TABLE project (id INTEGER NOT NULL PRIMARY KEY,name VARCHAR(255),start_date DATE,created_on TIMESTAMP,main_task INTEGER,FOREIGN KEY (main_task) REFERENCES task (id) ON UPDATE CASCADE ON DELETE CASCADE);ALTER TABLE task ADD project_id INTEGER;ALTER TABLE task ADD FOREIGN KEY (project_id) REFERENCES project (id) ON UPDATE CASCADE ON DELETE CASCADE;ALTER TABLE employee ADD current_task_id INTEGER;ALTER TABLE employee ADD FOREIGN KEY (current_task_id) REFERENCES task (id) ON UPDATE CASCADE ON DELETE CASCADE;CREATE TABLE employee_project_map (id INTEGER NOT NULL PRIMARY KEY,employee_id INTEGER,project_id INTEGER,FOREIGN KEY (employee_id) REFERENCES employee (id) ON UPDATE CASCADE ON DELETE CASCADE,FOREIGN KEY (project_id) REFERENCES project (id) ON UPDATE CASCADE ON DELETE CASCADE);';

# test 6
$builder->{SCHEMA} = '';
$config->{db}->{type} = 'SQLite';
my $sqlite = $builder->parse($text);

ok($sqlite eq $expected_sqlite, 'Generate SQLite tables');