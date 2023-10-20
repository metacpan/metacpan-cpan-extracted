# Parse::PlainConfig::Legacy -- Parsing Engine Legacy for Parse::PlainConfig
#
# (c) 2002 - 2023, Arthur Corliss <corliss@digitalmages.com>,
#
# $Id: lib/Parse/PlainConfig/Legacy.pm, 3.06 2023/09/23 19:24:20 acorliss Exp $
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

package Parse::PlainConfig::Legacy;

use 5.006;

use strict;
use warnings;
use vars qw($VERSION);

($VERSION) = ( q$Revision: 3.06 $ =~ /(\d+(?:\.(\d+))+)/sm );

use Parse::PlainConfig::Constants qw(:all);
use Text::ParseWords;
use Text::Tabs;
use Carp;
use Fcntl qw(:flock);
use Paranoid;
use Paranoid::Data;
use Paranoid::Debug;
use Paranoid::Filesystem;
use Paranoid::Input;
use Paranoid::IO qw(:all);
use Paranoid::IO::Line;

#####################################################################
#
# Module code follows
#
#####################################################################

{
    my $ERROR = '';

    sub ERROR : lvalue {
        $ERROR;
    }
}

sub new {

    # Purpose:  Creates a new object
    # Returns:  Object reference if successful, undef if not
    # Usage:    $obj = Parse::PlainConfig->new(%PARAMS);

    my $class = shift;
    my $self  = {
        CONF         => {},
        ORDER        => [],
        FILE         => undef,
        PARAM_DELIM  => ':',
        LIST_DELIM   => ',',
        HASH_DELIM   => '=>',
        AUTOPURGE    => 0,
        COERCE       => {},
        DEFAULTS     => {},
        SMART_PARSER => 0,
        PADDING      => 2,
        MAX_BYTES    => PPC_DEF_SIZE,
        MTIME        => 0,
        };
    my %args = @_;
    my ( $k, $v, $rv );

    subPreamble( PPCDLEVEL1, '$%', $class, %args );

    bless $self, $class;

    # Assign all the arguments
    $rv = 1;
    while ( $rv && scalar keys %args ) {
        $k = shift @{ [ keys %args ] };
        $v = $args{$k};
        delete $args{$k};
        $rv = 0 unless $self->property( $k, $v );
    }

    $self = undef unless $rv;

    subPostamble( PPCDLEVEL1, '$', $self );

    return $self;
}

sub property {

    # Purpose:  Gets/sets object property value
    # Returns:  Value of property in Get mode, true/false in set mode
    # Usage:    $value = $obj->property($name);
    # Usage:    $rv = $obj->property($name, $value);

    my $self = shift;
    my @args = @_;
    my $arg  = $_[0];
    my $val  = $_[1];
    my $ival = defined $val ? $val : 'undef';
    my $rv   = 1;
    my ( $k, $v );

    croak 'Mandatory first argument must be a valid property name'
        unless defined $arg and exists $$self{$arg};

    subPreamble( PPCDLEVEL1, '$$', $arg, $val );

    pdebug( 'method is in ' . ( scalar @args == 2 ? 'set' : 'get' ) . ' mode',
        PPCDLEVEL1 );
    $arg = uc $arg;

    # Validate arguments & value
    if ( scalar @args == 2 ) {

        if ( $arg eq 'ORDER' ) {

            # ORDER must be a list reference
            unless ( ref $val eq 'ARRAY' ) {
                $rv = 0;
                Parse::PlainConfig::Legacy::ERROR =
                    pdebug( '%s\'s value must be a list reference',
                    PPCDLEVEL1, $arg );
            }

        } elsif ( $arg eq 'CONF' or $arg eq 'COERCE' or $arg eq 'DEFAULTS' ) {

            # CONF, COERCE, and DEFAULTS must be a hash reference
            unless ( ref $val eq 'HASH' ) {
                $rv = 0;
                Parse::PlainConfig::Legacy::ERROR =
                    pdebug( '%s\'s value must be a hash reference',
                    PPCDLEVEL1, $arg );
            }

            if ($rv) {

                if ( $arg eq 'COERCE' ) {

                    # Validate each key/value pair in COERCE
                    foreach ( keys %$val ) {
                        $ival = defined $$val{$_} ? $$val{$_} : 'undef';
                        unless ( $ival eq 'string'
                            or $ival eq 'list'
                            or $ival eq 'hash' ) {
                            Parse::PlainConfig::Legacy::ERROR = pdebug(
                                'coerced data type (%s: %s) not a string, list, or hash',
                                PPCDLEVEL1, $_, $ival
                                );
                            $rv = 0;
                        }
                    }
                } elsif ( $arg eq 'DEFAULTS' ) {

                    # Copy over the defaults into CONF (not overriding
                    # existing values)
                    while ( ( $k, $v ) = each %{ $$self{DEFAULTS} } ) {
                        $$self{CONF}{$k} = { 'Value' => $v }
                            unless exists $$self{CONF}{$k};
                    }
                }
            }

            # TODO:  Validate properties like PADDING that have a concrete
            # TODO:  list of valid values?

        } elsif ( ref $val ne '' ) {

            # Everything else should be a scalar value
            $rv = 0;
            Parse::PlainConfig::Legacy::ERROR =
                pdebug( '%s\'s value must be a scalar value',
                PPCDLEVEL1, $arg );
        }
    }

    # Set the value if all's kosher
    if ($rv) {
        if ( scalar @args == 2 ) {

            # Assign the value
            if ( ref $val eq 'ARRAY' ) {

                # Copy array contents in
                $$self{$arg} = [@$val];

            } elsif ( ref $val eq 'HASH' ) {

                # Copy hash contents in
                $$self{$arg} = {%$val};

            } else {

                # Assign the scalar value
                $$self{$arg} = $val;
            }
        } else {

            # Copy the value
            if ( defined $$self{$arg} and ref $$self{$arg} ne '' ) {
                $rv =
                      ref $$self{$arg} eq 'ARRAY' ? []
                    : ref $$self{$arg} eq 'HASH'  ? {}
                    :                               undef;
                if ( defined $rv ) {
                    unless ( deepCopy( $$self{$arg}, $rv ) ) {
                        Parse::PlainConfig::Legacy::ERROR =
                            pdebug( 'failed to copy data from %s: %s',
                            PPCDLEVEL1, Paranoid::ERROR, $arg );
                    }
                } else {
                    Parse::PlainConfig::Legacy::ERROR =
                        pdebug( 'I don\'t know how to copy %s (%s)',
                        PPCDLEVEL1, $$self{$arg}, $arg );
                }
            } else {
                $rv = $$self{$arg};
            }
        }
    }

    subPostamble( PPCDLEVEL1, '$', $rv );

    return $rv;
}

sub purge {

    # Purpose:  Performs a manual purge of internal data
    # Returns:  True
    # Usage:    $obj->purge;

    my $self = shift;
    my ( $k, $v );

    subPreamble( PPCDLEVEL1, '$', $self );

    # First, purge all existing values
    delete @{ $$self{CONF} }{ keys %{ $$self{CONF} } };

    # Second, apply default values
    while ( ( $k, $v ) = each %{ $$self{DEFAULTS} } ) {
        $$self{CONF}{$k} = { 'Value' => $v };
    }

    subPostamble( PPCDLEVEL1, '$', 1 );

    return 1;
}

sub read {

    # Purpose:  Reads either the passed filename or an internally recorded one
    # Returns:  True or false depending on success of read & parse
    # Usage:    $rv = $obj->read;
    # Usage:    $rv = $obj->read($filename);

    my $self    = shift;
    my $file    = shift || $$self{FILE};
    my $rv      = 0;
    my $oldSize = PIOMAXFSIZE;
    my ( $line, @lines );

    croak 'Optional first argument must be a defined filename or the FILE '
        . 'property must be set'
        unless defined $file;

    subPreamble( PPCDLEVEL1, '$$', $self, $file );

    # Reset the error string and update the internal filename
    Parse::PlainConfig::Legacy::ERROR = '';
    $$self{FILE} = $file;

    # Temporarily set the specified size limit
    PIOMAXFSIZE = $$self{MAX_BYTES};

    # Store the file's current mtime
    $$self{MTIME} = ( stat $file )[MTIME];

    if ( detaint( $file, 'filename' ) ) {
        if ( slurp( $file, @lines, 1 ) ) {

            # Empty the current config hash and key order
            $self->purge if $$self{AUTOPURGE};

            # Parse the rc file's lines
            $rv = $self->_parse(@lines);

        } else {
            Parse::PlainConfig::Legacy::ERROR =
                pdebug( Paranoid::ERROR, PPCDLEVEL1 );
        }
    } else {
        Parse::PlainConfig::Legacy::ERROR =
            pdebug( 'Filename failed detaint check', PPCDLEVEL1 );
    }

    # Restore old size limit
    PIOMAXFSIZE = $oldSize;

    subPostamble( PPCDLEVEL1, '$', $rv );

    # Return the result code
    return $rv;
}

sub readIfNewer ($) {

    # Purpose:  Performs a file read/parse if the file is newer than last read
    # Returns:  1 if read/parse was successful, 2 if file is the same age, 0
    #           on any errors
    # Usage:    $rv = $obj->readIfNewer;

    my $self   = shift;
    my $file   = $$self{FILE};
    my $omtime = $$self{MTIME};
    my $rv     = 0;
    my $mtime;

    croak 'The FILE property must be set' unless defined $file;

    subPreamble( PPCDLEVEL1, '$', $self );

    # Try to read the file
    if ( -e $file && -r _ ) {

        # File exists and appears to be readable, get the mtime
        $mtime = ( stat _ )[MTIME];
        pdebug( 'current mtime: %s last: %s', PPCDLEVEL2, $mtime, $omtime );

        # Read the file if it's newer, or return 2
        $rv = $mtime > $omtime ? $self->read : 2;

    } else {

        # Report errors
        Parse::PlainConfig::Legacy::ERROR =
            pdebug( 'file (%s) does not exist or is not readable',
            PPCDLEVEL1, $file );
    }

    subPostamble( PPCDLEVEL1, '$', $rv );

    # Return the result code
    return $rv;
}

sub write {

    # Purpose:  Writes the file to disk
    # Returns:  True/False depending on success of write
    # Usage:    $rv = $obj->write;
    # Usage:    $rv = $obj->write($filename);

    my $self       = shift;
    my $file       = shift || $$self{FILE};
    my $padding    = shift;
    my $conf       = $$self{CONF};
    my $order      = $$self{ORDER};
    my $coerce     = $$self{COERCE};
    my $smart      = $$self{SMART_PARSER};
    my $paramDelim = $$self{PARAM_DELIM};
    my $hashDelim  = $$self{HASH_DELIM};
    my $listDelim  = $$self{LIST_DELIM};
    my $rv         = 0;
    my $tw         = DEFAULT_TW;
    my $delimRegex = qr/(?:\Q$hashDelim\E|\Q$listDelim\E)/sm;
    my ( @forder, $type, $param, $value, $description, $entry, $out );
    my ( $tmp, $tvalue, $lines, $fh );

    # TODO: Implement non-blocking flock support
    # TODO: Store read padding and/or use PADDING property value

    croak 'Optional first argument must be a defined filename or the FILE '
        . 'property must be set'
        unless defined $file;

    $padding = 2 unless defined $padding;
    $tw -= 2 unless $smart;

    subPreamble( PPCDLEVEL1, '$$$', $self, $file, $padding );

    # Pad the delimiter as specified
    $paramDelim =
          $padding == 0 ? $paramDelim
        : $padding == 1 ? " $paramDelim"
        : $padding == 2 ? "$paramDelim "
        :                 " $paramDelim ";
    pdebug( 'PARAM_DELIM w/padding is \'%s\'', PPCDLEVEL2, $paramDelim );

    # Create a list of parameters for output
    @forder = @$order;
    foreach $tmp ( sort keys %$conf ) {
        push @forder, $tmp
            unless grep /^\Q$tmp\E$/sm, @forder;
    }
    pdebug( "order of params to be written:\n\t%s", PPCDLEVEL2, @forder );

    # Compose the new output
    $out = '';
    foreach $param (@forder) {

        # Determine the datatype
        $value = exists $$conf{$param} ? $$conf{$param}{Value} : '';
        $description =
            exists $$conf{$param} ? $$conf{$param}{Description} : '';
        $type =
              exists $$coerce{$param} ? $$coerce{$param}
            : ref $value eq 'HASH'  ? 'hash'
            : ref $value eq 'ARRAY' ? 'list'
            :                         'string';
        pdebug( 'adding %s param (%s)', PPCDLEVEL2, $type, $param );

        # Append the comments
        $out .= $description;
        $out .= "\n" unless $out =~ /\n$/sm;

        # Start the new entry with the parameter name and delimiter
        $entry = "$param$paramDelim";

        # Append the value, taking into consideration the smart parser
        # and coercion settings
        if ( $type eq 'string' ) {

            # String type
            $tvalue = $value;
            unless ( $smart && exists $$coerce{$param} ) {
                $tvalue =~ s/"/\\"/smg;
                $tvalue = "\"$tvalue\"" if $tvalue =~ /$delimRegex/sm;
            }
            $lines = "$entry$tvalue";

        } elsif ( $type eq 'list' ) {

            # List type
            $tvalue = [@$value];
            foreach (@$tvalue) {
                s/"/\\"/smg;
                if ( $smart && exists $$coerce{$param} ) {
                    $_ = "\"$_\"" if /\Q$listDelim\E/sm;
                } else {
                    $_ = "\"$_\"" if /$delimRegex/sm;
                }
            }
            $lines = $entry . join " $listDelim ", @$tvalue;

        } else {

            # Hash type
            $tvalue = {%$value};
            foreach ( keys %$tvalue ) {
                $tmp = $_;
                $tmp =~ s/"/\\"/smg;
                $tmp = "\"$tmp\"" if /$delimRegex/sm;
                if ( $tmp ne $_ ) {
                    $$tvalue{$tmp} = $$tvalue{$_};
                    delete $$tvalue{$_};
                }
                $$tvalue{$tmp} =~ s/"/\\"/smg;
                $$tvalue{$tmp} = "\"$$tvalue{$tmp}\""
                    if $$tvalue{$tmp} =~ /$delimRegex/sm;
            }
            $lines = $entry
                . join " $listDelim ",
                map {"$_ $hashDelim $$tvalue{$_}"} sort keys %$tvalue;
        }

        # wrap the output to the column width and append to the output
        $out .= _wrap( '', "\t", $tw, ( $smart ? "\n" : "\\\n" ), $lines );
        $out .= "\n" unless $out =~ /\n$/sm;
    }

    # Write the file
    if ( detaint( $file, 'filename' ) ) {
        if ( open $fh, '>', $file ) {

            # Write the file
            flock $fh, LOCK_EX;
            if ( print $fh $out ) {
                $rv = 1;
            } else {
                Parse::PlainConfig::Legacy::ERROR = $!;
            }
            flock $fh, LOCK_UN;
            close $fh;

            # Store the new mtime on successful writes
            $$self{MTIME} = ( stat $file )[MTIME] if $rv;

        } else {

            # Report the errors
            Parse::PlainConfig::Legacy::ERROR =
                pdebug( 'error writing file: %s', PPCDLEVEL1, $! );
        }
    } else {

        # Detainting filename failed
        Parse::PlainConfig::Legacy::ERROR =
            pdebug( 'illegal characters in filename: %s', PPCDLEVEL1, $file );
    }

    subPostamble( PPCDLEVEL1, '$', $rv );

    return $rv;
}

sub parameters {

    # Purpose:  Returns a list of all parsed parameters
    # Returns:  List of parameter names with configure values
    # Usage:    @params = $obj->parameters;

    my $self       = shift;
    my @parameters = keys %{ $$self{CONF} };

    pdebug( 'called method -- rv: %s', PPCDLEVEL1, @parameters );

    return @parameters;
}

sub parameter {

    # Purpose:  Gets/sets named parameter
    # Returns:  True/false in set mode, Parameter value in get mode
    # Usage:    $rv = $obj->parameter($name);
    # Usage:    $rv = $obj->parameter($name, $value);

    my $self       = shift;
    my @args       = @_;
    my $param      = $args[0];
    my $value      = $args[1];
    my $ivalue     = defined $value ? $value : 'undef';
    my $conf       = $$self{CONF};
    my $listDelim  = $$self{LIST_DELIM};
    my $hashDelim  = $$self{HASH_DELIM};
    my $paramDelim = $$self{PARAM_DELIM};
    my $coerceType =
        exists $$self{COERCE}{$param}
        ? $$self{COERCE}{$param}
        : 'undef';
    my $defaults   = $$self{DEFAULTS};
    my $rv         = 1;
    my $delimRegex = qr/(?:\Q$hashDelim\E|\Q$listDelim\E)/sm;
    my ( $finalValue, @elements );

    # TODO: Consider storing a list/hash padding value as well, for use
    # TODO: in coercion to string.

    croak 'Mandatory firest argument must be a defined parameter name'
        unless defined $param;

    subPreamble( PPCDLEVEL1, '$$$', $self, $param, $ivalue );

    if ( scalar @args == 2 ) {
        pdebug( 'method in set mode', PPCDLEVEL1 );

        # Create a blank record if it hasn't been defined yet
        $$conf{$param} = {
            Value       => '',
            Description => '',
            }
            unless exists $$conf{$param};

        # Start processing value assignment
        if ( $coerceType ne 'undef' ) {
            pdebug( 'coercing into %s', PPCDLEVEL2, $coerceType );

            # Parameter has a specific data type to be coerced into
            if ( $coerceType eq 'string' && ref $value ne '' ) {

                # Coerce values into strings
                if ( ref $value eq 'ARRAY' ) {

                    # Convert lists into a string using the list delimiter
                    foreach (@$value) {
                        s/"/\\"/smg;
                        $_ = "\"$_\"" if /\Q$listDelim\E/sm;
                    }
                    $finalValue = join " $listDelim ", @$value;

                } elsif ( ref $value eq 'HASH' ) {

                    # Convert hashes into a string using the hash & list
                    # delimiters
                    foreach ( sort keys %$value ) {
                        $ivalue = $_;
                        $ivalue =~ s/"/\\"/smg;
                        $ivalue = "\"$ivalue\""
                            if /(?:\Q$hashDelim\E|\Q$listDelim\E)/sm;
                        $$value{$_} = '' unless defined $$value{$_};
                        $$value{$_} = "\"$$value{$_}\""
                            if $$value{$_} =~
                                /(?:\Q$hashDelim\E|\Q$listDelim\E)/sm;
                        push @elements,
                            join " $hashDelim ", $_,
                            ( defined $$value{$_} ? $$value{$_} : '' );
                    }
                    $finalValue = join " $listDelim ", @elements;

                } else {

                    # Try to stringify everything else
                    $finalValue = "$value";
                }

            } elsif ( $coerceType eq 'list' && ref $value ne 'ARRAY' ) {

                # Coerce value into a list
                if ( ref $value eq 'HASH' ) {

                    # Convert hashes into a list
                    $finalValue = [];
                    foreach ( sort keys %$value ) {
                        push @$finalValue, $_, $$value{$_};
                    }

                } elsif ( ref $value eq '' ) {

                    # Convert strings into a list
                    $self->_parse(
                        split /\n/sm,
                        "$$conf{$param}{Description}\n"
                            . "$param $paramDelim $value"
                            );
                    $finalValue = $$conf{$param}{Value};

                } else {

                    # Stringify everything else and put it into an array
                    $finalValue = ["$value"];
                }

            } elsif ( $coerceType eq 'hash' && ref $value ne 'HASH' ) {

                # Coerce value into a hash
                if ( ref $value eq 'ARRAY' ) {

                    # Convert a list into a hash using every two elements
                    # as a key/value pair
                    push @$value, ''
                        unless int( scalar @$value / 2 ) ==
                            scalar @$value / 2;
                    $finalValue = {@$value};

                } elsif ( ref $value eq '' ) {

                    # Convert strings into a hash
                    $self->_parse(
                        split /\n/sm,
                        "$$conf{$param}{Description}\n"
                            . "$param $paramDelim $value"
                            );
                    $finalValue = $$conf{$param}{Value};

                } else {

                    # Stringify everything else and put the value into the
                    # hash key
                    $finalValue = { "$value" => '' };
                }

            } else {

                # No coercion is necessary
                $finalValue = $value;
            }

        } else {
            pdebug( 'no coercion to do', PPCDLEVEL2 );
            $finalValue = $value;
        }
        $$conf{$param}{Value} = $finalValue;

    } else {
        pdebug( 'method in retrieve mode', PPCDLEVEL1 );
        $rv =
              exists $$conf{$param}     ? $$conf{$param}{Value}
            : exists $$defaults{$param} ? $$defaults{$param}
            :                             undef;
    }

    subPostamble( PPCDLEVEL1, '$', $rv );

    return ref $rv eq 'HASH' ? (%$rv) : ref $rv eq 'ARRAY' ? (@$rv) : $rv;
}

sub coerce {

    # Purpose:  Assigns the passed list to a data type and attempts to
    #           coerce each existing value into that data type.
    # Returns:  True or false.
    # Usage:    $rv = $obj->coerce($type, @fields);

    my $self   = shift;
    my $type   = shift;
    my $itype  = defined $type ? $type : 'undef';
    my @params = @_;
    my $rv     = 1;

    croak 'Mandatory first argument must be "string", "list", or "hash"'
        unless $itype eq 'string'
            or $itype eq 'list'
            or $itype eq 'hash';
    croak 'Remaining arguments must be defined parameter names'
        unless @params;

    subPreamble( PPCDLEVEL1, '$$@', $self, $type, @params );

    foreach (@params) {
        if (defined) {

            # Mark the parameter
            $$self{COERCE}{$_} = $type;
            $self->parameter( $_, $$self{CONF}{$_}{Value} )
                if exists $$self{CONF}{$_};
        } else {

            # Report undefined parameter names
            Parse::PlainConfig::Legacy::ERROR =
                pdebug( 'passed undefined parameter names to coerce',
                PPCDLEVEL1 );
            $rv = 0;
        }
    }

    subPostamble( PPCDLEVEL1, '$', $rv );

    return $rv;
}

sub describe {

    # Purpose:  Assigns descriptive comments to specific parameters
    # Returns:  True
    # Usage:    $obj->describe(%descriptions);

    my $self   = shift;
    my $conf   = $$self{CONF};
    my $coerce = $$self{COERCE};
    my %new    = (@_);

    subPreamble( PPCDLEVEL1, '$', $self );

    # TODO: Consider allowing comment tags to be specified

    # TODO: Consider line splitting and comment tag prepending where
    # TODO: it's not already done.

    foreach ( keys %new ) {
        pdebug( '%s is described as \'%s\'', PPCDLEVEL1, $_, $new{$_} );
        unless ( exists $$conf{$_} ) {
            $$conf{$_} = {};
            if ( exists $$coerce{$_} ) {
                $$conf{$_}{Value} =
                      $$coerce{$_} eq 'list' ? []
                    : $$coerce{$_} eq 'hash' ? {}
                    :                          '';
            } else {
                $$conf{$_}{Value} = '';
            }
        }
        $$conf{$_}{Description} = $new{$_};
    }

    subPostamble( PPCDLEVEL1, '$', 1 );

    return 1;
}

sub order {

    # Purpose:  Gets/sets order of parameters in file
    # Returns:  Ordered list of named parameters
    # Usage:    @params = $obj->order;
    # Usage:    @params = $obj->order(@newOrder);

    my $self  = shift;
    my $order = $$self{ORDER};
    my @new   = (@_);

    pdebug( 'entering w/(%s)', PPCDLEVEL1, @new );

    @$order = (@new) if scalar @new;

    pdebug( 'leaving w/rv: %s', PPCDLEVEL1, @$order );

    return @$order;
}

sub _parse {

    # Purpose:  Parses the passed list of lines and extracts comments,
    #           fields, and values and storing everything into the CONF
    #           hash
    # Returns:  True or false
    # Usage:    $rv = $obj->_parse(@lines);

    my $self      = shift;
    my $conf      = $$self{CONF};
    my $order     = $$self{ORDER};
    my $smart     = $$self{SMART_PARSER};
    my $tagDelim  = $$self{PARAM_DELIM};
    my $hashDelim = $$self{HASH_DELIM};
    my $listDelim = $$self{LIST_DELIM};
    my @lines     = @_;
    my $rv        = 1;
    my ( $i, $line, $comment, $entry, $field, $value );
    my ( $indentation, $data, $saveEntry );

    # Make sure some of the properties are sane
    croak 'LIST_DELIM and HASH_DELIM cannot be the same character sequence!'
        unless $$self{LIST_DELIM} ne $$self{HASH_DELIM};

    subPreamble( PPCDLEVEL1, '$', $self );

    # Flatten lines using an explicit backslash
    for ( $i = 0; $i <= $#lines; $i++ ) {

        # Let's disable uninitialized warnings since there's a few
        # places here we really don't care
        no warnings 'uninitialized';

        if ( $lines[$i] =~ /\\\s*$/sm ) {
            pdebug( 'joining lines %s & %s', PPCDLEVEL2, $i + 1, $i + 2 );

            # Lop off the trailing whitespace and backslash, preserving
            # only one space on the assumption that if it's there it's a
            # natural word break.
            $lines[$i] =~ s/(\s)?\s*\\\s*$/$1/sm;

            # Concatenate the following line (if there is one) after stripping
            # off preceding whitespace
            if ( $i < $#lines ) {
                $lines[ $i + 1 ] =~ s/^\s+//sm;
                $lines[$i] .= $lines[ $i + 1 ];
                splice @lines, $i + 1, 1;
                --$i;
            }
        }
    }

    $saveEntry = sub {

        # Saves the extracted data into the conf hash and resets
        # the vars.

        my ($type);

        ( $field, $value ) =
            ( $entry =~ /^\s*([^$tagDelim]+?)\s*\Q$tagDelim\E\s*(.*)$/sm );
        pdebug( "saving data:\n\t(%s: %s)", PPCDLEVEL2, $field, $value );

        if ( exists $$self{COERCE}{$field} ) {

            # Get the field data type from COERCE
            $type = $$self{COERCE}{$field};

        } else {

            # Otherwise, try to autodetect data type
            $type =
                scalar quotewords( qr/\s*\Q$hashDelim\E\s*/sm, 0, $value ) > 1
                ? 'hash'
                : scalar quotewords( qr/\s*\Q$listDelim\E\s*/sm, 0, $value ) >
                1 ? 'list'
                :   'scalar';
        }
        pdebug( 'detected type of %s is %s', PPCDLEVEL2, $field, $type );

        # For all data types we should strip leading/trailing whitespace.
        # If they really want it they should quote it.
        $value =~ s/^\s+|\s+$//smg unless $type eq 'scalar';

        # We'll apply quotewords to scalar values only if the smart parser is
        # not being used or if we're not coercing all values into scalar for
        # this field.
        #
        # I hate having to do this but I was an idiot in the previous versions
        # and this is necessary for backwards compatibility.
        if ( $type eq 'scalar' ) {
            $value = join '',
                quotewords( qr/\s*\Q$listDelim\E\s*/sm, 0, $value )
                unless $smart
                    && exists $$self{COERCE}{$field}
                    && $$self{COERCE}{$field} eq 'scalar';
        } elsif ( $type eq 'hash' ) {
            $value = {
                quotewords(
                    qr/\s*(?:\Q$hashDelim\E|\Q$listDelim\E)\s*/sm, 0,
                    $value
                    ) };
        } elsif ( $type eq 'list' ) {
            $value = [ quotewords( qr/\s*\Q$listDelim\E\s*/sm, 0, $value ) ];
        }

        # Create the parameter record
        $$conf{$field}              = {};
        $$conf{$field}{Value}       = $value;
        $$conf{$field}{Description} = $comment;
        push @$order, $field unless grep /^\Q$field\E$/sm, @$order;
        $comment = $entry = '';
    };

    # Process lines
    $comment = $entry = '';
    while ( defined( $line = shift @lines ) ) {

        if ( $line =~ /^\s*(?:#.*)?$/sm ) {

            # Grab comments and blank lines
            pdebug( "comment/blank line:\n\t%s", PPCDLEVEL3, $line );

            # First save previous entries if $entry has content
            &$saveEntry() and $i = 0 if length $entry;

            # Save the comments
            $comment = length($comment) > 0 ? "$comment$line\n" : "$line\n";

        } else {

            # Grab configuration lines

            # If this is the first line of a new entry and there's no
            # PARAM_DELIM skip the line -- something must be wrong.
            #
            # TODO:  Error out/raise exception
            unless ( length $entry || $line =~ /\Q$tagDelim\E/sm ) {
                pdebug( "skipping spurious text:\n\t%s", PPCDLEVEL3, $line );
                next;
            }

            # Grab indentation characters and line content
            ( $indentation, $data ) = ( $line =~ /^(\s*)(.+)$/sm );
            pdebug( "data line:\n\t%s", PPCDLEVEL3, $data );

            if ($smart) {

                # Smart parsing is enabled

                if ( length $entry ) {

                    # There's current content

                    if ( length($indentation) > $i ) {

                        # If new indentation is greater than original
                        # indentation we concatenate the lines as a
                        # continuation
                        $entry .= $data;

                    } else {

                        # Otherwise we treat this a a new entry, so we save
                        # the old and store the current
                        &$saveEntry();
                        ( $i, $entry ) = ( length($indentation), $data );
                    }

                } else {

                    # No current content, so just store the current data and
                    # continue processing
                    ( $i, $entry ) = ( length($indentation), $data );
                }

            } else {

                # Smart parsing is disabled, so treat every line as a new
                # entry
                $entry = $data;
                &$saveEntry();
            }
        }
    }
    &$saveEntry() if length $entry;

    subPostamble( PPCDLEVEL1, '$', $rv );

    return $rv;
}

sub _wrap {

    # Purpose:  Parses the passed line of test and inserts indentation and
    #           line breaks as needed
    # Returns:  Formated string
    # Usage:    $out = $obj->_wrap($fIndent, $sIndent, $textWidth,
    #                              $lineBreak, $paragraph);

    my $firstIndent = shift;
    my $subIndent   = shift;
    my $textWidth   = shift;
    my $lineBreak   = shift;
    my $paragraph   = shift;
    my ( @lines, $segment, $output );

    subPreamble( PPCDLEVEL2, '$$$$p', $firstIndent, $subIndent,
        $textWidth, $lineBreak, $paragraph
        );

    # Expand tabs in everything -- sorry everyone
    ($firstIndent) = expand($firstIndent);
    ($subIndent)   = expand($subIndent);
    $paragraph = expand("$firstIndent$paragraph");

    $lines[0] = '';
    while ( length($paragraph) > 0 ) {

        # Get the next string segment (splitting on whitespace)
        ($segment) = ( $paragraph =~ /^(\s*\S+\s?)/sm );

        if ( length $segment <= $textWidth - length $lines[-1] ) {

            # The segment will fit appended to the current line,
            # concatenate it
            $lines[-1] .= $segment;

        } elsif ( length $segment <= $textWidth - length $subIndent ) {

            # The segment will fit into the next line, add it
            $lines[-1] .= $lineBreak;
            push @lines, "$subIndent$segment";

        } else {

            # Else, split on the text width
            $segment =
                $#lines == 0
                ? substr $paragraph, 0, $textWidth
                : substr $paragraph, 0, $textWidth - length $subIndent;
            if ( length $segment > $textWidth - length $lines[-1] ) {
                $lines[-1] .= $lineBreak;
                push @lines,
                    ( $#lines == 0 ? $segment : "$subIndent$segment" );
            } else {
                $lines[-1] .= $segment;
            }
        }
        $paragraph =~ s/^.{@{[length($segment)]}}//sm;
    }
    $lines[-1] .= "\n";

    $output = join '', @lines;

    subPostamble( PPCDLEVEL1, 'p', $output );

    return $output;
}

sub hasParameter {

    # Purpose:  Checks to see if the specified parameter exists as a
    #           configuration parameter
    # Returns:  True or false
    # Usage:    $rv = $obj->hasParameter($name);

    my $self   = shift;
    my $param  = shift;
    my $rv     = 0;
    my @params = ( keys %{ $self->{CONF} }, keys %{ $self->{DEFAULTS} }, );

    croak 'Mandatory first parameter must be a defined parameter name'
        unless defined $param;

    subPreamble( PPCDLEVEL1, '$$', $self, $param );

    $rv = scalar grep /^\Q$param\E$/sm, @params;

    subPostamble( PPCDLEVEL1, '$', $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Parse::PlainConfig::Legacy - Parsing engine Legacy for Parse::PlainConfig

=head1 VERSION

$Id: lib/Parse/PlainConfig/Legacy.pm, 3.06 2023/09/23 19:24:20 acorliss Exp $

=head1 SYNOPSIS

  use Parse::PlainConfig::Legacy;

  $conf = new Parse::PlainConfig::Legacy;
  $conf = Parse::PlainConfig->new(
    'PARAM_DELIM' => '=',
    'FILE'        => '.myrc',
    'MAX_BYTES'   => 65536,
    'SMART_PARSER => 1,
    );

  $conf->property(PARAM_DELIM => '=');

  $rv = $conf->read('myconf.conf');
  $rv = $conf->read;
  $rv = $conf->readIfNewer;
  $conf->write('.myrc', 2);

  $conf->purge;

  @parameters = $conf->parameters;
  $conf->parameter(FOO => "bar");
  $value = $conf->parameter(FOO);
  $conf->describe(FOO => 'This is foo');
  $conf->coerce("string", qw(FOO BAR));

  @order = $conf->order;
  $conf->order(@new_order);

  $errstr = Parse::PlainConfig::Parse::PlainConfig::Legacy::ERROR;

  $rv = $conf->hasParameter('FOO');

=head1 DESCRIPTION

Parse::PlainConfig::Legacy provides OO objects which can parse and generate
human-readable configuration files.

=head1 SUBROUTINES/METHODS

=head2 new

  $conf = new Parse::PlainConfig;
  $conf = Parse::PlainConfig->new(
    'PARAM_DELIM' => '=',
    'FILE'        => '.myrc',
    'MAX_BYTES'   => 65536,
    'SMART_PARSER => 1,
    );

The object constructor can be called with or without arguments.  Arguments
available for use include:

  Argument        Default    Purpose
  =============================================================
  ORDER           []         Specifies specific order of
                             fields to be used while writing
  FILE            undef      Filename for read/write ops
  PARAM_DELIM       ':'        Field/value delimiter
  LIST_DELIM      ','        List delimiter within field values
  HASH_DELIM      '=>'       Hash key/value delimiter within
                             field values
  AUTOPURGE       0          Autopurge enabled/disabled
  COERCE          {}         Field coercion hash
  DEFAULTS        {}         Default field values
  SMART_PARSER    0          Smart parser enabled/disabled
  MAX_BYTES       16384      Integer denoting maximum bytes
                             to read in any given file
  DEFAULTS        {}         Specifies default values for config
                             parameters if not specified/parsed

B<COERCE> is a hash of field name/data type pairs.  If a field is listed in
this hash then their values will always be returned in the requested format of
either string, list, or hash.  Any field coerced to string, for instance, will
ignore list and hash delimiters and assume the entire value will always be
string value.

B<DEFAULTS> is a hash of field name/value pairs.  This ensures that even if a
field is not explicitly set (either in a conf file or programmatically) a
default value can still be retrieved.

B<SMART_PARSER> removes the need to backslash end-of-lines to continue the
value onto the next.  If the following line is indented further than the tag
was it will automatically assume that the next line is a continuation of the
previous.  It also affects the need to encapsulate coerced datatypes with
quotation marks for irrelevant delimiters.

B<AUTOPURGE> erases all stored parameters and values and applies the defaults 
(if any) before reading a file.  This does not, however, erase any values 
set for B<ORDER>.

=head2 property

  $conf->property(PARAM_DELIM => '=');

This method sets or retrieves the specified property.  Please note
that this B<overwrites> the current value, even for those properties that are
references to lists and hashes.

If you're using this to set a property it will return a boolean true or false
depending on the success of the operation.  If you're just retrieving a
property it will return the value of the property.  If you ask for a
nonexistent property it will B<croak>.

B<NOTE:> As of version 2.07 all hashes and lists are copied both in and out of
the object, so any alterations to a referenced structure retrieved will have
no effect on the property within the object.

=head2 purge

  $conf->purge;

This method performs an immediate manual purge.  Auto-purge mode clears the 
configuration hash each time a configuration file is read, so that the internal 
configuration data consists solely of what is in that file.  If you wanted to 
combine the settings of multiple files that each may exclusively hold some 
directives, setting this to 'off' will load the combined configuration as you 
read each file.

You can still clobber configuration values, of course, if the same directive
is defined in multiple files.  In that case, the last file's value will be the
one stored in the hash.

This does not clear the B<order> or B<coerce> properties.

Autopurge mode is disabled by default.

=head2 read

  $rv = $conf->read('myconf.conf');
  $rv = $conf->read;

The read method is called initially with a filename as the only argument.
This causes the parser to read the file and extract all of the configuration
directives from it.

You'll notice that you can also call the read method without an argument.
The name of the file read is stored internally, and if already set to a valid
value (either by a previous call to B<read> with a filename argument or by
setting the B<FILE> property) this will read that file's contents.

The return value will be one if the file was successfully read and parsed, 
or zero otherwise.  The reason for failure can be read via
B<Parse::PlainConfig::Parse::PlainConfig::Legacy::ERROR>.

This function will cause the program to croak if called without a filename 
ever being defined.

=head2 readIfNewer

  $rv = $conf->readIfNewer;

This method is used to reread & parse the file only if the mtime appears
newer than when last read.  If the file was successfully reread or appears to
be the same it will return true.  Any errors will be stored in
B<Parse::PlainConfig::Legacy::ERROR> and it will return a false value.

You can determine whether or not the file was read by the true value.  If it
was re-read it will return 1.  If the file appears to be the same age it will 
return a 2.

=head2 write

  $conf->write('.myrc', 2);

This method writes the current configuration stored in memory to the specified
file, either specified as the first argument, or as stored from an explicit or
implicit B<read> call.

The second argument specifies what kind of whitespace padding, if any, to use
with the directive/value delimiter.  The following values are recognised:

  Value    Meaning
  ================================================
  0        No padding (i.e., written as KEY:VALUE)
  1        Left padding (i.e., written as KEY :VALUE)
  2        Right padding (i.e., written as KEY: VALUE)
  3        Full padding (i.e., written as KEY : VALUE)

Both arguments are optional.

=head2 parameters

  @parameters = $conf->parameters;

This method returns a list of all the names of the directives currently 
stored in the configuration hash in no particular order.

=head2 parameter

  $value = $conf->parameter('SCALAR1');
  @values = $conf->parameter('LIST1');
  %values = $conf->parameter('HASH1');
  $conf->parameter('SCALAR1', "foo");
  $conf->parameter('LIST1', [qw(foo bar)]);
  $conf->parameter('HASH1', { foo => 'bar' });

This method sets or retrieves the specified parameter.  Hash and list values
are copied and returned as a list.  If the specified parameter is set to be
coerced into a specific data type the specified value will be converted to
that datatype.   This means you can do something like:

  # SCALAR1 will equal "foo , bar , roo" assuming LIST_DELIM is set to ','
  $conf->coerce(qw(string SCALAR1));
  $conf->parameter('SCALAR1', [qw(foo bar roo)]);

  # SCALAR1 will equal "foo => bar : roo => ''" assuming HASH_DELIM is set
  # to '=>' and LIST_DELIM is set to ':'
  $conf->parameter('SCALAR1', { 'foo' => 'bar', 'roo' => '' });

In order for conversions to be somewhat predictable (in the case of hashes
coerced into other values) hash key/value pairs will be assigned to string
or list portions according to the alphabetic sort order of the keys.

=head2 coerce

  $conf->coerce("string", "FOO", "BAR");

This method configures the parser to coerce values into the specified
datatype (either string, list, or hash) and immediately convert any existing
values and store them into that datatype as well.

B<NOTE:> Coercing existing values into another data type can provide for some
interesting conversions.  Strings, for instance, are split on the list
delimiter when converting to arrays, and similarly on list and hash delimiters
for hashes.  Going from a hash or list to a string is done in the opposite
manner, elements/key-value pairs are joined with the applicable delimiters and
concatenated into a string.

For this reason one should try to avoid coercing one data type into another if 
you can avoid it.  Instead one should predefine what the data types for each
parameter should be and define that in the COERCE hash passed during object
instantiation, or via this method prior to reading and parsing a file.

=head2 describe

  $conf->describe(KEY1 => 'This is foo', KEY2 => 'This is bar');

The describe method takes any number of key/description pairs which will be
used as comments preceding the directives in any newly written conf file.  You
are responsible for prepending a comment character to each line, as well as
splitting along your desired text width.

=head2 order

  @order = $conf->order;
  $conf->order(@new_order);

This method returns the current order of the configuration directives as read 
from the file.   If called with a list as an argument, it will set the
directive order with that list.  This method is probably of limited use except 
when you wish to control the order in which directives are written in new conf 
files.

Please note that if there are more directives than are present in this list, 
those extra keys will still be included in the new file, but will appear in
alphabetically sorted order at the end, after all of the keys present in the
list.

=head2 hasParameter

  $rv = $conf->hasParameter('FOO');

This function allows you to see if a parameter has been defined or has a
default set for it.  Returns a boolean value.

=head1 DEPRECATED METHODS

=head2 delim

  $conf->delim('=');

This method gets and/or sets the parameter name/value delimiter to be used in the 
conf files.  The default delimiter is ':'.  This can be multiple characters.

=head2 directives

  @directives = $conf->directives;

This method returns a list of all the names of the directives currently 
stored in the configuration hash in no particular order.

=head2 get

  $field = $conf->get('KEY1');
  ($field1, $field2) = $conf->get(qw(KEY1 KEY2));

The get method takes any number of directives to retrieve, and returns them.  
Please note that both hash and list values are passed by reference.  In order 
to protect the internal state information, the contents of either reference is
merely a copy of what is in the configuration object's hash.  This will B<not>
pass you a reference to data stored internally in the object.  Because of
this, it's perfectly safe for you to shift off values from a list as you
process it, and so on.

=head2 set

  $conf->set(KEY1 => 'foo', KEY2 => 'bar');

The set method takes any number of directive/value pairs and copies them into 
the internal configuration hash.

=head2 get_ref

  $href = $conf->get_ref

B<Note>:  This used to give you a reference to the internal configuration hash
so you could manipulate it directly.  It now only gives you a B<copy> of the
internal hash (actually, it's reconstructed has to make it look like the old
data structure).  In short, any changes you make to this hash B<will be lost>.

=head2 error

  warn $conf->error;

This method returns a zero-length string if no errors were registered with the
last operation, or a text message describing the error.

=head2 ERROR

  $error = Parse::PlainConfig::ERROR();

Lvalue subroutine storing the last error which may have occurred.

=head1 DEPENDENCIES

=over

=item o

L<Paranoid>

=item o

L<Text::ParseWords>

=item o

L<Text::Tabs>

=back

=head1 FILE SYNTAX

=head2 TRADITIONAL USAGE

The plain parser supports the reconstructions of relatively simple data
structures.  Simple string assignments and one-dimensional arrays and hashes
are possible.  Below are are various examples of constructs:

  # Scalar assignment
  FIRST_NAME: Joe
  LAST_NAME: Blow

  # Array assignment
  FAVOURITE_COLOURS: red, yellow, green
  ACCOUNT_NUMBERS:  9956-234-9943211, \
                    2343232-421231445, \
                    004422-03430-0343
  
  # Hash assignment
  CARS:  crown_vic => 1982, \
         geo       => 1993

As the example above demonstrates, all lines that begin with a '#' (leading
whitespace is allowed) are ignored as comments.  if '#" occurs in any other
position, it is accepted as part of the passed value.  This means that you
B<cannot> place comments on the same lines as values.

All directives and associated values will have both leading and trailing 
whitespace stripped from them before being stored in the configuration hash.  
Whitespace is allowed within both.

In traditional mode (meaning no parameters are set to be coerced into a
specific datatype) one must encapsulate list and hash delimiters with
quotation marks in order to prevent the string from being split and stored as
a list or hash.  Quotation marks that are a literal part of the string must be
backslashed.

=head2 SMART PARSER

The new parser now provides some options to make the file syntax more
convenient.  You can activate the smart parser by setting B<SMART_PARSER> to a
true value during object instantiation or via the B<property> method.

With the traditional parser you had to backslach the end of all preceding
lines if you wanted to split a value into more than one line:

  FOO:  This line starts here \
        and ends here...

With the smart parser enabled that is no longer necessary as long as the
following lines are indented further than the first line:

  FOO:  This line starts here
        and ends here...

B<Note:>  The indentation is compared by byte count with no recognition of
tab stops.  That means if you indent with spaces on the first line and indent
with tabs on the following it may not concantenate those values.

Another benefit of the smart parser is found when you specify a parameter to
be of a specific datatype via the B<COERCE> hash during object instantiation
or the B<coerce> method.  For instance, the traditional parser requires you to
encapsulate strings with quotation marks if they contain list or hash
delimiters:

  Quote:  "\"It can't be that easy,\" he said."

Also note how you had to escape quotation marks if they were to be a literal
part of the string.  With this parameter set to be coerced to a scalar you can
simply write:

  Quote:  "It can't be that easy," he said.

Similarly, you don't have to quote hash delimiters in parameters set to be
coerced into lists.  Quotation marks as part of an element value must be
escaped, though, since unescaped quotation marks are assumed to encapsulate
strings containing list delimiters you don't want to split on.

B<Note:> The previous versions of Parse::PlainConfig did not allow the user to
set keys like:

  FOO: \
      bar

or save empty assignments like

  FOO:

This is no longer the case.  Both are now valid and honoured.

=head1 SECURITY

B<WARNING:> This parser will attempt to open what ever you pass to it for a
filename as is.  If this object is to be used in programs that run with
permissions other than the calling user, make sure you sanitize any
user-supplied filename strings before passing them to this object.

This also uses a blocking b<flock> call to open the file for reading and
writing.

=head1 DIAGNOSTICS 

Through the use of B<Paranoid::Debug> this module will produce internal
diagnostic output to STDERR.  It begins logging at log level 7.  To enable
debugging output please see the pod for L<Paranoid::Debug>.

=head1 BUGS AND LIMITATIONS 

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2002 - 2023, Arthur Corliss (corliss@digitalmages.com)

