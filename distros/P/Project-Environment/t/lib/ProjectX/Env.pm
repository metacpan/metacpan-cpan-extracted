package ProjectX::Env;

use Moose;
extends 'Project::Environment';

has '+environment_filename' => (default => 'environment');

1;
