package MooseX::Runnable::Invocation::Role::WithParsedArgs;

our $VERSION = '0.10';

use Moose::Role;
use MooseX::Runnable::Util::ArgParser;
use namespace::autoclean;

has 'parsed_args' => (
    is       => 'ro',
    isa      => 'MooseX::Runnable::Util::ArgParser',
    required => 1,
);

1;
