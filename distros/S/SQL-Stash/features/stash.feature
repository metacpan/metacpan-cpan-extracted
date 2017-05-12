Feature: Stash SQL statements
	In order to easily maintain SQL statements
	As a developer
	I want to have a central class for storing SQL statements

	Scenario: Store a statement in the stash
		Given a valid database connection
		And a new SQL::Stash instance using the database connection
		And I stash the statement "SELECT * FROM Dummy" named select_dummy
		When I retrieve the statement select_dummy
		Then I should have a statement handle
		And the statement should be "SELECT * FROM Dummy"

	Scenario: Retrieve a non-existant statement
		Given a valid database connection
		And a new SQL::Stash instance using the database connection
		When I retrieve the statement select_dummy
		Then the statement handle should be undefined

