# Paranoid::Args -- Command-line argument parsing functions
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/Args.pm, 2.07 2019/01/30 18:25:27 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Args;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Paranoid;
use Paranoid::Debug qw(:all);

($VERSION) = ( q$Revision: 2.07 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT      = qw(parseArgs);
@EXPORT_OK   = ( @EXPORT, qw(PA_DEBUG PA_VERBOSE PA_HELP PA_VERSION) );
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

# I know, this really doesn't protect the contents...
use constant PA_DEBUG => {
    Short      => 'D',
    Long       => 'debug',
    CountShort => 1,
    };
use constant PA_VERBOSE => {
    Short      => 'v',
    Long       => 'verbose',
    CountShort => 1,
    };
use constant PA_HELP => {
    Short => 'h',
    Long  => 'help',
    };
use constant PA_VERSION => {
    Short => 'V',
    Long  => 'version',
    };

#####################################################################
#
# Module code follows
#
#####################################################################

{

    # Internal boolean flag for noOptions
    my $noOptions = 0;

    sub _NOOPTIONS : lvalue {

        # Purpose:  Gets/sets value of boolean flag $noOptions
        # Returns:  Value of $noOptions
        # Usage:    $flag = _NOOPTIONS;
        # Usage:    _NOOPTIONS = 1;

        $noOptions;
    }

    # Internal errors array
    my @errors;

    sub _resetErrors {

        # Purpose:  Empties @errors
        # Returns:  True (1)
        # Usage:    resetErrors();

        @errors = ();
        return 1;
    }

    sub _pushErrors {

        # Purpose:  Pushes a new string onto the @errors array
        # Returns:  Same argument as called with
        # Usage:    _pushErrors($message);

        my $message = shift;
        push @errors, $message;
        return $message;
    }

    sub listErrors {

        # Purpose:  Gets the contents of @errors
        # Returns:  Contents of @errors
        # Usage:    @errors = listErrors();

        my ( %messages, $n, @indices );

        # Filter out redundant messages
        $n = 0;
        foreach (@errors) {
            $messages{$_}++;
            push @indices, $n if $messages{$_} > 1;
            $n++;
        }
        foreach ( sort { $b <=> $a } @indices ) {
            splice @errors, $_, 1;
        }

        return @errors;
    }

    # Internal options hash
    my %options;

    sub _getOption {

        # Purpose:  Gets the template associated with passed option
        # Returns:  Reference to template hash or undef should the
        #           requested option not be defined
        # Usage:    $tref = _getOption($option);

        my $option = shift;

        return exists $options{$option} ? $options{$option} : undef;
    }

    sub _setOption {

        # Purpose:  Associates the passed option to the passed template in
        #           %options
        # Returns:  True (1)
        # Usage:    _setOption($option, $tref);

        my $option = shift;
        my $tref   = shift;

        $options{$option} = $tref;

        return 1;
    }

    sub _optionsKeys {

        # Purpose:  Returns a list of keys from %options
        # Returns:  keys %options
        # Usage:    @keys = _optionsKeys();

        return keys %options;
    }

    sub _resetOptions {

        # Purpose:  Empties the %options
        # Returns:  True (1)
        # Usage:    _resetOptions();

        %options = ();

        return 1;
    }

    # Internal arguments list
    my @arguments;

    sub _getArgRef {

        # Purpose:  Gets a reference the argument array
        # Returns:  Array reference
        # Usage:    $argRef = _getArgRef();

        return \@arguments;
    }

    sub clearMemory {

        # Purpose:  Empties all internal data structures
        # Returns:  True (1)
        # Usage:    clearMemory();

        _NOOPTIONS = 0;
        _resetErrors();
        _resetOptions();
        @{ _getArgRef() } = ();

        return 1;
    }
}

sub _tLint {

    # Purpose:  Performs basic checks on a given option template for
    #           correctness
    # Returns:  True (1) if all checks pass, False (0) otherwise
    # Usage:    $rv = _tLint($templateRef);

    my $tref = shift;    # Reference to option template hash
    my $rv   = 1;
    my ( $oname, @at );

    pdebug( 'entering w/(%s)', PDLEVEL2, $tref );
    pIn();

    # Get the option name for reporting purposes (should have been populated
    # within parseArgs below)
    $oname = $$tref{Name};

    # Make sure a short or long option is declared
    if ( !defined $oname ) {
        _pushErrors('No short or long option name declared');
        $rv = 0;
    }

    # Make sure the argument template is defined
    if ($rv) {
        unless ( defined $$tref{Template} ) {
            _pushErrors("$oname option declared without a template");
            $rv = 0;
        }
    }

    # Make sure the template contains only supported characters
    if ($rv) {
        unless ( defined $$tref{Template}
            && $$tref{Template} =~ /^[\$\@]*$/s ) {
            _pushErrors( "$oname option declared with an invalid template"
                    . "($$tref{Template})" );
            $rv = 0;
        }
    }

    # Make sure option names are sane
    if ($rv) {
        if ( defined $$tref{Short} ) {
            unless ( $$tref{Short} =~ /^[a-zA-Z0-9]$/s ) {
                _pushErrors(
                    "Invalid name for the short option ($$tref{Short})");
                $rv = 0;
            }
        }
        if ( defined $$tref{Long} ) {
            unless ( $$tref{Long} =~ /^[a-zA-Z0-9-]{2,}$/s ) {
                _pushErrors(
                    "Invalid name for the long option ($$tref{Long})");
                $rv = 0;
            }
        }
    }

    # Make sure '@' is only used once, if at all, and the option isn't
    # set to allow bundling
    if ($rv) {
        if ( $$tref{Template} =~ /\@/sm ) {
            @at = ( $$tref{Template} =~ m#(\@)#sg );
            if ( @at > 1 ) {
                _pushErrors( 'The \'@\' symbol can only be used once in the '
                        . "template for $oname: $_" );
                $rv = 0;
            }
            if ( $$tref{CanBundle} and defined $$tref{Short} ) {
                _pushErrors(
                    "Option $$tref{Short} must have CanBundle set to false "
                        . 'if the template contains \'@\'' );
                $rv = 0;
            }
        }
    }

    # Make sure all values in our lists are defined
    if ($rv) {
        unless ( ref( $$tref{ExclusiveOf} ) eq 'ARRAY' ) {
            _pushErrors( "Option ${oname}'s parameter ExclusiveOf must be an "
                    . 'array reference' );
            $rv = 0;
        }
        unless ( ref( $$tref{AccompaniedBy} ) eq 'ARRAY' ) {
            _pushErrors(
                      "Option ${oname}'s parameter AccompaniedBy must be an "
                    . 'array reference' );
            $rv = 0;
        }
        if ($rv) {
            if ( grep { !defined } @{ $$tref{ExclusiveOf} } ) {
                _pushErrors(
                    "Option $oname has undefined values in ExclusiveOf");
                $rv = 0;
            }
            if ( grep { !defined } @{ $$tref{AccompaniedBy} } ) {
                _pushErrors(
                    "Option $oname has undefined values in ExclusiveOf");
                $rv = 0;
            }
        }
    }

    # Make sure CountShort is enabled only for those with a template of ''
    # or '$'
    if ($rv) {

        if ( $$tref{CountShort} ) {
            unless ( $$tref{Template} =~ /^\$?$/sm ) {
                _pushErrors( "Option $oname has CountShort set but with an "
                        . 'incompatible template' );
                $rv = 0;
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub _getArgs ($$\@) {

    # Purpose:  Takes passed argument template and extracts the requisite
    #           arguments to satisfy it from the argument list.  The
    #           results are stored in the passed option list.
    # Results:  True (1) if successful, False (0) if not
    # Usage:    $rv = _getArgs($option, $argTemplate, @optionArgs);

    my $option      = shift;         # Option name
    my $argTemplate = shift;         # Option argument template
    my $lref        = shift;         # Array reference for retrieved arguments
    my $rv          = 1;
    my $argRef      = _getArgRef();
    my @tmp;

    pdebug( 'entering w/(%s)(%s)(%s)',
        PDLEVEL2, $option, $argTemplate, $lref );
    pIn();

    # Empty the array
    @$lref = ();

    pdebug( 'contents of args: %s', PDLEVEL4, @$argRef );

    # Start checking the contents of $argTemplate
    if ( $argTemplate eq '' ) {

        # Template is '' (boolean option)
        @$lref = (1);

    } elsif ( $argTemplate =~ /\@/s ) {

        # Template has a '@' in it -- we'll need to
        # grab as many of the next arguments as possible.

        # Check the noOptions flags
        if (_NOOPTIONS) {

            # True: gobble up everything left
            push @$lref, @$argRef;
            @$argRef = ();

        } else {

            # False: gobble up to the next option-looking thing
            while ( @$argRef and $$argRef[0] !~ /^--?(?:\w+.*)?$/s ) {
                push @$lref, shift @$argRef;
            }

            # Now, we check to see if the first remaining argument is '--'.
            # If it is then we must set noOptions to true and gobble the
            # rest.
            if ( @$argRef and $$argRef[0] eq '--' ) {
                _NOOPTIONS = 1;
                shift @$argRef;
                push @$lref, @$argRef;
                @$argRef = ();
            }
        }

    } else {

       # The template is not empty and has no '@', so we'll just grab the next
       # n arguments, n being the length of the template

        # Check the noOptions flag
        if (_NOOPTIONS) {

            # True:  grab everything we need
            while ( @$argRef and @$lref < length $argTemplate ) {
                push @$lref, shift @$argRef;
            }

        } else {

            # False:  grab as many non-option-looking things as we can
            while ( @$argRef
                and $$argRef[0] !~ /^--?(?:\w+.*)$/s
                and @$lref < length $argTemplate ) {
                push @$lref, shift @$argRef;
            }

            # Now, we check to see if we still need more arguments and if
            # the first remaining argument is '--'.  If it is then we must
            # set noOptions to true and gobble what we need.
            if (    @$lref < length $argTemplate
                and @$argRef
                and $$argRef[0] eq '--' ) {
                _NOOPTIONS = 1;
                shift @$argRef;
                while ( @$argRef and @$lref < length $argTemplate ) {
                    push @$lref, shift @$argRef;
                }
            }
        }
    }

    # Final check:  did we get minimum requisite number of arguments?
    if ( @$lref < length $argTemplate ) {
        _pushErrors(
            pdebug(
                'Missing the minimum number of arguments for %s', PDLEVEL1,
                $option
                ) );
        $rv = 0;
    } else {
        pdebug( 'extracted the following arguments: %s', PDLEVEL3, @$lref );
    }

    # sublist '@' portions of multicharacter templates
    if ( $rv and $argTemplate =~ /\@/sm and length $argTemplate > 1 ) {
        @tmp = ( [], [], [] );

        # First, shift off all preceding '$'s
        if ( $argTemplate =~ /^(\$+)/s ) {
            @{ $tmp[0] } = splice @$lref, 0, length $1;
        }

        # Next, pop off all trailing '$'
        if ( $argTemplate =~ /(\$+)\$/s ) {
            @{ $tmp[2] } = splice @$lref, -1 * length $1;
        }

        # Everything left belongs to the '@'
        @{ $tmp[1] } = @$lref;

        # Let's put it all together...
        @$lref = ();
        push @$lref, @{ $tmp[0] } if @{ $tmp[0] };
        push @$lref, $tmp[1];
        push @$lref, @{ $tmp[2] } if @{ $tmp[2] };

        pdebug( 'sublisted arguments into: %s', PDLEVEL3, @$lref );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub _storeArgs ($$\@) {

    # Purpose:  Stores the passed option arguments in the passed option
    #           template's Value, but in accordance with parameters in the
    #           template
    # Returns:  True (1)
    # Usage:    _storeArgs($optionTemplate, $argTemplate, @optionArgs);

    my $tref        = shift;
    my $argTemplate = shift;
    my $lref        = shift;

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL2, $tref, $argTemplate, $lref );
    pIn();

    pdebug( 'adding values to %s', PDLEVEL3, $$tref{Name} );

    # Increment our usage counter
    $$tref{Count}++;

    # Store arguments according to the template
    if ( $argTemplate eq '' ) {

        # Template is ''
        $$tref{Value} = 0 unless defined $$tref{Value};
        $$tref{Value}++;
        pdebug( 'Value is now %s', PDLEVEL3, $$tref{Value} );

    } elsif ( $argTemplate eq '$' ) {

        # Template is '$'
        if ( not $$tref{Multiple} or $$tref{CountShort} ) {

            # Store the value directly since we
            # can only be used once
            $$tref{Value} = $$lref[0];
            pdebug( 'Value is now %s', PDLEVEL3, $$tref{Value} );

        } else {

            # Store the value as part of a list since
            # we can be used multiple times
            $$tref{Value} = []
                unless defined $$tref{Value}
                    and ref $$tref{Value} eq 'ARRAY';
            push @{ $$tref{Value} }, $$lref[0];
            pdebug( 'Value is now %s', PDLEVEL3, @{ $$tref{Value} } );
        }

    } else {

        # Template is anything else
        if ( not $$tref{Multiple} ) {

            # Store the values directly in a an array
            # since we can only be used once
            $$tref{Value} = [@$lref];
            pdebug( 'Value is now %s', PDLEVEL3, @{ $$tref{Value} } );

        } else {

            # Store the values as an element of an
            # array since we can be used multiple times
            $$tref{Value} = []
                unless defined $$tref{Value}
                    and ref $$tref{Value} eq 'ARRAY';
            push @{ $$tref{Value} }, [@$lref];
            pdebug( 'Value now has %d sets',
                PDLEVEL3, scalar @{ $$tref{Value} } );
        }
    }

    pOut();
    pdebug( 'leaving w/rv: 1', PDLEVEL2 );

    return 1;
}

sub parseArgs (\@\%;\@) {

    # Purpose:  Extracts and validates all command-line arguments and options,
    #           storing them in an organized hash for easy retrieval
    # Returns:  True (1) if successful, False (0) if not
    # Usage:    $rv = parseArgs(@templates, %options);
    # Usage:    $rv = parseArgs(@templates, %options, @args);

    my $tlref = shift;    # Templates list ref
    my $oref  = shift;    # Options hash ref
    my $paref = shift;    # Program argument list ref
    my $rv    = 1;
    my ( $tref, $oname, $argRef, $arg, $argTemplate );
    my ( @tmp, @oargs, $regex );

    # Validate arguments
    $paref = \@ARGV unless defined $paref;

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL1, $tlref, $oref, $paref );
    pIn();

    # Clear all internal data structures and reset flag
    clearMemory();

    # Empty the passed options hash
    %$oref = ();

    # Make a copy of the argument list
    $argRef  = _getArgRef();
    @$argRef = (@$paref);

    # Assemble %options and lint-check the templates
    foreach (@$tlref) {

        # Make sure the element is a hash reference
        unless ( ref $_ eq 'HASH' ) {
            _pushErrors('Illegal non-hash reference in templates array');
            $rv = 0;
            next;
        }

        # Establish a base template and copy the contents of the passed hash
        $tref = {
            Short         => undef,
            Long          => undef,
            Template      => '',
            Multiple      => 0,
            ExclusiveOf   => [],
            AccompaniedBy => [],
            CanBundle     => 0,
            CountShort    => 0,
            Value         => undef,
            %$_,
            };

        # Set AllOptions for error message reporting
        $$tref{Name} =
               defined $$tref{Short}
            && defined $$tref{Long} ? "-$$tref{Short}/--$$tref{Long}"
            : defined $$tref{Short} ? "-$$tref{Short}"
            : defined $$tref{Long}  ? "--$$tref{Long}"
            :                         undef;

        # Initialize our usage counter
        $$tref{Count} = 0;

        # Anything that has CountShort enabled implies Multiple/CanBundle
        # and a template of '$'
        if ( $$tref{CountShort} ) {
            $$tref{CanBundle} = $$tref{Multiple} = 1;
            $$tref{Template} = '$' if defined $$tref{Long};
        }

        # Anything that has a Short option and a template of '$' or ''
        # implies CanBundle
        $$tref{CanBundle} = 1
            if defined $$tref{Short} and $$tref{Template} eq '';

        # We'll associate both the long and short options to the same hash
        # to make sure that we count/collect everything appropriately.
        #
        # Store the short option
        if ( defined $$tref{Short} and length $$tref{Short} ) {

            # See if a template is already defined
            if ( defined _getOption( $$tref{Short} ) ) {

                # It is -- report the error
                Paranoid::ERROR = _pushErrors(
                    pdebug(
                        'the %s option has more than one template',
                        PDLEVEL1, $$tref{Short} ) );
                $rv = 0;

            } else {

                # It's not -- go ahead and store it
                _setOption( $$tref{Short}, $tref );
            }
        }

        # Store the long option
        if ( defined $$tref{Long} and length $$tref{Long} ) {

            # See if a template is already defined
            if ( defined _getOption( $$tref{Long} ) ) {

                # It is -- report the error
                Paranoid::ERROR = _pushErrors(
                    pdebug(
                        'the %s option has more than one template',
                        PDLEVEL1, $$tref{Long} ) );
                $rv = 0;

            } else {

                # It's not -- go ahead and store it
                _setOption( $$tref{Long}, $tref );
            }
        }

        # Do a basic lint-check on the template
        $rv = 0 unless _tLint($tref);
    }

    if ($rv) {

        while (@$argRef) {
            $arg = shift @$argRef;
            next unless defined $arg;

            # Start testing $arg
            if ( $arg eq '--' and not _NOOPTIONS ) {

                # $arg is '--', so set the no options flag
                _NOOPTIONS = 1;

            } elsif ( not _NOOPTIONS and $arg =~ /^--?/s ) {

                # '--' hasn't been passed yet and this looks
                # like an option...

                # Test types of options
                if ( $arg =~ /^-(\w.*)$/s ) {

                    # With a single '-' it should be a short option.  However,
                    # we'll split the option portion, in case there's more
                    # than one character
                    @tmp = split //s, $1;

                    # If there's more than one character for the option name
                    # it must be either a bunch of bundled options or an
                    # option with a concatenated argument.  In case of the
                    # latter (assuming that CanBundle is set to false (a
                    # prerequisite of argument concatenation) and it has a
                    # template of '$' (another prerequisite)) we'll unshift
                    # the rest of the characters back onto the argument list.
                    #
                    # Oh, but first we'll need to get the applicable
                    # option template and then start testing...
                    $tref = _getOption( $tmp[0] );
                    if (    $#tmp
                        and defined $tref
                        and $$tref{Template} eq '$'
                        and not $$tref{CanBundle} ) {
                        unshift @$argRef, join '', @tmp[ 1 .. $#tmp ];
                        splice @tmp, 1;
                    }

                    # Start processing all remaining short options in @tmp
                    foreach (@tmp) {

                        # Get the template
                        $tref = _getOption($_);

                        # Make sure the option is supported
                        if ( defined $tref ) {

                            # Make sure option allows bundling if bundled
                            if ($#tmp) {
                                unless ( $$tref{CanBundle} ) {
                                    _pushErrors(
                                              "Option $_ used bundled with "
                                            . 'other options' );
                                    $rv = 0;
                                    next;
                                }
                            }

                            # Get the argument template
                            $argTemplate = $$tref{Template};

                            # Override the template if CountShort is true
                            $argTemplate = ''
                                if $argTemplate eq '$'
                                    and $$tref{CountShort};

                            # Get any accompanying arguments
                            unless ( _getArgs( "-$_", $argTemplate, @oargs ) )
                            {
                                $rv = 0;
                                next;
                            }

                            # Check if we've call this more than once
                            if ( not $$tref{Multiple}
                                and $$tref{Count} > 0 ) {
                                _pushErrors(
                                    "Option $$tref{Name} is only allowed "
                                        . 'to be used once' );
                                $rv = 0;
                                next;
                            }

                            # Store the values
                            _storeArgs( $tref, $argTemplate, @oargs );

                        } else {

                            # Warn that this is an unknown option
                            _pushErrors("Unknown short option used: $_");
                            $rv = 0;
                        }
                    }

                } elsif ( $arg =~ /^--([\w-]+)(?:=(.+))?$/sm ) {

                    # Starts with '--', so must be a long option

                    # Save the extracted option/argument portion
                    @tmp = ($1);
                    push @tmp, $2 if defined $2 and length $2;

                    # If this option had an argument portion we need to
                    # unshift it back onto the argument list *provided* it was
                    # a legal argument, i.e., this option had a template of
                    # '$'.
                    $tref = _getOption( $tmp[0] );
                    if ( $#tmp and defined $tref ) {

                        # Test for various templates
                        if ( $$tref{Template} eq '$' ) {

                            # Legal invocation  -- unshift away
                            unshift @$argRef, $tmp[1];

                        } elsif ( $$tref{Template} eq '' ) {

                            # Illegal, no arguments expected
                            _pushErrors( "--$tmp[0] does not require any "
                                    . 'arguments' );
                            $rv = 0;
                            next;

                        } else {

                            # Illegal, can't use concatenated arguments in
                            # more complex templates
                            _pushErrors( "--$tmp[0] cannot be called like "
                                    . 'this when multiple arguments are '
                                    . 'required.' );
                        }
                    }

                    # Handle known options
                    if ( defined $tref ) {

                        # Get the argument template
                        $argTemplate = $$tref{Template};

                        # Snarf extra arguments
                        unless (
                            _getArgs( "--$tmp[0]", $argTemplate, @oargs ) ) {
                            $rv = 0;
                            next;
                        }

                        # Check if we've call this more than once
                        if ( not $$tref{Multiple} and $$tref{Count} > 0 ) {
                            _pushErrors(
                                "Option $$tref{Name} is only allowed to be used once"
                                );
                            $rv = 0;
                            next;
                        }

                        # Store the values
                        _storeArgs( $tref, $argTemplate, @oargs );

                    } else {

                        # Unknown long option
                        _pushErrors("Unknown option: --$tmp[0]");
                        $rv = 0;
                    }

                } else {

                    # Unknown option-looking thingy
                    _pushErrors("Unknown option thingy: $arg");
                    $rv = 0;
                }

            } else {

                # Everything else is payload
                $$oref{PAYLOAD} = [] unless exists $$oref{PAYLOAD};
                push @{ $$oref{PAYLOAD} }, $arg;
            }
        }
    }

    # Make a list of all the arguments that was used
    @tmp = ();
    foreach ( _optionsKeys() ) {
        push @tmp, $_ if ${ _getOption($_) }{Count};
    }

    # Final sanity check
    foreach ( sort @tmp ) {
        $tref = _getOption($_);

        # Make sure nothing was called that is exclusive of
        # other called options
        if ( @{ $$tref{ExclusiveOf} } ) {
            $regex = '(?:' . join( '|', @{ $$tref{ExclusiveOf} } ) . ')';
            if ( grep /^$regex$/sm, @tmp ) {
                _pushErrors(
                    "$$tref{Name} cannot be called with the following options: "
                        . join ', ',
                    @{ $$tref{ExclusiveOf} } );
                $rv = 0;
            }
        }

        # Make sure the option was called in conjunction with others
        foreach $regex ( @{ $$tref{AccompaniedBy} } ) {
            unless ( grep /^\Q$regex\E$/sm, @tmp ) {
                _pushErrors(
                    "$$tref{Name} must be called with the following options: "
                        . join ', ',
                    @{ $$tref{AccompaniedBy} } );
                $rv = 0;
            }
        }

        # Copy the values into %$oref
        $$oref{$_} = $$tref{Value};
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::Args - Command-line argument parsing functions

=head1 VERSION

$Id: lib/Paranoid/Args.pm, 2.07 2019/01/30 18:25:27 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Args;

  $rv = parseArgs(@templates, %opts);
  $rv = parseArgs(@templates, %opts, @args);

  @errors = Paranoid::Args::listErrors();
  Paranoid::Args::clearMemory();

=head1 DESCRIPTION

The purpose of this module is to provide simplified but validated parsing and
extraction of command-line arguments (otherwise known as the contents of
@ARGV).  It is meant to be used in lieu of modules like B<Getopt::Std> and
B<Getopt::Long>, but that does not mean that this module is functionally
equivalent -- it isn't.  There are things that those modules do that this
doesn't, but that's primarily by design.  My priorities are a bit different
when it comes to this particular task.

The primary focus of this module is validation, with the secondary focus being
preservation of context.

=head2 VALIDATION

When validating the use of options and arguments we concern ourselves
primarily the following things:

=over

=item 1)

Is the option accompanied by the requisite arguments?

=item 2)

Was the option called with the other requisite options?

=item 3)

Was the option called without options meant only for mutually exclusive 
use?

=item 4)

Were any unrecognized options used?

=back

This module also does basic sanity validation of all option templates to
ensure correct usage of this module.

=head2 PRESERVATION OF CONTEXT

Simply put, preservation of context means remembering the order and grouping
of associated arguments.  Take the hypothetical case of "tagging" files.  
The traditional approach is to define an option that takes a single string 
argument and apply them to the remaining contents of @ARGV:

  ./foo.pl -t "tag1" file1 file2

This module supports that model, with the option argument template being '$'
for that single string.  But what if you wanted to apply different tags to
different files with one command execution?

  ./foo.pl -t "tag1" file1 file2 -t "tag2" file3

In this case it is important to keep each group of payloads that you want to
operate on separate.  With this module you could instead use an argument
template of '$@', which would return each set independently:

  %opt = (
    't' => [
            [ "tag1", [ "file1", "file2" ] ],
            [ "tag2", [ "file3" ] ],
           ],
          );

Notice that we also preserve the context between the '$' and the '@' by
putting the '@' arguments in a sublist.  With this example that could possible
be considered pointless, but we also support templates like '$$@$' which makes
this very useful.  Now, instead of having to shift or pop off the
encapsulating arguments they now have one permanent ordinal index.  You also
can now just grab the array reference for the '@' portion and iterate over a
complete and separate list rather than having to take a splice of the complete
argument array.

It's probably just me, but I find that a little easier to track.

=head2 SUPPORTED COMMAND-LINE SYNTAX

The following list of syntactical options are supported:

=over

=item o

Short option bundling (i.e., "rm -rf")

=item o

Short option counting (i.e., "ssh -vvv")

=item o

Short option argument concatenation (i.e., "cut -d' '")

=item o

Long option "equals" argument concatenation (i.e., "./configure
--prefix=/usr")

=item o

The use of '--' to designate all following arguments are strictly that, even
if they look like options.

=back

This module don't support the hash key/value pairs (i.e., -s foo=one 
bar=two) or argument type validation (B<Getopt::*> can validate string, 
integer, and floating point argument types).  And while it supports a short 
& long option it doesn't support innumerable aliases in addition.  In 
short, if it isn't explicitly documented it isn't supported, though it 
probably is in B<Getopt::*>.

There are a few restrictions meant to eliminate confusion:

=over

=item 1)

Long and short argument concatenation is only allowed if the argument 
template is '$' (expecting a single argument, only).

=item 2)

Short argument concatenation is furthermore only allowed on arguments 
that aren't allowed to be bundled with other short options.

=item 3) 

Short options supporting bundling can require associate arguments as 
long as '@' is not part of the argument template.

=back

=head1 SUBROUTINES/METHODS

=head2 parseArgs

  $rv = parseArgs(@templates, %opts);
  $rv = parseArgs(@templates, %opts, @args);

Using the option templates passed as the first reference this function 
populates the options hash with all of the parsed options found in the 
passed arguments.  The args list reference can be omitted if you wish the 
function to work off of B<@ARGV>.  Please note that this function makes a
working copy of the array, so no alterations will be made to it.

If any options and/or arguments fail to match the option template, or if 
an option is found with no template, a text message is pushed into an
errors array and the function will return a boolean false.

When the options hash is populated extracted arguments to the options are 
stored in both long and short form as the keys, assuming they were defined 
in the template.  Otherwise it will use whatever form of option was defined.

Any arguments not associated with an option are stored in the options hash 
in a list associated with the key B<PAYLOAD>.  

=head2 Paranoid::Args::listErrors

  @errors = Paranoid::Args::listErrors();

If you need a list of everything that was found wrong during a B<parseArgs>
run, from template errors to command-line argument validation failures, you
can get all of the messages form B<listErrors>.  Please note that we show it
fully qualified because it is B<not> exported.

Each time B<parseArgs> is invoked this array is reset.

=head2 Paranoid::Args::clearMemory

  Paranoid::Args::clearMemory();

If the existence of a (most likely) lightly populated array bothers you, you
may use this function to empty all internal data structures of their contents.
Like B<listErrors> this function is not exported.

=head1 OPTION TEMPLATES

The function provided by this module depends on templates to extract
and validate the options and arguments.  Each option template looks 
similar to the following:

  {
    Short         => 'v',
    Long          => 'verbose',
    Template      => '$',
    CountShort    => 1,
    Multiple      => 1,
    CanBundle     => 1,
    ExclusiveOf   => [],
    AccompaniedBy => [],
  }

This template provides extraction of verbose options in the following (and
similar) forms:

  -vvvvv
  --verbose 5
  --verbose=5

If B<CountShort> was instead false you'd have to say '-v 5' instead of '-vvvvv'.

When the B<parseArgs> function is called the options hash passed to it would
be populated with:

  %opts = (
    'v'        => 5,
    'verbose'  => 5,
    );

The redundancy is intentional.  Regardless of whether you look up the short or
the long name you will be able to retrieve the cumulative value.

The particulars of all key/value pairs in a template are documented below.

B<NOTES:>  The default template is as follows:

        {
            Short         => undef,
            Long          => undef,
            Template      => '',
            Multiple      => 0, 
            ExclusiveOf   => [],
            AccompaniedBy => [],
            CanBundle     => 0,
            CountShort    => 0,
            Value         => undef,
         };

When creating your option templates you only need to specify those that differ
from the defaults.  In addition, there's a few options that are also modified
automatically for you.  If your template consists of a I<Short> option and has
a template of I<''> then I<CanBundle> is automatically set to true.

If I<CountShort> is enabled then I<Multiple> and I<CanBundle> is set to be
true as well.  Additionally, if there is a I<Long> option, the I<Template> is
set to I<'$'>.

=head2 Short

B<Short> refers to the form of the short option style (minus the normal
preceding '-').  If this is left undefined then no short option is supported.

This parameter is set to undef by default.

B<NOTE:>  All short option names must be only one character in length and
consisting only of alphanumeric characters.

=head2 Long

B<Long> refers to the from of the long option style (minus the normal 
preceding '--').  If this is left undefined then no long option is 
supported.

This parameter is set to undef by default.

B<NOTE:> All long option names must be more than one character in length and
consisting only of alphanumeric characters and hyphens.

=head2 Template

B<Template> refers to the argument template which informs us how many, if any,
arguments are required for this option.  A template can consist of zero or 
more of the following characters:

  Char  Description
  ========================================================
  $     The option will be followed by a mandatory argument
  @     The option will be followed by one or more arguments
  ''    No additional arguments are expected

For simple boolean options (like '-f') you'd use a zero-length string as the
template.  The associated value of the option will be either a scalar or a
list reference, depending on various parameters in the option template.

If the option has a template of '' then it is assumed that it is a boolean
option.  The associated value in the options hash would then be a scalar:

  # Template: ''
  # @ARGV:  -vvv
  'v' => 3

with the scalar denoting the number of times it was used in the arguments.
It is the same if the template is '$' but CountShort is true.  In that case,
the template really only applies to the long option (whose argument would set
the initial scalar value), while the short options operate purely as an
incrementer.  However, since everything is processed serially, you get the
following results:

  # Template '$', CountShort is true
  # @ARGV: -vvv --verbose=7 -v --verbose=1 -v
  'v' => 2

If the template is '$', but Multiple is false (mandating that the
option be used only once) the associated value is again scalar:

  # Template: '$'
  # @ARGV: -v3
  'v' => 3

If the template is '$' and Multiple is true then the associated value is an
array reference, with the contents of the array being every argument
associated with each option invocation:

  # Template: '$'
  # @ARGV:  --file foo  --file bar
  'file' => [ 'foo', 'bar' ]

If the template is two or more '$' or contains '@' anywhere in the template
then the associated value is an array reference.  The element where '@' would 
occur would be an array reference to the list containing everything globbed 
up by the '@':

  # Template:  '$@'
  # @ARGV: --chmod 0755 foo bar
  'chmod'   => [ '0755', [ 'foo', 'bar' ] ]

If Multiple is true, each element would be a reference to each invocation of 
the option, with the element organized internally as in the previous example:

  # Template: '@'
  # @ARGV:  --add 5 7 2 --add 4 9
  'add'   => [ [ 5, 7, 2 ], [ 4, 9 ] ]

  # Template: '$@$'
  # @ARGV: --perform one two three four --perform five six seven
  'perform' => [ [ 'one', [ 'two', 'three' ], 'four'],
                 [ 'five', [ 'six' ], 'seven' ] ]

NOTE: You cannot use the '@' character if the short option is allowed to be 
bundled with other options.

This parameter defaults to '' (boolean options).

=head2 Multiple

B<Multiple> is a boolean parameter which, if set, allows an option to be used 
more than once on the command-line.

This parameter defaults to false.

=head2 ExclusiveOf

B<ExclusiveOf> is an array of options that this option cannot be used in 
conjunction with.  If the options in this list contain both short and long
names you do not have to list them both.  Listing only one of the names will
suffice.

This parameter defaults to an empty list.

=head2 AccompaniedBy

B<AccompaniedBy> is array of options that this option must be accompanied by.
If the options in this list contain both short and long names you do not 
have to list them both.  Listing only one of the names will suffice.

This parameter defaults to an empty list.

=head2 CanBundle

B<CanBundle> is a boolean parameter which, if set, allows short options to be 
bundled as part of a single argument (i.e., combining '-r' and '-f' as 
'-rf').

This parameter defaults to false.

B<NOTE:> if you wish to be able to concatenate a short option and its
requisite argument then B<CanBundle> must be set to false.

B<NOTE:> if B<CanBundle> is true and each short option requires a mandatory
argument those arguments will be associated with each option in the order in
which the options were specified.  For example, if 'v' and 'S' each expected 
a mandatory single argument:

  -vuS foo bar

v would be associated with foo, and S with bar.  Bundling of short options 
that use '@' as part of their template is not allowed due to the obvious 
guaranteed problems which will result.

=head1 TEMPLATES

There are a few convenience templates available to code down on code
generation.  These are not exported by default, however, so you'll need
explicitly import the ones you want or import them with the B<:all> tag.

=head2 PA_DEBUG

    {
        Short      => 'D',
        Long       => 'debug',
        CountShort => 1,
    };

=head2 PA_VERBOSE

    {
        Short      => 'v',
        Long       => 'verbose',
        CountShort => 1,
     };

=head2 PA_HELP

    {
        Short => 'h',
        Long  => 'help',
    };

=head2 PA_VERSION

    {
        Short => 'V',
        Long  => 'version',
    };

=head1 DEPENDENCIES

=over

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=back

=head1 EXAMPLE

  @otemplates = (
      {
        Short       => 'v',
        Long        => 'verbose',
        CountShort  => 1,
      },
      {
        Short       => 'f',
        Long        => 'force',
      },
      {
        Short       => 'h',
        Long        => 'host',
        Multiple    => 1,
        CanBundle   => 1,
        Template    => '$',
      },
    );

  # Process @ARGV:  -vvvfh host1 file1 file2 file3
  if (parseArgs(@templates, %opts )) {
    setVerbosity($opts{'verbose'});

    if ($opts{'force'}) {
      foreach (@{ $opts{'host'} }) {
        if (connectToHost($_)) {
          transferFiles(@{ $opts{'PAYLOAD'} });
        }
      }
    }
  } else {
    foreach (@errors) { warn "$_\n" };
  }

=head1 BUGS AND LIMITATIONS

It is not advisable for you to call B<parseArgs> multiple times in a program to
process a list of arguments in sections.  parseArgs uses an internal flag to
note whether or not its seen the '--' argument, which disables all further
recognition of arguments as options.  That flag is set to false with every
invocation, possibly causing problems for later sections if that flag had been
used in a prior section.

This doesn't offer the same range of functionality or flexibility of
B<Getopt::Long>.

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

