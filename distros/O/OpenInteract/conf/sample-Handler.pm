package OpenInteract::Handler::%%UC_FIRST_NAME%%;

# $Id: sample-Handler.pm,v 1.3 2001/09/18 22:04:42 lachoy Exp $

# This is a sample handler. It exists only to provide a template for
# you and some notes on what these configuration variables mean.

use strict;

# If you don't want security for your handler then you can remove this

use SPOPS::Secure qw( :level );

# The first entry in the @ISA implements the 'handler' method and does
# security and sanity checks for you. (The
# 'OpenInteract::Handler::GenericDispatcher' file is found in the
# 'OpenInteract/Handler/' directory of the 'base' package -- check the
# main OI installation for the actual file.)
#
#
# The second entry is how you tell OpenInteract that you want security
# for this handler. You can edit security for a module via the web
# interface -- click on the 'Module Security' link in the 'Admin
# Tools' box to get to the interface.

@OpenInteract::Handler::%%UC_FIRST_NAME%%::ISA     = qw( 
        OpenInteract::Handler::GenericDispatcher  SPOPS::Secure 
);

# Use whatever standard you like here -- it's always nice to let CVS
# deal with it :-)

$OpenInteract::Handler::%%UC_FIRST_NAME%%::VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

# This might seem cosmetic but actually the GenericDispatcher will
# e-mail you if someone tries to call the handler without a method and
# you don't have a default method (see below) defined.

$OpenInteract::Handler::%%UC_FIRST_NAME%%::author            = 'yourname@yourco.com';

# Define a method to call if the user doesn't specify one. This allows
# users to do something like: 'http://.../News/' rather than having to
# remember 'http://.../News/listing/'

$OpenInteract::Handler::%%UC_FIRST_NAME%%::default_method    = 'listing';

# Put a method name here and GenericDispatcher will ensure the method
# cannot be called from the outside world.

@OpenInteract::Handler::%%UC_FIRST_NAME%%::forbidden_methods = ();

# Specify security for the different methods in your handler --
# GenericDispatcher does the actual security checking: you don't have
# to do anything! Note that this is the MINIMUM security necessary to
# execute the method and that it doesn't directly affect object
# security. (Indirectly it does since object creation is govererned by
# this task-level security.)
#
# These ONLY take effect if you've specified 'SPOPS::Secure' in the @ISA.

%OpenInteract::Handler::%%UC_FIRST_NAME%%::security          = ( 
 listing => SEC_LEVEL_READ,  
);

sub listing {

 # These are invoked as class methods so the class is always the first
 # argument; $p is always a hashref (\%p) and always contains at least
 # 'level', which is the security level GenericDispatcher found for
 # this method. (If you're not using security then the level will
 # always be SEC_LEVEL_WRITE.); other handlers and functions can also
 # call your handler. Any arguments they pass in will be as a hashref.

    my ( $class, $p ) = @_;

 # Instantiate "big R" -- the request object. This is typically done
 # at the top of a method to get it out of the way.

    my $R = OpenInteract::Request->instance;

 # We've found the best way to pass parameters is to create a hashref
 # early in the method and then fill it with information and pass it
 # to the template. Another way is to just create variables throughout
 # the method and then pass all the variables in an anonymous hashref
 # argument. But this is more explicit.

    my $params = { main_script => '/%%UC_FIRST_NAME%%',
                   error_msg   => $p->{error_msg} };

 # Retrieve the class corresponding to the '$R->myobj' alias and then
 # call 'fetch_group()' on the class

    $params->{myobj_list} = eval { $R->myobj->fetch_group() };

 # Set the 'error_msg' variable in the template. Most templates call
 # the 'showerror' component with this message to consistently display
 # an error.

    if ( $@ ) {
        $params->{error_msg} = "Could not retrieve objects. Error: $@";
    }

 # Set the title for the page

    $R->{page}{title} = 'My Object Listing';

 # Every method should return either a template processing directive
 # or a call to another handler which will return a template
 # processing directive. Note that '$R->template' is an alias for the
 # default template processing handler.

    return $R->template->handler( {}, $params, 
                                  { name => '%%NAME%%::myobj_list' } );
}

1;

__END__

=pod

=head1 NAME

OpenInteract::Handler::%%UC_FIRST_NAME%% - Handler for this package

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

=head1 TO DO

=head1 SEE ALSO

=head1 AUTHORS

=cut
