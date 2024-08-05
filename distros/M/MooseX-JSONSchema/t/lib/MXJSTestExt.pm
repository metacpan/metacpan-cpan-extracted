package MXJSTestExt;

use Moose;
use MooseX::JSONSchema;

extends 'MXJSTest';

json_schema_title "Extended person";

string job => "The job of the person";

1;
