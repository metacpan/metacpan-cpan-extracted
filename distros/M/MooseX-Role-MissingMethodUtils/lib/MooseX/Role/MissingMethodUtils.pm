package MooseX::Role::MissingMethodUtils;
{
  $MooseX::Role::MissingMethodUtils::VERSION = '0.02';
}

use Moose::Role;

sub AUTOLOAD
{
    my ($self, @params)  = @_;
    my ($name)           = our $AUTOLOAD =~ /::(\w+)$/;

    my $meth_ref        = $self->can('method_missing');

    if ( $meth_ref ) 
    {
        @_ = ($self, $name, @params);

        goto &{$meth_ref} if $meth_ref;
    }

    return;
}

sub can
{
    my ($self, $method) = @_;

    my $meth_ref = $self->SUPER::can( $method ); 
    
    return $meth_ref if $meth_ref;

    if ( $self->can("responds_to") ) 
    {
        if ( my $meth_ref = $self->responds_to($method) )  
        {
            no strict 'refs'; 
            return *{ $method } = $meth_ref;
        }
    }
}

1;

# ABSTRACT: Getting rid of boilerplate AUTOLOAD stuff




__END__
=pod

=head1 NAME

MooseX::Role::MissingMethodUtils - Getting rid of boilerplate AUTOLOAD stuff

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    package Foo;
    use Moose;

    with 'MooseX::Role::MissingMethodUtils';

    sub method_missing {
        my ($self, $method_name, @params) = @_;

        if ( $method_name eq 'do_this' ) {
            Delegator->do_this; 
        }
    }

    sub responds_to {
        my ($self, $method_name) = @_;

        if ( $method_name =~ /foo/ )
        {
            return sub {
                print "Bar";
            }
        }
    }

=head1 DESCRIPTION

This role will now introduce a method named method_missing. This method is called via AUTOLOAD as a last
resort in the calling chain. 

Three parameters will be passed in to help with delegation: ref to self,method name, and parameters.

=head1 CALLBACKS

=head2 method_missing

Call back method that is called during the AUTOLOAD phase. It's unable to find
a method and will call this method_missing as last resort for delegation.

=head2 responds_to

Call back method that is called during a "can" call. This method needs to just
return a sub ref.

=head1 METHODS

=head2 AUTOLOAD

Just does all the boilerplate autoloading stuff. Will call "method_missing"

=head2 can

A subclass of can, will call "responds_to" if nothing is found in super.

=head1 AUTHOR

Logan Bell <loganbell@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Logan Bell.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

