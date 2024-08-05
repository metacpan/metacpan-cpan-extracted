package MXJSTest;

use Moose;
use MooseX::JSONSchema;

json_schema_title "A person";

string first_name => "The first name of the person";
string last_name => "The last name of the person";
integer age => "Current age in years", json_schema_args => { minimum => 0, maximum => 200 };

1;
