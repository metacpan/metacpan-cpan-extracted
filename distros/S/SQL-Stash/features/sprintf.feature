Feature: sprintf
	In order to allow dynamic statements
	As a developer
	I want to have sprintf-like arguments parsed

	Scenario: Simple arguments
		Given a valid database connection
		And a new SQL::Stash instance using the database connection
		And I stash the statement "SELECT * FROM Dummy%s" named select_dummy
		When I retrieve the statement select_dummy with "2" as an argument
		Then the statement should be "SELECT * FROM Dummy2"

