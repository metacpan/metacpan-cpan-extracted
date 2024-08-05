# SYNOPSIS

    package PersonClass;

    use Moose;
    use MooseX::JSONSchema;

    json_schema_title "A person";

    string first_name => "The first name of the person";
    string last_name => "The last name of the person";
    integer age => "Current age in years", json_schema_args => { minimum => 0, maximum => 200 };

    1;

    package CharacterClass;

    use Moose;
    use MooseX::JSONSchema;

    extends 'PersonClass';

    json_schema_title "Extended person";

    string job => "The job of the person";

    1;

    my $json_schema_json = PersonClass->meta->json_schema_json;

    my $person = PersonClass->new(
      first_name => "Peter",
      last_name => "Parker",
      age => 21,
    );

    my $json_schema_data_json = $person->json_schema_data_json;

# DESCRIPTION

**THIS API IS WORK IN PROGRESS**

# SUPPORT

Repository

     https://github.com/Getty/perl-moosex-jsonschema
     Pull request and additional contributors are welcome
    

Issue Tracker

    https://github.com/Getty/perl-moosex-jsonschema/issues
