# Parse::PlainConfig -- Parsing Engine for Parse::PlainConfig
#
# (c) 2002 - 2023, Arthur Corliss <corliss@digitalmages.com>,
#
# $Id: lib/Parse/PlainConfig.pm, 3.06 2023/09/23 19:24:20 acorliss Exp $
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

package Parse::PlainConfig;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);

($VERSION) = ( q$Revision: 3.06 $ =~ /(\d+(?:\.(\d+))+)/sm );

use Class::EHierarchy qw(:all);
use Parse::PlainConfig::Constants qw(:all);
use Parse::PlainConfig::Settings;
use Text::ParseWords;
use Text::Tabs;
use Fcntl qw(:seek :DEFAULT);
use Paranoid;
use Paranoid::Debug;
use Paranoid::IO;
use Paranoid::IO::Line;
use Paranoid::Input qw(:all);
use Paranoid::Glob;

use base qw(Class::EHierarchy);

use vars qw(@_properties @_methods %_parameters %_prototypes);

#####################################################################
#
# Module code follows
#
#####################################################################

sub _findAllClasses {

    # Purpose:  Returns a list of all parent class names
    # Returns:  Array of scalars
    # Usage:    @pclasses = _findAllClasses(ref $obj);

    my $class = shift;
    my ( @classes, %c, $c, @rv );

    subPreamble( PPCDLEVEL3, '$', $class );

    # Pull all parent class and recursively loop
    {
        no strict 'refs';

        if ( defined *{"${class}::ISA"}{ARRAY} ) {

            foreach $c ( @{ *{"${class}::ISA"}{ARRAY} } ) {
                push @classes, _findAllClasses($c);
            }

            push @classes, $class
                if scalar @classes
                    or grep { $_ eq __PACKAGE__ }
                    @{ *{"${class}::ISA"}{ARRAY} };
        }
    }

    # Consolidate redundant entries
    foreach $c (@classes) {
        push @rv, $c unless exists $c{$c};
        $c{$c} = 1;
    }

    subPostamble( PPCDLEVEL3, '@', @rv );

    return @rv;
}

sub _initialize {

    # Purpose:  Initialize config object and loads class defaults
    # Returns:  Boolean
    # Usage:    $rv = $obj->_initialize(@args);

    my $obj   = shift;
    my $class = ref $obj;
    my $rv    = 1;
    my ( @classes, $settings, %new, %_globals, %_parameters, %_prototypes );

    subPreamble( PPCDLEVEL1, '$$', $obj, $class );

    # Create & adopt the settings object
    $settings = new Parse::PlainConfig::Settings;
    $obj->adopt($settings);
    $settings->alias('settings');

    # Get a list of all parent classes
    @classes = ( _findAllClasses($class) );

    # Read in class global settings
    unless ( __PACKAGE__ eq $class ) {

        foreach $class (@classes) {
            if ( defined *{"${class}::_globals"} ) {
                pdebug( 'loading globals from %s', PPCDLEVEL2, $class );

                {
                    no strict 'refs';

                    %new = %{ *{"${class}::_globals"}{HASH} };
                }

                if ( scalar keys %new ) {
                    foreach ( keys %new ) {
                        $_globals{$_} = $new{$_};
                        pdebug( 'overriding %s with (%s)',
                            PPCDLEVEL3, $_, $_globals{$_} );
                        $rv = 0 unless $settings->set( $_, $_globals{$_} );
                    }
                }
            }
        }

        foreach $class (@classes) {
            if ( defined *{"${class}::_parameters"} ) {
                pdebug( 'loading parameters from %s', PPCDLEVEL2, $class );

                {
                    no strict 'refs';

                    %new = %{ *{"${class}::_parameters"}{HASH} };
                }

                if ( scalar keys %new ) {
                    %_parameters = ( %_parameters, %new );
                    $settings->set( 'property types', %_parameters );
                    foreach ( keys %new ) {

                        pdebug( 'creating property %s', PPCDLEVEL3, $_ );
                        unless (
                            _declProperty(
                                $obj, $_,
                                CEH_PUB | (
                                    $_parameters{$_} == PPC_HDOC
                                    ? PPC_SCALAR
                                    : $_parameters{$_}
                                    ),
                            )
                            ) {
                            $rv = 0;
                            last;
                        }

                        # merge property regex
                        $settings->merge(
                            'property regexes',
                            $_,
                            qr#(\s*)(\Q$_\E)\s*\Q@{[ $settings->delimiter ]}\E\s*(.*)#s
                            );
                    }
                }
            }

            if ( defined *{"${class}::_prototypes"} ) {
                pdebug( 'loading prototypes from %s', PPCDLEVEL2, $class );

                {
                    no strict 'refs';

                    %new = %{ *{"${class}::_prototypes"}{HASH} };
                }

                if ( scalar keys %new ) {
                    %_prototypes = ( %_prototypes, %new );
                    $settings->set( 'prototypes', %_prototypes );
                    foreach ( keys %new ) {

                        # merge property meta-data
                        $settings->merge(
                            'prototype regexes',
                            $_,
                            qr#(\s*)(\Q$_\E)\s+(\S+)\s*\Q@{[ $settings->delimiter ]}\E\s*(.*)#s
                            );
                    }
                }
            }
        }
    }

    # Store all parent classes
    $settings->set( '_ppcClasses', @classes );

    # Load the defaults
    $rv = $obj->parse( $obj->default );

    subPostamble( PPCDLEVEL1, '$', $rv );

    return $rv;
}

sub settings {

    # Purpose:  Returns object reference to the settings object
    # Returns:  Object reference
    # Usage:    $settings = $obj->settings;

    my $obj = shift;

    return $obj->getByAlias('settings');
}

sub _default {

    # Purpose:  Returns the DATA block from the calling
    # Returns:  Array
    # Usage:    @lines = $obj->_default;

    my $obj   = shift;
    my $class = shift;
    my ( $fn, @chunk, @lines );

    subPreamble( PPCDLEVEL2, '$', $obj );

    $class =~ s#::#/#sg;
    $class .= '.pm';
    $fn = $INC{$class};

    pdebug( 'attempting to read from %s', PPCDLEVEL3, $fn );
    if ( popen( $fn, O_RDONLY ) ) {

        # Read in file
        while ( sip( $fn, @chunk ) and @chunk ) { push @lines, @chunk }

        # empty all lines prior to __DATA__
        while ( @lines and $lines[0] !~ /^\s*__DATA__\s*$/s ) {
            shift @lines;
        }
        shift @lines;

        # empty all lines after __END__
        if ( @lines and grep /^\s*__END__\s*$/s, @lines ) {
            while ( @lines and $lines[-1] !~ /^\s*__END__\s*$/s ) {
                pop @lines;
            }
            pop @lines;
        }
        pseek( $fn, 0, SEEK_SET );
    }

    subPostamble( PPCDLEVEL2, '@', @lines );

    return wantarray ? @lines : join '', @lines;
}

sub default {

    # Purpose:  Returns the DATA block from the specified class,
    #           or the object class if not specified
    # Returns:  Array
    # Usage:    @lines = $obj->default;
    # Usage:    @lines = $obj->default($class);

    my $obj     = shift;
    my @classes = $obj->getByAlias('settings')->get('_ppcClasses');
    my ( $class, @rv );

    subPreamble( PPCDLEVEL1, '$', $obj );

    foreach $class (@classes) {
        push @rv, $obj->_default($class);
    }

    subPostamble( PPCDLEVEL1, '@', @rv );

    return @rv;
}

sub get {

    # Purpose:  Returns the value of the specified parameter
    # Returns:  Scalar/List/Hash
    # Usage:    $val = $obj->get('foo');

    my $obj = shift;
    my $p   = shift;
    my $valp;

    subPreamble( PPCDLEVEL1, '$$', $obj, $p );

    if ( defined $p ) {
        $valp = scalar grep /^\Q$p\E$/s, $obj->properties;
    }
    $obj->error(
        pdebug( 'specified invalid parameter name: %s', PPCDLEVEL1, $p ) )
        unless $valp;

    subPostamble( PPCDLEVEL1, '' );

    return $valp ? $obj->SUPER::get($p) : undef;
}

sub set {

    # Purpose:  Assigns the desired values to the specified parameter
    # Returns:  Boolean
    # Usage:    $rv = $obj->set($prop, @values);

    my $obj       = shift;
    my $p         = shift;
    my @vals      = @_;
    my %propTypes = $obj->settings->propertyTypes;
    my ( $valp, $rv );

    subPreamble( PPCDLEVEL1, '$$@', $obj, $p, @vals );

    if ( defined $p ) {
        $valp = scalar grep /^\Q$p\E$/s, $obj->properties;
    }
    $obj->error(
        pdebug( 'specified invalid parameter name: %s', PPCDLEVEL1, $p ) )
        unless $valp;

    if ($valp) {
        if (@vals) {

            # Set whatever's assigned
            $rv = $obj->SUPER::set( $p, @vals );
        } else {

            # Assume that no values means empty/undef
            if (   $propTypes{$p} == PPC_SCALAR
                or $propTypes{$p} == PPC_HDOC ) {
                $rv = $obj->SUPER::set( $p, undef );
            } else {
                $rv = $obj->empty($p);
            }
        }
    }

    subPostamble( PPCDLEVEL1, '$', $valp ? $rv : undef );

    return $valp ? $rv : undef;
}

sub _snarfBlock (\@\$\$$) {

    # Purpose:  Finds and returns the block with the value
    #           string extracted.
    # Returns:  Boolean
    # Usage:    $rv = _snarfBlock(@lines, $val);

    my $lref       = shift;
    my $pref       = shift;
    my $vref       = shift;
    my $settings   = shift;
    my $obj        = $settings->parent;
    my %regex      = $settings->propertyRegexes;
    my %pregex     = $settings->prototypeRegexes;
    my %propTypes  = $settings->propertyTypes;
    my %prototypes = $settings->prototypes;
    my $subi       = $settings->subindentation;
    my ( $rv, $indent, $prop, $proto, $trailer, $iwidth, $line, $preg );

    subPreamble( PPCDLEVEL2, '$$$$', $lref, $pref, $vref, $settings );

    # Match line to a property/prototype declaration
    #
    # First try to match against properties
    foreach ( keys %regex ) {
        if ( $$lref[0] =~ /^$regex{$_}$/s ) {
            ( $indent, $prop, $trailer ) = ( $1, $2, $3 );
            $rv = 1;
            shift @$lref;
            last;
        }
    }
    unless ( $rv and defined $prop and length $prop ) {
        foreach ( keys %pregex ) {
            if ( $$lref[0] =~ /^$pregex{$_}$/s ) {
                ( $indent, $proto, $prop, $trailer ) = ( $1, $2, $3, $4 );
                $rv = 1;
                shift @$lref;
                last;
            }
        }
    }

    # Define all prototyped properties
    if ( defined $proto and length $proto ) {
        if ( defined $prop and length $prop ) {

            if ( exists $regex{$prop} ) {
                $obj->error(
                    pdebug(
                        'token (%s) for prototype (%s) attempted to override property',
                        PPCDLEVEL1,
                        $prop,
                        $proto
                        ) );
                $rv = 0;
            } else {

                if ( exists $propTypes{$prop} ) {

                    # Make sure they haven't been previously defined,
                    # or if they have, they match the same type
                    unless ( $propTypes{$prop} == $prototypes{$proto} ) {
                        $rv = 0;
                        $obj->error(
                            pdebug(
                                'prototype mismatch with previous declaration: %s',
                                PPCDLEVEL1,
                                $proto
                                ) );
                        pdebug( 'current type: %s prototype: %s',
                            PPCDLEVEL1, $propTypes{$prop},
                            $prototypes{$proto} );
                    }
                } else {

                    # Create a new property
                    pdebug( 'creating property based on prototype %s: %s',
                        PPCDLEVEL3, $proto, $prop );

                    $rv = _declProperty(
                        $obj, $prop,
                        CEH_PUB | (
                            $prototypes{$proto} == PPC_HDOC
                            ? PPC_SCALAR
                            : $prototypes{$proto}
                            ),
                            );

                    # Record the prop type
                    if ($rv) {
                        $settings->merge( 'property types',
                            $prop, $propTypes{$prop} = $prototypes{$proto} );
                        ($preg) =
                            $settings->subset( 'prototype registry', $proto );
                        $preg = [] unless defined $preg;
                        push @$preg, $prop;
                        $settings->merge( 'prototype registry',
                            $proto => $preg );
                    } else {
                        $obj->error(
                            pdebug(
                                'failed to declare prototype: %s %s',
                                PPCDLEVEL1, $proto, $prop
                                ) );
                    }
                }
            }
        } else {
            $obj->error(
                pdebug(
                    'invalid token used for prototype %s: %s', PPCDLEVEL1,
                    $proto,                                    $prop
                    ) );
            $rv = 0;
        }
    }

    # Grab additional lines as needed
    if ($rv) {

        if ( $propTypes{$prop} == PPC_HDOC ) {

            # Snarf all lines until we hit the HDOC marker
            $rv = 0;
            while (@$lref) {
                $line = shift @$lref;
                if ( $line =~ /^\s*\Q@{[ $settings->hereDoc ]}\E\s*$/s ) {
                    $rv = 1;
                    last;
                } else {
                    $line =~ s/^\s{1,$subi}//s;
                    $trailer .= $line;
                }
            }

            # Error out if we never found the marker
            $obj->error(
                pdebug( 'failed to find the here doc marker', PPCDLEVEL1 ) )
                unless $rv;

        } else {

            # All non-HDOCs are handled the same
            $iwidth = defined $indent ? length $indent : 0;
            while (@$lref) {

                # We're done if this is a line break
                last if $$lref[0] =~ /^\s*$/s;

                # We're also done if indentation isn't greater
                # than the parameter declaration line
                ($indent) = ( $$lref[0] =~ /^(\s*)/s );
                last if !defined $indent or $iwidth >= length $indent;

                # Append content to the trailer
                $line = shift @$lref;
                $line =~ s/^\s{1,$subi}//s;
                pchomp($line);
                $trailer .= $line;
            }
        }
        $trailer =~ s/\s+$//s if defined $trailer;
    }

    if ($rv) {
        pchomp($trailer);
        ( $$pref, $$vref ) = ( $prop, $trailer );
        pdebug( 'extracted value for %s: %s', PPCDLEVEL3, $prop, $trailer );
    }

    subPostamble( PPCDLEVEL2, '$', $rv );

    return $rv;
}

sub _snarfProp {

    # Purpose:  Takes the property value and parses according to its type,
    #           then merges it
    # Returns:  Boolean
    # Usage:    $rv = _snarfProp($obj, $prop, $val);

    my $obj       = shift;
    my $prop      = shift;
    my $val       = shift;
    my $settings  = $obj->settings;
    my %propTypes = $settings->propertyTypes;
    my $ldelim    = $settings->listDelimiter;
    my $hdelim    = $settings->hashDelimiter;
    my $rv        = 1;
    my @elements;

    subPreamble( PPCDLEVEL2, '$$$', $obj, $prop, $val );

    if (   $propTypes{$prop} == PPC_HDOC
        or $propTypes{$prop} == PPC_SCALAR ) {

        # Here Docs and scalars are merged as-is
        $obj->SUPER::set( $prop, $val );

    } else {

        if ( $propTypes{$prop} == PPC_ARRAY ) {

            # Split into a list
            @elements = quotewords( qr/\Q$ldelim\E/s, 0, $val );
            foreach (@elements) { s/^\s+//s; s/\s+$//s; }

        } else {

            # Split into a hash
            @elements =
                quotewords( qr/(?:\Q$ldelim\E|\Q$hdelim\E)/s, 0, $val );
            foreach (@elements) { s/^\s+//s; s/\s+$//s; }

        }

        # merge the list value
        pdebug( 'storing in %s: %s', PPCDLEVEL3, $prop, @elements );
        $obj->empty($prop);
        $obj->SUPER::set( $prop, @elements );
    }

    subPostamble( PPCDLEVEL2, '$', $rv );

    return $rv;
}

sub parse {

    # Purpose:  Parses passed content and extracts values
    # Returns:  Boolean
    # Usage:    $rv = $obj->parse(@lines);

    my $obj      = shift;
    my @lines    = @_;
    my $settings = $obj->settings;
    my $delim    = $settings->delimiter;
    my $cre      = qr#^\s*\Q@{[ $settings->comment ]}\E#s;
    my $rv       = 1;
    my ( $text, $prop, $value, $glob );

    subPreamble( PPCDLEVEL1, '$@', $obj, @lines );

    # Some preprocessing of lines
    if (@lines) {
        $tabstop = $settings->tabStop;
        @lines   = expand(@lines);
        foreach (@lines) {
            $text =
                ( defined $text and length $text )
                ? join "\n", $text, split NEWLINE_REGEX, $_
                : join "\n", split NEWLINE_REGEX, $_;
        }
    }

    while (@lines) {

        # Skip comments and empty lines
        if (   $lines[0] =~ /^$cre/s
            or $lines[0] =~ /^\s*(?:@{[ NEWLINE_REGEX ]})?$/s ) {
            shift @lines;
            next;
        }

        # Handle "include" statements
        if ( $lines[0] =~ /^\s*include\s+(.+?)\s*$/s ) {
            $glob = new Paranoid::Glob globs => [$1];
            shift @lines;
            $rv = 0 unless $obj->read($glob);
            next;
        }

        # See if we have property block
        if ( _snarfBlock( @lines, $prop, $value, $settings ) ) {

            # Parse the block (but preserve earlier errors)
            $rv = 0 unless _snarfProp( $obj, $prop, $value );

        } else {

            pdebug( 'discarding invalid input: %s', PPCDLEVEL1, $lines[0] );
            shift @lines;
            $rv = 0;
        }
    }

    subPostamble( PPCDLEVEL1, '$', $rv );

    return $rv;
}

sub read {

    # Purpose:  Reads the passed file(s)
    # Returns:  Boolean
    # Usage:    $rv = $obj->read($filename);

    my $obj    = shift;
    my $source = shift;
    my ( $rv, @lines );

    subPreamble( PPCDLEVEL1, '$$', $obj, $source );

    if (@_) {

        # Work all entries passed if handed a list
        $rv = $obj->read($source);
        foreach (@_) { $rv = 0 unless $obj->read($_) }

    } elsif ( ref $source eq '' ) {

        # Treat all non-reference files as filenames
        if ( slurp( $source, @lines ) ) {
            $rv = $obj->parse(@lines);
            pdebug( 'errors parsing %s', PPCDLEVEL1, $source ) unless $rv;
        } else {
            $obj->error(
                pdebug(
                    'failed to read %s: %s', PPCDLEVEL1,
                    $source,                 Paranoid::ERROR() ) );
        }

    } elsif ( ref $source eq 'Paranoid::Glob' ) {

        # Handle Paranoid globs specially
        $rv = 1;
        foreach (@$source) { $rv = 0 unless $obj->read($_) }

    } else {

        # Handle everything else as if it was a glob
        if ( slurp( $source, @lines ) ) {
            $rv = $obj->parse(@lines);
            pdebug( 'errors parsing %s', PPCDLEVEL1, $source ) unless $rv;
        } else {
            $obj->error(
                pdebug(
                    'failed to read %s: %s', PPCDLEVEL1,
                    $source,                 Paranoid::ERROR() ) );
        }
    }

    subPostamble( PPCDLEVEL1, '$', $rv );

    return $rv;
}

sub reset {

    # Purpose:  Resets configuration state to defaults
    # Returns:  Boolean
    # Usage:    $rv = $obj->reset;

    my $obj       = shift;
    my $settings  = $obj->settings;
    my %propTypes = $settings->propertyTypes;
    my $rv;

    subPreamble( PPCDLEVEL1, '$', $obj );

    # empty all property values
    foreach ( keys %propTypes ) {
        pdebug( 'clearing merged values for %s', PPCDLEVEL2, $_ );
        if ( $propTypes{$_} == PPC_SCALAR or $propTypes{$_} == PPC_HDOC ) {
            $obj->SUPER::set( $_, undef );
        } else {
            $obj->empty($_);
        }
    }
    $rv = $obj->parse( $obj->default );

    subPostamble( PPCDLEVEL1, '$', $rv );

    return $rv;
}

sub prototyped {

    # Purpose:  Returns a list of properties that were created with
    #           prototypes
    # Returns:  Array
    # Usage:    @protos = $obj->prototyped;
    # Usage:    @protos = $obj->prototyped($proto);

    my $obj   = shift;
    my $proto = shift;
    my ( %preg, @prval );

    subPreamble( PPCDLEVEL1, '$$', $obj, $proto );

    %preg = $obj->settings->get('prototype registry');

    if ( defined $proto and length $proto ) {
        if ( exists $preg{$proto} ) {
            @prval = @{ $preg{$proto} };
        } else {
            pdebug( 'no prototype properties declared w/%s',
                PPCDLEVEL2, $proto );
        }
    } else {
        pdebug( 'dumping all declared prototyped properties', PPCDLEVEL2 );
        foreach ( keys %preg ) { push @prval, @{ $preg{$_} } }
    }

    subPostamble( PPCDLEVEL1, '@', @prval );

    return @prval;
}

sub error {

    # Purpose:  Sets/gets the last error message
    # Returns:  Scalar/undef
    # Usage:    $errStr = $obj->error;
    # Usage:    $errStr = $obj->error($msg);

    my $obj = shift;
    my $msg = shift;

    if ( defined $msg ) {
        $obj->settings->set( 'error', $msg );
    } else {
        $msg = $obj->settings->get('error');
    }

    return $msg;
}

1;

__END__

=head1 NAME

Parse::PlainConfig - Configuration file class

=head1 VERSION

$Id: lib/Parse/PlainConfig.pm, 3.06 2023/09/23 19:24:20 acorliss Exp $

=head1 SYNOPSIS

=head2 SAMPLE CONFIG CLASS

  package MyConfig;

  use Parse::PlainConfig;
  use Parse::PlainConfig::Constants;
  use base qw(Parse::PlainConfig);
  use vars qw(%_globals %_parameters %_prototypes);

  %_globals = (
        'comment'        => '#',
        'delimiter'      => ':',
        'list delimiter' => ',',
        'hash delimiter' => '=>',
        'subindentation' => 4,
        'here doc'       => 'EOF',
      );
  %_parameters = (
      'daemon ports'    => PPC_ARRAY,
      'banner'          => PPC_HDOC,
      'user'            => PPC_SCALAR,
      'group'           => PPC_SCALAR,
      'database'        => PPC_HASH,
      'acls'            => PPC_HASH,
      );
  %_prototypes = (
      'define net'      => PPC_ARRAY,
      );

  1;

  __DATA__

  # This is the default configuration for MyConfig.
  # Newly created objects based on this class will 
  # inherit the below configuration as default values.
  #
  # daemon ports:  list of ports to listen on
  daemon ports:  8888, 9010

  # banner:  default banner to display on each connection
  banner: 
      ********  WARNING  ********
         You are being watched
      ********  WARNING  ********  
  EOF

  user: nobody
  group: nogroup
  database:
      host => localhost,
      db   => mydb,
      user => dbuser,
      pass => dbpass

  define net loopback: 127.0.0.1/8, ::1/128
  define net localnet: 192.168.0.0/24, 192.168.35.0/24
  define net nonlocal:  ! 192.168.0.0/16

  acls:  loopback => allow, localnet => allow, nonlocal => deny

  __END__

  =head1 NAME

  normal pod text can be put here...

=head2 SAMPLE OBJECT USAGE

  $config = new MyConfig;

  print "default user: ", $config->get('user'), "\n";
  print "default group: ", $config->get('group'), "\n";

  # Override value
  $config->set('user', 'root');

  # Get config from a file
  $rv = $config->read($filename);

  # Parse config from in-memory text
  $rv = $config->parse(@lines);

  # Prototyps are accessed like parameters
  @localnets = $config->get('localnet');

  # Reset config values back to class defaults
  $config->reset;

  # Print default config file
  print $config->default;

=head1 DESCRIPTION

B<Parse::PlainConfig> provides a simple way to write a config object class
that supports all the basic primitive data types (scalar, array, and hashes)
while allowing for arbitrary delimiters, comment characters, and more.

The use of a B<__DATA__> block to merge your default config not only provides 
for a reference config but a convenient way to set default values for 
parameters and prototypes.  Use of B<__END__> also allows you to append your
standard POD text to allow for the creation of man pages documenting your
configuration options.

The parser supports the use of "include {filename|glob}" syntax for splitting
configuration parameters amongst multiple config files.  Even without it every
call to L<read> or L<parse> only applies new settings on top of the existing
set, allowing you to aggregate multiple config file parameters into one set of
parameters.

Unlike previous versions of this module B<Parse::PlainConfig> is strictly a
parser, not a generator.  That functionality never seem to be used enough to
be worth maintaining with this upgrade.  For backwards compatibility the old
Parser/Generator is still included under the new namespace
L<Parse::PlainConfig::Legacy>.  Updating legacy scripts to use that package
name instead should keep everything working.

B<Parse::PlainConfig> is a subclass of L<Class::EHierarchy>, and all
parameters are public properties allowing access to the full set of data-aware
methods provided by that module (such as B<merge>, B<empty>, B<pop>, B<shift>,
and others).

I/O is also done in a platform-agnostic manner, allowing parsed values to read
reliably on any platform regardless of line termination style used to author
the config file.

=head1 SUBCLASSING

All parsing objects are now subclasses of L<Parse::PlainConfig> tuned for a
specific style and a known list of parameters and/or prototypes.  This makes
coding for config file parsing extremely simple and convenient.

Control of the parser is performed by setting values in three class hashes:

=head2 %_globals

The B<%_globals> hash is primarily used to specify special character sequences
the parser will key to identify comments and the various parameters and data
types.  The following key/value are supported:

    Key             Default   Description
    ---------------------------------------------------------------
    comment         #         Character(s) used to denote comments
    delimiter       :         Parameter/value delimiter
    list delimiter  ,         Ordinal array values delimiter
    hash delimiter  =>        Hash values' key/value pair delimiter
    subindentation  4         Default level of indentation to 
                              expect for line continuations
    here doc        EOF       Token used for terminating here doc
                              parameter values

If all of the defaults are acceptable this hash can be omitted entirely.

Note that the I<subindentation> is merely advisory, any additional level of
subindentation on line continuations will work.  What this does, however, is
trim up to that amount of preceding white space on each line within a
here-doc.  This allows one to indent blocks of text to maintain the visual
flow of the config file, while still allowing the editor the use of all
columns in the display.

=head2 %_parameters

The B<%_parameters> hash is used to list all of the formal parameters
recognized by this config object.  All parameters must be one of four data
types:

    Type        Description
    ----------------------------------------------------------------
    PPC_SCALAR  Simple strings
    PPC_ARRAY   Arrays/lists
    PPC_HASH    Hashes/Associative arrays
    PPC_HDOC    Essentially a PPC_SCALAR that preserves formatting

All but B<PPC_HDOC> will trim leading/trailing white space and collapse all
lines into a single line for parsing.  That means that no string, ordinal
value, key, or associative value can have embedded line breaks.  You can,
however, have delimiter characters as part of any values as long as they are
encapusated in quoted text or escaped.

B<PPC_HDOC> will preserve line breaks, but will trim leading white space on
each line up to the value given to B<$_globals{subindentation}>.

=head2 %_prototypes

B<%_prototypes> exist to allow for user-defined parameters that fall outside
of the formal parameters in B<%_parameters>.  ACLs, for instance, are often
of indeterminate number and naming, which is a perfect use-case for
prototypes.

Like parameters prototypes are assigned a data type.  Unlike parameters
prototypes are assigned types based on a declarative preamble since the the
name (or token) is not known in advance.

To continue with the ACL example we could define a prototype like so:

    %_prototypes = ( 'define acl' => PPC_ARRAY );

The config editor could then define any number of ACLs:

    define acl loopback 127.0.0.1/8
    define acl localnet 192.168.0.0/24,192.168.1.0/24

Once parsed those ACL parameters can then be accessed simply by their unique
token:

    @localnets = $config->get('localnet');

=head2 NOTES ON SUBCLASSING

The above section provided the rudimentaries of subclassing
L<Parse::PlainConfig>, but this module also subclassing your config modules as
well, including multiple inheritance.  This can allow you to have a single
config that can consolidate multiple configurations in a single file.  There's
only a few rules to observe:

=over

=item * All configs must use the same global parsing parameters

=item * Each property and prototype should use be declared in one specific class
to avoid conflicts with data types and potential defaults in the DATA block

=item * Defaults from each class will be applied from the top down, and left to 
right.  This means that the top level parent class'es data block will be
parsed first, then each subsequent child class, and the final subclass, last.

=back

=head1 CONFIG FILE FORMAT RULES

This module is intended to provide support for parsing human-readable config
files, while supporting basic data structures and delimiter flexibility.  That
said, there are a few basic rules by which the parser operates.

Note that the use B<__DATA__> and/or B<__END__> blocks are entirely optional.

=head2 DELIMITERS

Delimiters must be unique.  You cannot use the same character(s) for
both list delimiters and hash key/value pair delimiters, for instance.  That
said, the parser is very forgiving on the use of whitespace around all
delimiters, even if one of your delimiters is literally a space.

Hash and array delimiters can be embedded in elements as long as they're
quoted or escaped appropriately.  Those elements are split using
L<Text::ParseWords>' L<quotewords> function.

=head2 LINE CONTINUATIONS

Parameters values may need to be, by necessity, longer than a single line.
This is fully supported for all data types.  All that is needed that the line
continuations be at least one space more indented than the preceding line.
Empty lines are considered to be line breaks which terminate the parameter
value.  Likewise, a line that is indented equal or less than the parameter 
declaration line implies a new block of content.

There is one exception to that rule:  here docs.  If you need to preserve
formatting, which can include line breaks, the use of here docs will suck in
everything up to the next here doc EOF token.  The entire here doc, however,
is treated as scalar value for purposes of parameter storage.

=head2 COMMENTS

Comments can be any sequence of characters, but must be on a line by
themselves.  Preceding white space is allowed.

=head2 PARAMETER NAMES

Given that parameters are actually formal object properties it could go 
without saying that each parameter must be uniquely named.  Parameters 
names can include white space or other miscellaneous punctuation.

=head2 PROTOTYPES

Prototypes allow for the dynamic creation of parameters.  There are a few
caveats in their usage, however.  Prototypes are specified through a unique
preamble followed by a unique token.  Unlike parameter names this token
cannot have embedded white space.  But like parameters they are specified by
that unique token (minus the preamble) during L<get> and L<set> operations.

Since these dynamic properties are also formal properties the token must not 
be in use as a formal property.  In other words, all prototype tokens and 
parameter names must be unique as a set.

Parsing errors will be generated if the token occurs as a formal parameter.
It will also be generated if you attempt to redfine a token as a different
type of data structure.

=head1 SUBROUTINES/METHODS

=head2 new

  $conf = new MyConfig;

This creates a new config object based on the specified config class,
initialized with the defaults merged in B<__DATA__>.  No additional arguments
are supported.  This will fail if the default config is invalid in any way.

=head2 settings

  $settings = $config->settings;

This provides a reference to the engine settings object from which you can
interrogate various settings such as delimiters, etc.  The full set of methods
supported by the settings object is documented in
L<Parse::PlainConfig::Settings>.

=head2 default

   $text  = $config->default;
   @lines = $config->default;

This returns the text of the default configuration file embedded in the
B<__DATA__> section of the config class.

=head2 get

  $val = $config->get($parameter);
  @val = $config->get($parameter);
  %val = $config->get($parameter);

This returns the store value(s) for the specified parameter.  It is
essentially the same as using the parent class L<property> method, although
this will not cause the program to L<croak> like L<property> does.  It will
L<carp>, instead.

=head2 set

  $rv = $config->set($parameter);
  $rv = $config->set($parameter, $newval);
  $rv = $config->set($parameter, @newval);
  $rv = $config->set($parameter, %newval);

This method sets the desired parameter to the newly specified value(s).  If no
values are provided it will assume that you wish to set scalars to B<undef> or
empty arrays and hashes.

=head2 parse

  $rv = $config->parse($text);
  $rv = $config->parse(@lines);

This will parse and set any parameters or prototypes found in the content.  It
will return false if any parsing errors are found (spurious text, etc.) but
will extract everything of intelligible value it can.

=head2 read

  $rv = $config->read($filename);
  $rv = $config->read(@files);
  $rv = $config->read($pglob);
  $rv = $config->read(*fh);

This method will attempt to read every file passed to it, whether it be passed
by file name, file handle, L<Paranoid::Glob>, or objec reference support I/O
functions.  Fair warning:  this does observe file locking semantics (L<flock>)
and it will close any file handles passed to it after consuming the content.

Also note that this method uses L<Paranoid::IO::Line>, which implements
protections against memory-utilization attacks.  You may need to adjust the
following parameters depending on the size of your config files:

  use Paranoid::IO qw(PIOMAXFSIZE PIOBLKSIZE);
  use Paranoid::IO qw(PIOMAXLNSIZE);

  # Adjust read block size for performance
  PIOBLKSIZE = 16 * 1024;

  # Allow file sizes up to 128KB
  PIOMAXFSIZE = 128 * 1024;

  # Allow individual lines to be 4KB long
  PIOMAXLNSIZE = 4 * 1024;

=head2 reset

  $rv = $config->reset;

This method emptys the contents of all parameters and prototypes, then applies
the default settings as found in B<__DATA__>.

=head2 prototyped

    @protos = $config->prototyped;
    @protos = $config->prototyped($preamble);

This method returns a list of properties that were defined as the result of
prototypes.  With no arguments it returns all properties that were defined.
With an argument it returns only those properties that were defined by that
specific prototype preamble.

=head2 error

    $errStr = $config->error;

Returns the last error that occurred.  Note that this isn't reset between
method invocations.

=head1 DEPENDENCIES

=over

=item o

L<Class::EHierarchy>

=item o

L<Fcntl>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Glob>

=item o

L<Paranoid::IO>

=item o

L<Paranoid::IO::Line>

=item o

L<Paranoid::Input>

=item o

L<Parse::PlainConfig::Constants>

=item o

L<Parse::PlainConfig::Settings>

=item o

L<Text::ParseWords>

=item o

L<Text::Tabs>

=back

=head1 DIAGNOSTICS 

Through the use of B<Paranoid::Debug> this module will produce internal
diagnostic output to STDERR.  It begins logging at log level 6.  To enable
debugging output please see the pod for L<Paranoid::Debug>.

=head1 BUGS AND LIMITATIONS 

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2002 - 2023, Arthur Corliss (corliss@digitalmages.com)

