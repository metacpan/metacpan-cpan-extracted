package Module::Mask;

use strict;
use warnings;

our $VERSION = '0.06';

=head1 NAME

Module::Mask - Pretend certain modules are not installed

=head1 SYNOPSIS

    use Module::Mask;

    {
        my $mask = new Module::Mask ('My::Module');
        eval { require My::Module };
        if ($@) {
            # ... should be called
        }
        else {
            warn "require succeeded unexpectedly"
        }
    }
    
    # The mask is out of scope, this should now work.
    eval { require My::Module };

    # There's also an inverted version:
    {
        my $mask = new Module::Mask::Inverted qw( Foo Bar );

        # Now only Foo and Bar can be loaded by require:
        eval {require Baz};
    }

=head1 DESCRIPTION

Sometimes you need to test what happens when a given module is not installed.
This module provides a way of temporarily hiding installed modules from perl's
require mechanism. The Module::Mask object adds itself to @INC and blocks
require calls to restricted modules.

Module::Mask will not affect modules already loaded at time of instantiation.

=cut

use Module::Util qw( module_path );
use Scalar::Util qw( weaken );
use Carp qw( shortmess );

# Don't want this to be loaded inside INC by calling shortmess
require Carp::Heavy;

=head1 METHODS

=head2 import

    use Module::Mask @modules;

    $class->import(@modules);

Globally masks modules. This can be used to block optional modules for testing
purposes.

    perl -MModule::Mask=MyOptionalModule my_test.pl

=cut

sub import {
    my $class = shift;
    our $Mask = $class->new(@_);
}

=head2 new

    $obj = $class->new(@modules);

Returns a new instance of this class. Any arguments are passed to mask_modules.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->mask_modules(@_);
    $self->set_mask;

    return $self;
}

sub DESTROY {
    my $self = shift;

    $self->clear_mask();
}

=head2 mask_modules

    $obj = $obj->mask_modules(@modules)

Add the given modules to the mask. Arguments can be paths or module names,
module names will be stored internally as relative paths. So there's no
difference between the following statements:

    $mask->mask_modules('My::Module');
    $mask->mask_modules('My/Module.pm');

=cut

sub mask_modules {
    my ($self, @modules) = @_;

    for my $module (@modules) {
        next unless defined $module;
        $self->_mask_module($module);
    }

    return $self;
}

sub _path {
    my ($self, $module) = @_;

    return module_path $module || $module;
}

# internal method to allow overriding
sub _mask_module {
    my ($self, $module) = @_;
    my $path = $self->_path($module) or return;

    $self->{$path} = 1;
}

=head2 clear_mask

    $obj = $obj->clear_mask()

Stops the object from masking modules by removing it from @INC. This is
automatically called when object goes out of scope.

=cut

sub clear_mask {
    my $self = shift;

    @INC = grep { !ref $_ or $_ != $self } @INC;

    return $self;
}

=head2 set_mask

    $obj = $obj->set_mask()

Makes the object start masking modules by adding it to @INC. This is called by
new().

This also has the effect of moving the object to the front of @INC again, which
could prove useful if @INC has been manipulated since the object was first
instantiated.

Calling this method on an object already in @INC won't cause multiple copies to
appear.

=cut

sub set_mask {
    my $self = shift;

    # We might already be in @INC
    $self->clear_mask;

    unshift @INC, $self;
    weaken $INC[0]; # don't let @INC keep us alive.

    return $self;
}

=head2 is_masked

    $bool = $obj->is_masked($module)

Returns true if the mask object is currently masking the given module, false
otherwise.

Module::Mask::Inverted objects have the opposite behaviour.

=cut

sub is_masked {
    my ($self, $module) = @_;

    return $self->_is_listed($module);
}

# internal method to determine whether a module is listed in the mask or not.
sub _is_listed {
    my ($self, $module) = @_;
    my $path = $self->_path($module) or return 0;

    return $self->{$path} ? 1 : 0;
}

@Module::Mask::Inverted::ISA = qw( Module::Mask );

sub Module::Mask::Inverted::is_masked {
    my $self = shift;

    return ! $self->_is_listed(@_);
}

=head2 list_masked

    @modules = $obj->list_masked()

Returns a list of modules that are being masked. These are in the form of relative file paths, as found in %INC.

=cut

sub list_masked { keys %{$_[0]} }

=head2 INC

Implements the hook in @INC. See perldoc -f require

=cut

# INC gets forced into main unless explicitly qualified
sub Module::Mask::INC {
    my ($self, $filename) = @_;

    if ($self->is_masked($filename)) {
        die $self->message($filename);
    }
    else {
        return;
    }
}

=head2 message

    $message = $obj->message($filename)

Returns the error message to be used when the filename is not found. This is
normally "$filename masked by $class", but can be overridden in subclasses if
necessary. Carp's L<shortmess|Carp/shortmess> is used to make this message
appear to come from the caller, i.e. the C<require> or C<use> statement
attempting to load the file.

One possible application of this would be to make the error message look more
like perl's native "Could not find $filename in \@INC ...".

=cut

sub message {
    my ($self, $filename) = @_;
    my $class = ref $self;

    return shortmess("$filename masked by $class");
}

1;

__END__

=head1 BUGS

Because loaded modules cannot be masked, the following module are effectively
never able to be masked as they are used my Module::Mask.

=over

=item * Module::Util

=item * Scalar::Util

=item * Carp

=back

Plus some other core modules and pragmata used by these.

Run

    perl -MModule::Mask -le 'print for keys %INC'

To see a definitive list.

=head1 SEE ALSO

perldoc -f require

L<Module::Util>

=head1 AUTHOR

Matt Lawrence E<lt>mattlaw@cpan.orgE<gt>

=cut

vim: ts=8 sts=4 sw=4 sr et
