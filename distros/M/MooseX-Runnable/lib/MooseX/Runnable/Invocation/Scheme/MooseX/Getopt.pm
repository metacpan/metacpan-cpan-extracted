package MooseX::Runnable::Invocation::Scheme::MooseX::Getopt;

our $VERSION = '0.10';

use Moose::Role;
use namespace::autoclean;

around validate_class => sub {
    return; # always valid
};

around create_instance => sub {
    my ($next, $self, $class, @args) = @_;

    local @ARGV = @args; # ugly!
    my $instance = $class->name->new_with_options();

    my $more_args = $instance->extra_argv;

    return ($instance, @$more_args);
};

# XXX: arounds that don't actually call $orig fuck up plugins.  i
# think that's OK, mostly, but it's something to keep in mind...

1;

__END__

=head1 NAME

MooseX::Runnable::Invocation::Scheme::MooseX::Getopt - run MX::Getopt classes

=head1 DESCRIPTION

This role will be used by C<MooseX::Runnable::Invocation> to create an
instance of the class to be run with C<MooseX::Getopt>.  Any args not
consumed by MX::Getopt will be passed to the class's run method.

(See the test C<t/basic-mx-getopt.t> for an example.)

=head1 SEE ALSO

L<MooseX::Runnable>

L<MooseX::Getopt>
