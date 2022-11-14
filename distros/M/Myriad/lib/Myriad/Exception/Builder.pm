package Myriad::Exception::Builder;

use Myriad::Class class => '';

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Exception::Builder - applies L<Myriad::Exception::Base> to an exception class

=head1 DESCRIPTION

See L<Myriad::Exception> for the rôle that defines the exception API.

=cut

# We deliberately *don't* want class/method keywords, but *do* want MOP
use Object::Pad qw(:experimental);

use Myriad::Exception;
use Myriad::Exception::Base;

use constant CLASS_CREATION_METHOD => Object::Pad::MOP::Class->can('create_class') || Object::Pad::MOP::Class->can('begin_class');

# Not currently used, but nice as a hint
our @EXPORT = our @EXPORT_OK = qw(declare_exception);

# When importing, you can set the default category to avoid some
# repetition when there's a long list of exceptions to be defining
our %DEFAULT_CATEGORY_FOR_CLASS;

our %EXCEPTIONS;

sub import {
    my ($class, %args) = @_;
    my $pkg = caller;
    no strict 'refs';
    $DEFAULT_CATEGORY_FOR_CLASS{$pkg} = delete $args{category} if exists $args{category};
    die 'unexpected parameters: ' . join ',', sort keys %args if %args;
    *{$pkg . '::declare_exception'} = $class->can('declare_exception');
}

=head2 declare_exception

Creates a new exception under the L<Myriad::Exception> namespace.

This will be a class formed from the caller's class:

=over 4

=item * called from C<Myriad::*>, would strip the C<Myriad::> prefix

=item * any other class will remain intact

=back

e.g.  L<Myriad::RPC> when calling this would end up with classes under L<Myriad::Exception::RPC>,
but C<SomeCompany::Service::Example> would get L<Myriad::Exception::SomeCompany::Service::Example>
as the exception base class.

Takes the following parameters:

=over 4

=item * C<$name> - the exception

=item * C<%args> - extra details

=back

Details can currently include:

=over 4

=item * C<category>

=item * C<message>

=back

Returns the generated classname.

=cut

sub declare_exception {
    my ($name, %args) = @_;
    my $caller = caller;
    my $pkg = length($name) ? (join '::', (
        delete($args{package}) || ('Myriad::Exception::' . (caller =~ s{^Myriad::}{}r))
    ), $name) : $caller;
    my $category = delete $args{category} // $DEFAULT_CATEGORY_FOR_CLASS{$caller};
    die 'invalid category ' . $category unless $category =~ /^[0-9a-z_]+$/;
    my $message = delete $args{message} // 'unknown';

    die 'already have exception ' . $pkg if exists $EXCEPTIONS{$pkg};

    $EXCEPTIONS{$pkg} //= create_exception({
        package  => $pkg,
        category => $category,
        message  => $message
    });
    return $pkg;
}

sub create_exception ($details) {
    my $pkg = delete $details->{package} or die 'no package';
    my $category = delete $details->{category} or die 'no category';
    my $message = delete $details->{message} or die 'no message';

    try {
        Myriad::Class->import(
            target  => $pkg,
            class   => '',
        );
        $EXCEPTIONS{$pkg} = my $class = (CLASS_CREATION_METHOD)->(
            'Object::Pad::MOP::Class',
            $pkg,
            extends => 'Myriad::Exception::Base',
        );
        $class->add_role('Myriad::Exception');
        $class->add_method(
            category => sub ($self) { $category }
        );
        $class->add_method(
            message => sub ($self) {
                my $str = $message . ' (category=' . $self->category;
                if($self->reason) {
                    $str .= ' , reason=' . $self->reason;
                }
                return $str . ')';
            }
        );
        { # Until we get class methods in role { } blocks, need to inject this directly
            no strict 'refs';
            *{$pkg . '::throw'} = sub ($class, @args) {
                my $self = blessed($class) ? $class : $class->new(@args);
                die $self;
            };
        }
        $class->seal;
        return $class;
    } catch ($e) {
        $log->errorf('Failed to raise declare exception - %s', $e);
    }
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

