package Module::Checkstyle::Check;

use strict;
use warnings;

sub register {
    return ();
}

sub new {
    my ($class, $config) = @_;
    $class = ref $class || $class;
    my $self = bless { _config => $config }, $class;
    return $self;
}

sub config {
    my $self = shift;
    return $self->{_config};
}

1;
__END__

=head1 NAME

Module::Checkstyle::Check - Base class for checks

=head1 WRITING CHECK MODULES

C<Module::Checkstyle> is extensible via a plug-in mechanism. This guide takes you through the
basic steps in writing your own check.

To write a check you create a module that lives in the namespace C<Module::Checkstyle::Check::> and
that extends C<Module::Checkstyle::Check>. As an example we'll write a check that counts the length of a
named subroutine.

To begin with we create a module named B<Module::Checkstyle::Check::SubLength> either via C<h2xs> or C<Module::Starter>.

In the file I<Module/Checkstyle/Check/SubLength.pm> we enter the following code:

    package Module::Checkstyle::Check::SubLength;

    use strict;
    use warnings;
    use Readonly;

    use Module::Checkstyle::Util qw(:args :problem);
    use base qw(Module::Checkstyle::Check);

Next we need to tell Module::Checkstyle what we want to recive events for. We do this by overriding the subroutine C<register> which is called if the check is enabled in the configuration file.

    sub register {
        return ('enter PPI::Statement::Sub' => \&enter_subroutine);
    }

The method C<register> must return a hash with I<event =E<gt> handler> pairs (actually it's a list that is returned). The
event is defined by an optional operation, B<enter> or B<leave>, followed by the type of PPI::Element we want to respond to, which in this case is B<PPI::Statement::Sub>.

The plug-in is then instansiated by calling its C<new> method. This method should read the configuration directives into the object itself because there can exist mulitple instances of the check with different configurations. The C<new> method is supplied an instance of C<Module::Checkstyle::Config>. Lets define the configuration-directive I<max-length> as a readonly-variable and add a constructor that reads it into the instance.

    Readonly my $MAX_LENGTH => 'max-length';

    sub new {
        my ($class, $config) = @_;
        $class = ref $class || $class;

        my $self = bless { config => $config }, $class;

        $self->{$MAX_LENGTH} = as_numeric($config->get_directive($MAX_LENGTH));
        
        return $self;
    }

The function C<as_numeric> is provided by C<Module::Checkstyle::Util> via the tag B<args>.

Next we need to write our event handling code that is called when a named subroutine is found. Event-handlers retrieves three arguments: the instance of the plug-in, the C<PPI::Element> and the path of the current file that is being processed.

    my enter_subroutine {
        my ($self, $subroutine, $file) = @_;

        my @problems;

        if ($self->{$MAX_LENGTH}) { # No need to run code if it's turned off
            my $block = $subroutine->block();
            if ($block) { # It's not a forward declaration
                my $line = $subroutine->location->[0]; # The line the declartion is on
                my $last_line = $block->last_element->location->[0]; # The line where } is at
                my $length = $last_line - $line;
                if ($length > $self->{$MAX_LENGTH}) {
                    my $name = $subroutine->name();
                    push @problems, make_problem($self->{config}->get_severity($MAX_LENGTH),
                                                 "Subroutine '$name' is too long ($length)",
                                                 $subroutine->location,
                                                 $file);
                }
            }
        }

        return @problems;
    }

The function make_problem is exported by C<Module::Checkstyle::Util> in the tag B<problem>.

To finish up our module we write the documentation, see L<Module::Checkstyle::Check::Package> for an example, write the tests and make sure the module returns a true value.

=head1 METHODS

=over 4

=item new ($config)

Default constructor that returns a hash-reference blessed to the subclass. The returned object will have the passed configuration object available under the key I<_config>.

=item register

Abstract method that subclasses should override that provides the events it responds to.

=item config

Returns the config passed to C<new>.

=back

=cut
