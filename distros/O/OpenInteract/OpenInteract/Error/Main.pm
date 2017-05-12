package OpenInteract::Error::Main;

# $Id: Main.pm,v 1.7 2002/01/02 02:43:53 lachoy Exp $

use strict;
require Exporter;
use vars         qw( $ERROR_HOLD );
use Carp         qw( carp );
use Data::Dumper qw( Dumper );

$ERROR_HOLD = 'error_hold';

@OpenInteract::Error::Main::ISA       = qw( Exporter );
$OpenInteract::Error::Main::VERSION   = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);
@OpenInteract::Error::Main::EXPORT_OK = qw( $ERROR_HOLD );


sub catch {
    my ( $class, $err ) = @_;
    my $R = OpenInteract::Request->instance;

    # Find the action and its error handlers

    my $action = lc $err->{action};
    $R->DEBUG && $R->scrib( 1, "Action where the error was thrown from: <<$action>>" );
    my $MOD_INFO = $R->error_handlers;
    my $err_class_list = $MOD_INFO->{ $action } || [];
    push @{ $err_class_list }, $MOD_INFO->{'_DEFAULT_HANDLER'};

    # For every handler, see if it can catch the error
    # If so, it returns a coderef to run; if not, it simply
    # returns undef or any other false value.

    foreach my $err_class ( @{ $err_class_list } ) {
        $R->DEBUG && $R->scrib( 1, "See if class <<$err_class>> will take error" );
        my $info = $err_class->can_handle_error( $err );
        next if ( ! $info or ! ref $info or ref $info ne 'CODE' );
        return $info->( $err );
    }
    die "Cannot handle error thrown: ", Dumper( $err );
}


# Just initialize the module info and the default error handler

sub initialize {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;
    my $handler_info = {};
    my $action_info = $p->{config}{action};
    foreach my $action ( keys %{ $action_info } ) {
        $handler_info->{ lc $action } = $action_info->{ lc $action }{error};
    }
    $handler_info->{'_DEFAULT_HANDLER'} = $p->{config}{error}{default_error_handler} ||
                                          $p->{config}{default_error_handler};
    $class->require_error_handlers( $handler_info );
    my $stash_class = $p->{config}{server_info}{stash_class};
    $stash_class->set_stash( 'error_handlers', $handler_info );
    $R->DEBUG && $R->scrib( 1, "Initialized DEFAULT_HANDLER for app",
                               "($stash_class) to ($handler_info->{'_DEFAULT_HANDLER'})" );
}


sub require_error_handlers {
    my ( $class, $handlers ) = @_;
    foreach my $h ( values %{ $handlers } ) {
        my $handler_list = ( ref $h ) ? $h : [ $h ];
        foreach my $error_handler ( @{ $handler_list } ) {
            next unless ( $error_handler );
            eval "require $error_handler";
        }
    }
}


sub save_error {
    my ( $class, $err ) = @_;
    eval { $err->save() };
    if ( $@ ) { carp " Cannot save error $err->{code}: $@"; }
    else      { carp " Error saved ok (ID: $err->{error_id})."; }
    return $err->id;
}

1;

__END__

=pod

=head1 NAME

OpenInteract::Error::Main - Catches all errors and dispatches to proper handler

=head1 SYNOPSIS

 $R->throw( { code => 412, type => 'db' } );

=head1 DESCRIPTION

This class catches all errors thrown by the framework. It then 
inspects the error, reviews the current context and decides which
class and method should handle the error.

To do this, it needs to be able to determine a few things:

=over 4

=item *

What type of error is this? The code (and possibly type) found in the
error passed to I<catch()> should be sufficient to distinguish errors
from one another.

=item *

From where was the error thrown? This is a crucial piece of
information, because it determines which set of error handlers we
inspect. We get this information from $R in the {current_context}
key. This key is either set by hand, or set when we call the
I<lookup_action()> method of $R.

=back

The main method, I<catch()>, determines the context in which the error
was thrown. (This should be simple: just ask $R.) It then determines
which error handler(s) should be queried as to whether it/they can
deal with the error thrown.

The last entry in the list of error handlers should always be the
default system catalog of error handlers. They may be generic, but
they can catch any error and return something more meaningful than
'Internal Systen Error.'

=head1 METHODS

B<catch( $err )>

Discussed above.

B<initialize( { config => $C } )>

Should be called from the Apache child init handler. In your startup
file, be sure to add something like this:

 Apache->push_handlers( PerlChildInitHandler => sub {
   ...blah blah blah...

   OpenInteract::Error::Main->initialize( { config => $C } );

   ...blah blah blah...
  }
 )

This initializes the class with information from all the packages,
including the handlers they intend to use for their errors.

=head1 TO DO

Nothing.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
