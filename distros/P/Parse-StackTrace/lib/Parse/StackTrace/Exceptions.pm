package Parse::StackTrace::Exceptions;
use strict;
use Exception::Class (
    'Parse::StackTrace::Exception',
    
    'Parse::StackTrace::Exception::NotAFrame' =>
    { isa => 'Parse::StackTrace::Exception' },

);

1;

__END__

=head1 NAME

Parse::StackTrace::Exceptions - Exceptions that can be thrown by
Parse::StackTrace modules

=head1 DESCRIPTION

There are no public methods that can throw an exception, so you generally
don't need to worry about this.