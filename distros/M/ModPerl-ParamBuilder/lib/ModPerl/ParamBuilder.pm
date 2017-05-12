package ModPerl::ParamBuilder;
#####################################################################
#
# Module      : ModPerl::ParamBuilder
# Author      : Frank Wiles <frank@revsys.com>
#
# Description : This module is a wrapper that assists in making/using 
#               custom Apache directives easier for the most common 
#               use cases. 
#
#####################################################################

use strict;
use warnings;
use vars qw( $VERSION );

use Carp qw( croak ); 

use Apache2::CmdParms ();
use Apache2::Module ();
use Apache2::ServerUtil (); 

###########################################################
# Variables                                               #
###########################################################
$VERSION        =   '0.08';

###########################################################
# Methods                                                 #
###########################################################

#------------------------------------------------
# new( __PACKAGE__ )
#------------------------------------------------
# Object constructor
#------------------------------------------------
sub new { 
    my $class       = shift; 
    my $package     = shift; 

    # For use when retrieving the configuration 
    if( !defined( $package ) and $class !~ /^ModPerl::ParamBuilder/o ) { 
        $package = $class; 
    }

    # Make sure we receive a package name
    croak( 'No package defined in new() ' . caller . ' ' . $class )
        if ( !defined( $package ) or $package eq '' ); 

    my $self = {}; 

    # In what namespace we are going to install these directives in 
    $$self{_calling_package} = $package; 

    # Array to hold our directives 
    $$self{_directives}      = []; 

    # Objectify this hash :) 
    bless( $self, $class ); 

    return( $self ); 

} # END new 

#------------------------------------------------
# _build_param 
#------------------------------------------------
# This the main meat of this module. It builds
# up our @{ $self{_directives} } array that we
# pass to Apache2::Module::add() to actually
# install them
#------------------------------------------------
sub _build_param { 
    my $self        =   shift; 
    my $opts        =   shift; 

    # Ensure we have some options and do some basic error checking 
    croak( 'No options passed to ModPerl::ParamBuilder::_build_param() ' )
        if ( keys( %{$opts} ) < 1 ); 

    # Make sure we have a name 
    croak( ' \'name\' must be defined in order to build paramater ' ) 
        if !exists( $$opts{name} ); 

    # Hash used in building the directives array 
    my $tmp_hash = {};
    $$tmp_hash{ 'name' }  = $$opts{name}; 

    # The hash key defaults to the name of the directive or
    # the user can override it by passing a 'key' to use
    if( !exists( $$opts{key} ) or $$opts{key} eq '' ) { 
        $$tmp_hash{ 'cmd_data' } = $$opts{name}; 
    }
    else { 
        $$tmp_hash{ 'cmd_data' } = $$opts{key}; 
    }

    # Pass along our error message if there is one
    if( exists( $$opts{err} ) ) { 
        $$tmp_hash{ 'errmsg' } = $$opts{err}; 
    }

    # Determine what type of take we are 
    $$tmp_hash{ 'args_how' } = $self->_determine_take( $$opts{take} ); 

    # Set a function if we aren't given one explicitly
    if( !exists($$opts{func}) or $$opts{func} eq '' ) { 
        $$tmp_hash{ 'func' } = $self->_determine_func($$tmp_hash{'args_how'}); 
    }
    else { 
        $$tmp_hash{ 'func' } = $$opts{func};
    }

    # Store this directive for later loading 
    push( @{ $self->{_directives} }, $tmp_hash ); 

} # END _build_param 

#------------------------------------------------
# _determine_take 
#------------------------------------------------
# Figure out what options we need to take 
#------------------------------------------------
sub _determine_take { 
    my $self        =   shift; 
    my $take        =   shift;  
    my $tmp_value   =   'Apache2::Const::';  # Variable to return to caller

    # We've already explicitly set it, so don't bother trying to
    # determine it
    return( $take ) if ( $take and $take =~ /^Apache2::Const::/o ); 

    # Default to one argument 
    if( !defined( $take ) or $take eq '' ) { 
        return( $tmp_value . 'TAKE1' );
    }

    # Translate any words to numbers 
    if( $take !~ /^\d+$/o ) { 
        $tmp_value .= 'TAKE1'    if $take eq 'one'; 
        $tmp_value .= 'TAKE2'    if $take eq 'two';
        $tmp_value .= 'TAKE3'    if $take eq 'three';
        $tmp_value .= 'TAKE12'   if $take eq 'one_plus'; 
        $tmp_value .= 'TAKE23'   if $take eq 'two_plus';
        $tmp_value .= 'TAKE123'  if $take eq 'one_plus_two'; 
        $tmp_value .= 'ITERATE'  if $take eq 'list'; 
        $tmp_value .= 'ITERATE2' if $take eq 'one_plus_list'; 
    }
    else { 
        $tmp_value .= 'TAKE' . $take; 
    }

    return( $tmp_value ); 

} # END _determine_take 

#------------------------------------------------
# _determine_func
#------------------------------------------------
# This function determines which function we
# should use for processing the directive's 
# values.  It uses the already determined take
# for this. NOTE: This must be called after 
# _determine_take to work properly 
#------------------------------------------------
sub _determine_func {
    my $self        =   shift; 
    my $arg         =   shift; 

    # Make sure we're given an argument 
    croak( 'No argument given to _determine_func method' ) 
        if ( !defined( $arg ) or $arg eq '' ); 

    # Clean up our argument for easier processing
    $arg =~ s/^Apache2::Const:://o; 

    return( __PACKAGE__ . '::Handle_TAKE1'    ) if $arg eq 'TAKE1'; 
    return( __PACKAGE__ . '::Handle_TAKE2'    ) if $arg eq 'TAKE2'; 
    return( __PACKAGE__ . '::Handle_TAKE3'    ) if $arg eq 'TAKE3'; 
    return( __PACKAGE__ . '::Handle_TAKE12'   ) if $arg eq 'TAKE12'; 
    return( __PACKAGE__ . '::Handle_TAKE23'   ) if $arg eq 'TAKE23'; 
    return( __PACKAGE__ . '::Handle_TAKE123'  ) if $arg eq 'TAKE123'; 
    return( __PACKAGE__ . '::Handle_ITERATE'  ) if $arg eq 'ITERATE'; 
    return( __PACKAGE__ . '::Handle_ITERATE2' ) if $arg eq 'ITERATE2'; 

} # END _determine_func 

#------------------------------------------------
# param 
#------------------------------------------------
# Build a directive based on user args
#------------------------------------------------
sub param { 
    my $self        =   shift; 
    my $arg         =   shift; 

    # Make sure we're given something 
    croak( 'No arguments provided to param() method' ) 
        if ( !$arg or $arg eq '' );

    # We either take a simple directive name or a hash of 
    # options for the directive 
    if( ref($arg) ne 'HASH' ) { 
        $self->_build_param( { name => $arg } ); 
    } 
    else { 
        $self->_build_param( $arg ); 
    } 

    return; 

} # END param

#------------------------------------------------
# no_arg 
#------------------------------------------------
# This builds a directive that takes no arguments
# and is simply incremented when it is used
#------------------------------------------------
sub no_arg { 
    my $self        =   shift;
    my $arg         =   shift; 

    # Make sure we're given a name 
    croak( 'No arguments provided to no_arg() method' ) 
        if ( !$arg or $arg eq '' ); 

    # Build it 
    my $tmp_hash = {}; 
    $$tmp_hash{ 'take' } = 'Apache2::Const::NO_ARGS'; 
    $$tmp_hash{ 'func' } = __PACKAGE__ . '::Handle_NO_ARGS';

    # Merge in any user overrides 
    if( ref( $arg ) eq 'HASH' ) { 
        $$tmp_hash{ 'name' } = $$arg{ 'name' }; 
        
        $$tmp_hash{ 'err' } = $$arg{ 'err' } if $$arg{ 'err' };
        $$tmp_hash{ 'key' } = $$arg{ 'key' } if $$arg{ 'key' }; 
    }
    else { 
        $$tmp_hash{ 'name' } = $arg; 
    }

    # Actually build the parameter
    $self->_build_param( $tmp_hash );

} # END no_arg 

#------------------------------------------------
# on_off
#------------------------------------------------
# This builds a flag that is either On or Off
#------------------------------------------------
sub on_off { 
    my $self        =   shift; 
    my $arg         =   shift; 

    # Make sure we're given something 
    croak( 'No arguments provided to on_off() method' ) 
        if ( !$arg or $arg eq '' ); 

    # Build our our args for _build_param
    my $tmp_hash = {}; 
    $$tmp_hash{ 'take' } = 'Apache2::Const::FLAG';
    $$tmp_hash{ 'func' } = $self->{_calling_package} . '::Handle_On_Off'; 

    if( ref( $arg ) eq 'HASH' ) { 

        $$tmp_hash{ 'name' } = $$arg{'name'}; 
        $$tmp_hash{ 'err'  } = $$arg{'err'} if $$arg{'err'}; 
        $$tmp_hash{ 'key'  } = $$arg{'key'} if $$arg{'key'};

    } 
    else { 
        $$tmp_hash{ 'name' } = $arg; 
    }

    # Build the directive
    $self->_build_param( $tmp_hash ); 

} # END flag 

#------------------------------------------------
# yes_no
#------------------------------------------------
# This builds a simple argument that takes a
# Yes or No as it's argument
#------------------------------------------------
sub yes_no {
    my $self        =   shift; 
    my $arg         =   shift; 

    # Make sure we're given a name 
    croak( 'No arguments provided to yes_no() method' ) 
        if ( !$arg or $arg eq '' ); 

    # Build our our args for _build_param
    my $tmp_hash = {}; 
    $$tmp_hash{ 'take' } = 'Apache2::Const::TAKE1';
    $$tmp_hash{ 'func' } = $self->{_calling_package} . '::Handle_Yes_No'; 

    if( ref( $arg ) eq 'HASH' ) { 

        $$tmp_hash{ 'name' } = $$arg{'name'}; 
        $$tmp_hash{ 'err'  } = $$arg{'err'} if $$arg{'err'}; 
        $$tmp_hash{ 'key'  } = $$arg{'key'} if $$arg{'key'};

    } 
    else { 
        $$tmp_hash{ 'name' } = $arg; 
    }

    # Build the directive
    $self->_build_param( $tmp_hash ); 

} # END yes_no 

#------------------------------------------------
# load 
#------------------------------------------------
# Install the newly built directives 
#------------------------------------------------
sub load { 
    my $self        =   shift; 

    # Die if we don't have anything to build 
    if( scalar( @{ $self->{_directives} } ) < 1 ) { 
        croak "No Apache directives defined: $!"; 
    }

    use Data::Dumper; 
    warn( "Loading..." );
    warn( Dumper( $self->{_directives} ) ); 

    # Actually load them
    Apache2::Module::add(   $self->{_calling_package}, 
                            \@{ $self->{_directives} } );

} # END load 

#------------------------------------------------
# get_config
#------------------------------------------------
# This method retrieves the configuration for 
# this module 
#------------------------------------------------
sub get_config { 
    my $self        =   shift; 
    my $r           =   shift; 

    # Use the caller when retrieving from outside of the derived
    # class
    if( !defined($self) ) { 
        $self = caller; 
    }

    # Use the $r we are given, but if we're not given one
    # attempt to get the global one, provided the user has 
    # +GlobalRequest on 
    if( !defined($r) ) { 

        use Apache2::RequestUtil (); 

        # Retrieve global request 
        $r = Apache2::RequestUtil->request or 
            croak   'No request object given to get_config() and '.
                    'PerlOptions +GlobalRequest not set, unable to '.
                    'retrieve configuration without request object'
    }

    # Retrieve the actual configuration 
    no strict 'refs';
    my $return_value = Apache2::Module::get_config( 
                                                    $self->{_calling_package},
                                                    $r->server,
                                                    $r->per_dir_config );

    return( $return_value );

} # END get_config 

#####################################################################
# Below are the functions used to process the arguments of the 
# directives
#####################################################################

#------------------------------------------------
# Handle_TAKE1
#------------------------------------------------
sub Handle_TAKE1 { 
    my ($self, $parms, $arg) = @_; 

    $self->{ $parms->info } = $arg; 

} # END HANDLE_TAKE1

#------------------------------------------------
# Handle_TAKE2
#------------------------------------------------
sub Handle_TAKE2 { 
    my ($self, $parms, $arg1, $arg2) = @_; 

    $self->{ $parms->info } = { arg1 => $arg1, arg2 => $arg2 }; 

} # END HANDLE_TAKE2

#------------------------------------------------
# Handle_TAKE3
#------------------------------------------------
sub Handle_TAKE3 { 
    my ($self, $parms, $arg1, $arg2, $arg3) = @_; 

    $self->{ $parms->info } = { arg1 => $arg1, arg2 => $arg2, arg3 => $arg3 };

} # END HANDLE_TAKE3

#------------------------------------------------
# Handle_TAKE12
#------------------------------------------------
sub Handle_TAKE12 { 
    my ($self, $parms, $arg1, $arg2) = @_; 

    $self->{ $parms->info } = { arg1 => $arg1, arg2 => $arg2 }; 

} # END HANDLE_TAKE12

#------------------------------------------------
# Handle_TAKE23
#------------------------------------------------
sub Handle_TAKE23 { 
    my ($self, $parms, $arg1, $arg2, $arg3) = @_; 

    $self->{ $parms->info } = { arg1 => $arg1, arg2 => $arg2, arg3 => $arg3 };

} # END HANDLE_TAKE23

#------------------------------------------------
# Handle_TAKE123
#------------------------------------------------
sub Handle_TAKE123 { 
    my ($self, $parms, $arg1, $arg2, $arg3) = @_; 

    $self->{ $parms->info } = { arg1 => $arg1, arg2 => $arg2, arg3 => $arg3 };

} # END HANDLE_TAKE123

#------------------------------------------------
# Handle_ITERATE
#------------------------------------------------
# Handle a list 
#------------------------------------------------
sub Handle_ITERATE { 
    my ($self, $parms, $arg) = @_; 

    if( !exists( $self->{ $parms->info } ) ) { 
        $self->{ $parms->info } = []; 
    }

    push( @{ $self->{ $parms->info } }, $arg ); 

} # END HANDLE_ITERATE

#------------------------------------------------
# Handle_ITERATE2
#------------------------------------------------
# Handle a default and a list 
#------------------------------------------------
sub Handle_ITERATE2 { 
    my ($self, $parms, $key, $val) = @_; 

    push( @{ $self->{ $parms->info }{ $key } }, $val ); 

} # END HANDLE_ITERATE2

#------------------------------------------------
# Handle_NO_ARGS
#------------------------------------------------
sub Handle_NO_ARGS { 
    my ($self, $parms) = @_; 

    $self->{ $parms->info }++; 

} # END HANDLE_NO_ARGS

#------------------------------------------------
# Handle_On_Off
#------------------------------------------------
sub Handle_On_Off { 
    my ($self, $parms, $arg) = @_; 

    $self->{ $parms->info } = $arg; 

} # END HANDLE_On_Off

#------------------------------------------------
# Handle_Yes_No
#------------------------------------------------
sub Handle_Yes_No { 
    my ($self, $parms, $arg) = @_; 

    if( $arg =~ /yes/io ) { 
        $arg = 1; 
    }
    else { 
        $arg = 0; 
    }

    $self->{ $parms->info } = $arg; 

} # END HANDLE_Yes_No

# EOF
1; 

__END__

=head1 NAME

ModPerl::ParamBuilder - Makes building custom Apache directives easy

=head1 SYNOPSIS

   package MyApp::Parameters; 

   use ModPerl::ParamBuilder;

   use base qw( 'ModPerl::ParamBuilder' );

   my $builder = ModPerl::ParamBuilder->new( __PACKAGE__ ); 

   # Build simple one argument parameter
   $builder->param( 'Template'     );
   $builder->param( 'PageTitle'    );
   $builder->param( 'ItemsPerPage' );

   # Build an On/Off parameter
   $builder->on_off( 'Caching'     );

   # Build a Yes/No parameter 
   $builder->yes_no( 'AutoCommit'  ); 

   # Build a no argument/flag parameter
   $builder->no_arg( 'Active'      );

   # Build a one argument parameter with a custom error message
   # and special configuration hash key 
   $builder->param( {
                        name    => 'SMTPServer',
                        err     => 'SMTPServer xx.xx.xx.xx',
                        key     => 'smtp_server',
                    });

   # Load the configuration into Apache 
   $builder->load; 

   ################################################
   # And elsewhere in your application
   ################################################
   package MyApp::Main;

   # Retrieve the configuration like so
   my $params   = MyApp::Parameters->new; 
   my $conf_ref = $params->get_config( $r ); 
  
   # Or if you have PerlOptions +GlobalRequest on then you can just
   # call 
   my $conf_ref = $params->get_config; 

=head1 DESCRIPTION

One of the neatest features of mod_perl 2.0 is the ability to easily
create your own custom Apache directives. Not only are they more efficient
to use compared to PerlSetEnv, PerlPassEnv, PerlAddVar, and PerlSetVar,
but they give your application a more polished and professional look and
feel..

Not to mention they're just plain cool. This module aims to make the
already easy, even easier. 

Note that you I<MUST> load your parameter module with PerlLoadModule in
your httpd.conf and not PerlModule.  This is necessary because Apache
needs to load your module earlier than usual in the startup to be able
to read it's own configuration now. 

=head1 METHODS

=head2 new 

    package MyApp::Params;
    use base qw( ModPerl::ParamBuilder );
    my $builder = ModPerl::ParamBuilder->new( __PACKAGE__ ); 

This function creates a new ParamBuilder object. You must pass either
the name of your application's parameter module or use the handy C<__PACKAGE__>
built in. 

=head2 param

This function is used to build the more general directives. To create a
simple directive named Foo that takes one argument you simply call: 

   $builder->param( 'Foo' ); 

Assuming you put your directives in MyApp::Parameters, you can then use 
Foo in Apache httpd.conf like so: 

   PerlLoadModule MyApp::Parameters

   <Location /myapp> 
      SetHandler perl-script 
      Foo Bar 
      PerlResponseHandler MyApp::Main 
   </Location> 

When you retrieve the configuration with C<get_config()> Foo's argument will
be stored in the hash key of the same name ( i.e. 'Foo' ).

C<param()> can also take a hash of options that give you more access to using
some more advanced features of Apache directives.  The valid options are: 

    name -- Name of the directive used in httpd.conf 
    key  -- Hash key to store this directives arguments in 
    err  -- Custom error message used with this directive 
    func -- Custom function used to process the directives on Apache 
            startup. See the mod_perl 2.0 documentation for more 
            information on how to use a custom function for 
            processing and/or validating the arguments 
    take -- How many arguments to take and which are required, etc. 

For example, if you wanted to create a directive named I<SMTPServers> that
took an arbitrarily long list of IP addresses of SMTP server your application
should use, and you wanted it to be stored in the configuration as 'smtp_servers',  it can be built like this: 

   $builder->param({
                      name    => 'SMTPServers',
                      key     => 'smtp_servers',
                      err     => 'SMTPServers xx.xx.xx.xx yy.yy.yy.yy', 
                      take    => 'list',
   });

This list of SMTP servers can then be retrieved like so: 

   my $conf_ref = MyApp::Parameters->get_config; 

   my @smtp_servers = $$conf_ref{smtp_servers}; 

Because C<ModPerl::ParamBuilder> will return a list to you in this case 
rather than a single value. 

The valid options for I<take> are: 

 1    or one          -- Take one argument (default)
 2    or two          -- Take two arguments 
 3    or three        -- Take three arguments 
 12   or one_plus     -- One mandatory argument  with one optional 
 23   or two_plus     -- Two mandatory arguments with an optional third
 123  or one_plus_two -- One mandatory argument  with two optional ones

 list                 -- An arbitrarily long list of arguments 
 one_plus_list        -- One mandatory argument followed by an 
                         arbitrarily long list of additional 
                         arguments 

=head2 no_arg( $name )

This allows you to define an Apache directive which takes no arguments.
Each time this value is used the value in the configuration hash will
be incremented. The value in the hash for the key $name will be undefined
if it does not appear in httpd.conf 

=head2 yes_no( $name )

This creates a simple Yes or No directive.  The value in the configuration
hash will be 1 ( Yes ) or 0 ( No ) depending on the definition in httpd.conf

=head2 on_off( $name )

This creates a simple On or Off directive.  The value in the configuration
hash will be 1 ( On ) or 0 ( No ), just like C<yes_no()>.

=head1 LIMITATIONS

The biggest limitation is that this module ONLY works with mod_perl 2.0 and
above.  There are no plans to support mod_perl 1.x for this module, trust me
you want to upgrade to mod_perl 2 as soon as you can.

This module's intent is not to replace the underlying mod_perl APIs nor 
is it intended to be used for complicated cases where special processing 
is needed.  It is intended to make the simple things simple. 

I<Some things to keep in mind when using ModPerl::ParamBuilder>

This module does not restrict where the directives can be used
in Apache's httpd.conf.  To restrict directives to particular area
( only in main server conf, a VirtualHost, or a Location, etc )
you will need to use the mod_perl APIs to build your directives. 

This also does not do, by default, any error checking or validation 
on the arguments passed to directives. If you create a directive
'NumberOfItemsPerPage' and then put: 

     NumberOfItemsPerPage rhubarb 

Apache will not see this as an error and your configuration hash
for the key 'NumberOfItemsPerPage' will contain the string 'rhubarb'.
You can validate this data in three different ways: 

    1) Validate the configuration data in your application prior to
       using it. 

    2) Instruct ModPerl::ParamBuilder to use a special function for
       processing the arguments by passing the 'func' option. 

    3) Revert to using the mod_perl API where you have more control.

See the appropriate mod_perl 2.0 API modules for how to accomplish 
more in depth processing of directives and their data. 

=head1 BUGS

None that I am aware of.  Please report any you find to the E-mail address
below.

=head1 SEE ALSO  

Apache2::Module(3), Apache2::CmdParms(3), the examples/ directory of this
module, and the mod_perl 2.0 documentation.

=head1 AUTHOR

Frank Wiles <frank@revsys.com> http://www.revsys.com/

=head1 COPYRIGHT 

Revolution Systems, LLC. All rights reserved.

=head1 LICENSE 

This software can be distributed under the same terms as Perl itself. 

=cut
