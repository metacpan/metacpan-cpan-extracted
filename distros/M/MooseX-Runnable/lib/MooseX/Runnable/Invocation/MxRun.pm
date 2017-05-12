package MooseX::Runnable::Invocation::MxRun;

our $VERSION = '0.10';

use Moose;
use namespace::autoclean;

extends 'MooseX::Runnable::Invocation';
with 'MooseX::Runnable::Invocation::Role::WithParsedArgs';

1;
