#ABSTRACT: Exception class for MooX::Ipc::Cmd role
package MooX::Ipc::Cmd::Exception;
use Moo;
our $VERSION = '1.2.1'; #VERSION
extends 'Throwable::Error';
has 'stderr'      => (is => 'ro', predicate => 1,);
has 'cmd'         => (is => 'ro', required  => 1,);
has 'exit_status' => (is => 'ro', required  => 1);
has 'signal'      => (is => 'ro', predicate => 1,);
use namespace::autoclean;
use overload
  q{""}    => 'as_string',
  fallback => 1;

 has +stack_trace_args => (
     is=>'ro',
     default=>sub{return [ skip_frames=>5,ignore_package=>['MooX::Ipc::Cmd','MooX::Ipc::Cmd::Exception'] ]},
 );
  #message to print when dieing
has +message => (
    is =>'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $str = join(" ", @{$self->cmd});
        if ($self->has_signal)
        {
            $str .= " failed with signal " . $self->signal;
        }
        else
        {
            $str .= " failed with exit status " . $self->exit_status;
            if ($self->has_stderr && defined $self->stderr)
            {
                $str .= "\nSTDERR is :\n  " . join("\n  ", @{$self->stderr});
            }
        }
        return $str;
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::Ipc::Cmd::Exception - Exception class for MooX::Ipc::Cmd role

=head1 VERSION

version 1.2.1

=head1 ATTRIBUTES

=head2 cmd

Reader: cmd

This attribute is required.

This documentation was automatically generated.

=head2 exit_status

Reader: exit_status

This attribute is required.

This documentation was automatically generated.

=head2 message

Reader: message

This documentation was automatically generated.

=head2 previous_exception

Reader: previous_exception

This documentation was automatically generated.

=head2 signal

Reader: signal

This documentation was automatically generated.

=head2 stack_trace

Reader: stack_trace

Type: __ANON__

This documentation was automatically generated.

=head2 stack_trace_args

Reader: stack_trace_args

This documentation was automatically generated.

=head2 stack_trace_class

Reader: stack_trace_class

Type: __ANON__

This documentation was automatically generated.

=head2 stderr

Reader: stderr

This documentation was automatically generated.

=head1 METHODS

=head2 (""

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 ((

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 ()

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 BUILD

Method originates in Throwable::Error.

This documentation was automatically generated.

=head2 _build_stack_trace_args

Method originates in Throwable::Error.

This documentation was automatically generated.

=head2 _build_stack_trace_class

Method originates in Throwable::Error.

This documentation was automatically generated.

=head2 as_string

Method originates in Throwable::Error.

This documentation was automatically generated.

=head2 cmd

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 exit_status

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 has_signal

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 has_stderr

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 message

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 previous_exception

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 signal

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 stack_trace

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 stack_trace_args

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 stack_trace_class

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 stderr

Method originates in MooX::Ipc::Cmd::Exception.

This documentation was automatically generated.

=head2 throw

Method originates in Throwable::Error.

This documentation was automatically generated.

=head1 AUTHOR

Eddie Ash <eddie+cpan@ashfamily.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Edward Ash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
