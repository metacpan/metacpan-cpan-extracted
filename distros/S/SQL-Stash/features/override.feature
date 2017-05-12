Feature: Override class-level statements in instance
	In order to locally defined SQL statements
	As a developer
	I want be able to override queries in the instance

	Scenario: Override class-level statement in instance
		Given a valid database connection
		And a new SQL::Stash instance using the database connection
		And I stash the statement "SELECT * FROM Dummy" named unique_query9131 in the class
		And I stash the statement "SELECT col1 FROM Dummy" named unique_query9131 in the instance
		When I retrieve the statement unique_query9131
		Then I should have a statement handle
		And the statement should be "SELECT col1 FROM Dummy"

