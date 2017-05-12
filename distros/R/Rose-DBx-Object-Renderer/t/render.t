#!perl -T

# use strict;
use warnings;
use Test::More;

eval 'use DBI';
plan skip_all => 'Could not load DBI' if $@;

eval 'use DBD::Pg';
plan skip_all => 'Could not load DBD::Pg' if $@;

eval 'use DateTime';
plan skip_all => 'Could not load DateTime' if $@;

eval 'use DateTime::TimeZone::Australia::Sydney';
plan skip_all => 'Could not load DateTime::TimeZone::Australia::Sydney' if $@;

my $dbh;
eval {$dbh = DBI->connect('dbi:Pg:dbname=test;host=localhost;port=5432;', 'postgres', undef, {AutoCommit => 0, RaiseError => 0, PrintError => 0, PrintWarn => 0});};
plan skip_all => 'Unable to connect "test" database at localhost(port 5432) via user "postgres"' if $@ || !$dbh;

my $schema = 'CREATE TABLE test_position (id SERIAL PRIMARY KEY,title VARCHAR(255),description TEXT);CREATE TABLE test_employee (id SERIAL PRIMARY KEY,first_name VARCHAR(255),last_name VARCHAR(255),email VARCHAR(255) UNIQUE,password VARCHAR(255),gender VARCHAR(255),date_of_birth DATE,photo VARCHAR(255),address VARCHAR(255),postcode VARCHAR(255),created_on TIMESTAMP,test_position_id INTEGER,FOREIGN KEY (test_position_id) REFERENCES test_position (id) ON UPDATE CASCADE ON DELETE CASCADE);CREATE TABLE test_project (id SERIAL PRIMARY KEY,name VARCHAR(255),document VARCHAR(255),url VARCHAR(255),percentage_completed NUMERIC,cost DECIMAL(13,2));CREATE TABLE test_employee_test_project_map (id SERIAL PRIMARY KEY,test_employee_id INTEGER,test_project_id INTEGER,FOREIGN KEY (test_project_id) REFERENCES test_project (id) ON UPDATE CASCADE ON DELETE CASCADE,FOREIGN KEY (test_employee_id) REFERENCES test_employee (id) ON UPDATE CASCADE ON DELETE CASCADE);';

eval {	
	foreach my $sql (split /;/, $schema) {
		$dbh->do($sql);
	}
	$dbh->commit;
};

if ($@) {
	eval {
	  $dbh->rollback;
	  $dbh->disconnect;
	};
	plan skip_all => 'Unable to create tables for testing';
}

plan tests => 17;

use_ok('Rose::DBx::Object::Renderer');

my $renderer = Rose::DBx::Object::Renderer->new(config => {db => {name => 'test', username => 'postgres', password => undef, type => 'Pg', table_prefix => 'test_', tables_are_singular => 1}}, load => {loader => {class_prefix => 'Company'}});

can_ok('Company::TestEmployee', ('new', 'stringify_class', 'render_as_form'));

my $manager_position = Company::TestPosition->new(title => 'Manager', description => 'General Manager')->save();
my $director_position = Company::TestPosition->new(title => 'Director', description => 'Company Director')->save();

my $new_employee = Company::TestEmployee->new(first_name => 'John', last_name => 'Smith', gender => 'Male', email => 'john@home.com', test_position_id => $manager_position->id)->save();
my $another_employee = Company::TestEmployee->new(first_name => 'Lisa', last_name => 'Smith', gender => 'Female', email => 'lisa@work.com', test_position_id => $director_position->id)->save();


can_ok($new_employee, ('stringify_me', 'render_as_form'));
can_ok('Company::TestEmployee::Manager', ('render_as_table', 'render_as_menu', 'render_as_chart'));

my $form_output = Company::TestEmployee->render_as_form(
	before => sub {
		my ($object, $args) = @_;
		$args->{title} = 'Add Employee';
	},
	output => 1,
	load_js => 1,
	template => 0,
	description => 'Some instructions',
	order => ['first_name', 'last_name', 'email', 'date_of_birth', 'gender', 'photo', 'address', 'postcode', 'created_on', 'test_position_id'],
	fields => {
		test_position_id => {type => 'select'},
	},
	controller_order => ['Create and Send Notification', 'Create', 'Cancel'],
	controllers => {
		'Create and Send Notification' => {
			create => 1,
			callback => sub {},
		}
	}
)->{output};

my $table_output = Company::TestPosition::Manager->render_as_table(
	before => sub {
		my ($class, $args) = @_;
		$args->{title} = 'Current Positions';
	},
	output => 1,
	template => 0,
	description => 'A list of current positions',
	order => ['title', 'description'],
	columns => {
		description => {label => 'Comments'},
	},
	create => 1,
	edit => 1,
	copy => 1,
	delete => 1,
	controller_order => ['notify', 'edit', 'copy', 'delete'],
	controllers => {
		'notify' => {
			label => 'Notify',
			callback => sub {},
		}
	}
)->{output};

my $menu_output = Company::TestEmployee::Manager->render_as_menu(
	output => 1,
	order => ['Company::TestEmployee', 'Company::TestPosition', 'Company::TestProject'],
	template => 0,
	create => 1,
	edit => 1,
	delete => 1
)->{output};

my $chart_output = Company::TestEmployee::Manager->render_as_chart(
	output => 1,
	template => 0,
	type => 'pie',
	column => 'gender',
	values => ['Male', 'Female'],
)->{output};


# clean up

eval {
  foreach my $sql (split /;/, 'DROP TABLE test_employee_test_project_map;DROP TABLE test_project;DROP TABLE test_employee;DROP TABLE test_position;') {
    $dbh->do($sql);
  }
  $dbh->commit;
};

if ($@) {
  eval {
    $dbh->rollback;
    $dbh->disconnect;
  };
  diag('Failed to clean up database tables after testing...disconnecting');
}

like ($form_output, qr/DOCTYPE HTML/, 'Form HTML head');

like ($form_output, qr/jquery/, 'Load JS');

like ($form_output, qr/validate_company_testemployee_form/, 'Form JS validation function');

my $date_of_birth_js_regex = 'date_of_birth.match(/^(0?[1-9]|[1-2][0-9]|3[0-1])\/(0?[1-9]|1[0-2])\/[0-9]{4}|([0-9]{4}\-0?[1-9]|1[0-2])\-(0?[1-9]|[1-2][0-9]|3[0-1])$/)';
like ($form_output, qr/\Q$date_of_birth_js_regex\E/, 'Form JS regular expression for validating "Date Of Birth"');

like ($form_output, qr/<h1>Add Employee<\/h1>/, 'Custom form title');

like ($form_output, qr/Some instructions/, 'Custom form description');

like ($form_output, qr/<option value="1">Manager<\/option>/, 'Custom select box for "Position"');

# test 11
unlike ($form_output, qr/test_projects/, 'Exclude "Projects" form field');

like ($form_output, qr/value="Create and Send Notification"/, 'Custom form controller');

like ($form_output, qr/<\/html>$/, 'Complete form');

# table
my $expected_partial_table_output = '<h1>Current Positions</h1><p>A list of current positions</p><div class="block"><div><a href="?action=create" class="button">Create</a></div></div><table id="company_testposition_table"><tr><th><a href="?sort_by=title">Title</a></th><th><a href="?sort_by=description">Comments</a></th><th></th><th></th><th></th><th></th></tr><tr><td>Manager</td><td>General Manager</td><td><a href="?action=notify&amp;object=1" class="button">Notify</a></td><td><a href="?action=edit&amp;object=1" class="button">Edit</a></td><td><a href="?action=copy&amp;object=1" class="button">Copy</a></td><td><a href="?action=delete&amp;object=1" class="button delete">Delete</a></td></tr><tr><td>Director</td><td>Company Director</td><td><a href="?action=notify&amp;object=2" class="button">Notify</a></td><td><a href="?action=edit&amp;object=2" class="button">Edit</a></td><td><a href="?action=copy&amp;object=2" class="button">Copy</a></td><td><a href="?action=delete&amp;object=2" class="button delete">Delete</a></td></tr></table><div><span class="pager">&laquo;</span><span class="pager">&lsaquo;</span><span class="pager">1</span><span class="pager">&rsaquo;</span><span class="pager">&raquo;</span></div></div></body></html>';
like ($table_output, qr/\Q$expected_partial_table_output\E/, 'Table output');


# menu
my $expected_partial_menu_output = '<body><div><div class="menu"><ul><li><a class="current" href="?current=test_employee">Employees</a></li><li><a href="?current=test_position">Positions</a></li><li><a href="?current=test_project">Projects</a></li></ul></div></div><div><h1>Employees</h1><div class="block"><div><a href="?current=test_employee&amp;company_testemployee_menu_table_action=create" class="button">Create</a></div></div><table id="company_testemployee_menu_table"><tr><th><a href="?current=test_employee&amp;company_testemployee_menu_table_sort_by=first_name">First Name</a></th><th><a href="?current=test_employee&amp;company_testemployee_menu_table_sort_by=last_name">Last Name</a></th><th><a href="?current=test_employee&amp;company_testemployee_menu_table_sort_by=email">Email</a></th><th>Password</th><th><a href="?current=test_employee&amp;company_testemployee_menu_table_sort_by=gender">Gender</a></th><th><a href="?current=test_employee&amp;company_testemployee_menu_table_sort_by=date_of_birth">Date Of Birth</a></th><th><a href="?current=test_employee&amp;company_testemployee_menu_table_sort_by=photo">Photo</a></th><th><a href="?current=test_employee&amp;company_testemployee_menu_table_sort_by=address">Address</a></th><th><a href="?current=test_employee&amp;company_testemployee_menu_table_sort_by=postcode">Postcode</a></th><th><a href="?current=test_employee&amp;company_testemployee_menu_table_sort_by=created_on">Created On</a></th><th><a href="?current=test_employee&amp;company_testemployee_menu_table_sort_by=test_position_id">Position</a></th><th>Projects</th><th></th><th></th></tr><tr><td>John</td><td>Smith</td><td><a href="mailto:john@home.com">john@home.com</a></td><td>****</td><td>Male</td><td></td><td></td><td></td><td></td><td></td><td>Manager</td><td></td><td><a href="?current=test_employee&amp;company_testemployee_menu_table_action=edit&amp;company_testemployee_menu_table_object=1" class="button">Edit</a></td><td><a href="?current=test_employee&amp;company_testemployee_menu_table_action=delete&amp;company_testemployee_menu_table_object=1" class="button delete">Delete</a></td></tr><tr><td>Lisa</td><td>Smith</td><td><a href="mailto:lisa@work.com">lisa@work.com</a></td><td>****</td><td>Female</td><td></td><td></td><td></td><td></td><td></td><td>Director</td><td></td><td><a href="?current=test_employee&amp;company_testemployee_menu_table_action=edit&amp;company_testemployee_menu_table_object=2" class="button">Edit</a></td><td><a href="?current=test_employee&amp;company_testemployee_menu_table_action=delete&amp;company_testemployee_menu_table_object=2" class="button delete">Delete</a></td></tr></table><div><span class="pager">&laquo;</span><span class="pager">&lsaquo;</span><span class="pager">1</span><span class="pager">&rsaquo;</span><span class="pager">&raquo;</span></div></div></body></html>';
like ($menu_output, qr/\Q$expected_partial_menu_output\E/, 'Menu output');

# chart
my $expected_partial_chart_output = '<body><div><h1>Employees</h1><img src="http://chart.apis.google.com/chart?cht=p&amp;chl=Female%7CMale&amp;chco=ff6600&amp;chs=600x300&amp;chd=t%3A1%2C1&amp;" alt="Employees"/></div></body></html>';
like ($chart_output, qr/\Q$expected_partial_chart_output\E/, 'Chart output');