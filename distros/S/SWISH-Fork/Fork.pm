package SWISH::Fork;
use strict;

use vars (qw/$VERSION $errstr @ISA $AUTOLOAD $DEBUG/);


# Plan to change to %FIELDS
use base qw/SWISH/;

use Symbol;          # For creating a locallized file handle
#use Sys::Signal ();  # For mod_perl
use IO::Handle;      # for flushing 

# $Id: Fork.pm,v 1.13 2001/03/26 02:16:27 lii Exp $

$VERSION = '0.13';


{
    my %available = (
        prog        => 1,       # swish path (path?)
        indexes     => 1,       # Not writable?
        query       => 1,
        tags        => 1,       # Alias content?
        properties  => 1,
        maxhits     => 1,
        startnum    => 1,
        sortorder   => 1,
        start_date  => 1,
        end_date    => 1,
        results     => 1,
        headers     => 1,
        timeout     => 1,
        version     => 1,
        errstr      => 0,
        rawline     => 0,   # as read from pipe
    );
    sub _readable{ exists $available{$_[1]} };
    sub _writable{ $available{$_[1]} };
}

my @default_x_fields = qw/
    swishrank
    swishdocpath
    swishtitle
    swishlastmodified
    swishdescription
    swishstartpos
    swishdocsize
    swishdbfile
    swishreccount
/;

my @fields_pre_21 = qw/
    swishrank
    swishdocpath
    swishtitle
    swishdocsize
/;


#------------- public methods -------------------------

# Rewrite so will clone an object.
sub new {
    my $class = shift;
    $class = ref( $class ) || $class;
    
    my %attr = ref $_[0] ? %{$_[0]} : @_ if @_;


    $attr{prog} ||= $attr{path} || '';  # Alias
    
    unless ( $attr{prog} ) {
        $errstr = 'Must specify path to swish binary in $attr{prog}';
        return;
    }

    unless ( -x $attr{prog} ) {
        $errstr = "Swish binary '$attr{prog}' not executable: $!";
        return;
    }

    unless ( $attr{version} ) {
        my $version = `$attr{prog} -V`;
        $version =~ tr/[0-9].//cd;
        $version = do { my @v=split('\.', $version ); sprintf "%d." . "%03d"x$#v,@v };
        $attr{version} = $version if $version;
    }


    return bless \%attr, $class;

}


sub errstr {
    my ($self, $message ) = @_;

    if ( ref $self ) {
        $self->{_errstr} = $message if $message;
        return $self->{_errstr};
    }

    $errstr;
}



sub query {
    my $self = shift;
    my %attr = ref $_[0] ? %{$_[0]}
                         : @_ == 1 ? ( query => $_[0] ) : @_;


    # make copy of defaults, and merge in passed parameters.
    my %settings = ( %$self, %attr );

    unless ( $settings{indexes} ) {
        $self->errstr( 'Must specify index files' );
        return;
    }

    my @indexes = ref $settings{indexes} ? @{$settings{indexes}} : ( $settings{indexes} );

    for ( @indexes ) {        
        unless ( -r ) {
            $self->errstr( "Index file '$_' not readable $!" );
            return;
        }
    }

    unless ( $settings{query} ) {
        $self->errstr( 'Must specify query' );
        return;
    }


    unless ( $settings{results} && ref $settings{results} eq 'CODE' ) {
        $self->errstr( "Must specify 'results' callback"  );
        return;
    }



    # Set default version.
    $settings{version} = 1.003 unless $settings{version} && $settings{version} =~ /^[\d.]+/;

    # This may cause problems if using -d or even both.
    $settings{output_separator} ||= '::';

    $settings{output_separator} = '' if $settings{version} < 1.003;
    

    my @parameters;

    push @parameters, '-w', $settings{query},
                      '-f', @indexes;


    push @parameters,  '-d', $settings{output_separator} if $settings{output_separator};



    my @properties;
    if ( $settings{properties} ) {
        @properties = ref $settings{properties} ? @{$settings{properties}} : ($settings{properties});
    }


    if ( $settings{version} >= 2.00120 ) {

        $settings{-H} ||= 4;  # enable extended headers unless set otherwise

        my $fields;
        my $format;

        if ( $settings{output_format} ) {

            unless ( ref $settings{output_format} eq 'HASH' ) {
                $self->errstr( q['output_format' must be a hash reference] );
                return;
            }
            unless ( $settings{output_format}{FIELDS} && ref $settings{output_format}{FIELDS} eq 'ARRAY' ) {
                $self->errstr( q['output_format' must have a 'FIELDS' key and be an ARRAY reference] );
                return;
            }
            unless ( @{ $settings{output_format}{FIELDS} } ) {
                $self->errstr( q['output_format FIELDS' must not be an empty array] );
                return;
            }
            unless ( $settings{output_format}{FORMAT} && ref $settings{output_format}{FORMAT} eq 'HASH' ) {
                $self->errstr( q['output_format' must have a 'FORMAT' key and be an HASH reference] );
                return;
            }

            $fields = $settings{output_format}{FIELDS};
            $format = $settings{output_format}{FORMAT};

        } elsif ( $settings{-x} ) {   # customer supplied format -- they are on their own!

            $settings{-x} = "0$settings{output_separator}$settings{-x}";

        } else { # otherwise supply our own fields

            $fields = [@default_x_fields, @properties];
            $format = {};
        }

        # Set the format field

        if ( $fields ) {
            $settings{-x} =
                join ( $settings{output_separator},
                    '0',  # place a digit first to can find results
                    map {
                        $format->{$_}
                            ? "<$_ fmt='$format->{$_}'>"
                            : "<$_>"
                        } @$fields
                    ) . '\n';

            $settings{_fields} = $fields;
        }

    } else { # not >= 2.120

        delete $settings{-x} if exists $settings{-x};
        $settings{_fields} = \@fields_pre_21;
        push @{ $settings{_fields} }, @properties if @properties;
    }
    

    # add other settings to parameters
    push @parameters, _add_options( \%settings );



    return $self->_fork_swish( \%settings, \@parameters );
}

sub raw_query {
    my $self = shift;
    my @output;
    $self->{_raw} = \@output;
    $self->query( @_ );
    delete $self->{_raw};
    return @output;
}


sub abort_query {
    my ( $self, $errstr ) = @_;
    $self->{_abort} = $errstr || '';
}




#-------------- private methods -----------------------

# This takes the settings and returns an array of option switches that is passed to swish.
sub _add_options {
    my $settings = shift;

    my %map = (
        properties  => '-p',
        sortorder   => '-s',
        maxhits     => '-m',
        tags        => '-t',
        context     => '-t',
        startnum    => '-b',
    );

    my %lookup = reverse %map;
    
    my @options;

    for my $option ( keys %$settings ) {

        next unless my ($switch) = ($map{$option}) || $option =~ /^(-\w)$/;

        push @options, $switch;

        # so you can say -e => undef to just add a switch.
        
        push @options, ref $settings->{$option}
                       ? @{$settings->{$option}}
                       : $settings->{$option}
                           if defined $settings->{$option};

        # Need to consider if someone uses -d instead of output_seperator                           


    }
    return @options;
}    


# Win 32 version            
sub _pipe_swish {

    my ( $self, $settings, $params ) = @_;
    my $fh = gensym;

    STDOUT->flush;  # flush STDOUT STDERR
    STDERR->flush;  # so child doesn't get copies

    $self->{_start_time} = time;
    $self->{_handle}     = $fh;
    delete $self->{_abort};

    my $cmd = join ' ', $self->{prog}, map { qq["$_"] } @$params;

    warn "$$ piped open: '$cmd'\n" if $DEBUG;

    $cmd = $1 if $cmd =~ /^(.+)$/;  # Blindly untaint on w32

    unless ( open $fh, "$cmd|" ) {
        $self->errstr( "Failed to run '$self->{prog}': '$!'" );
        return;
    }

    my $hits = $self->_read_results( $settings );

    unless ( close $fh ) {
        $self->errstr( "Failed to close '$self->{prog}': '$!' '$?'");
        return;
    }

    return $hits;
}


    


sub _fork_swish {

    return &_pipe_swish if $^O =~ /win/i;

    my ( $self, $settings, $params ) = @_;

    my $fh = gensym;

    STDOUT->flush;  # flush STDOUT STDERR
    STDERR->flush;  # so child doesn't get copies



    # Fork
    my $child = open( $fh, '-|' );

    unless ( defined $child ) {
        $self->errstr( "Failed to fork: '$!'" );
        return;
    }

    warn "$$ exec: " . join(' ', $self->{prog}, @$params ) . "\n" if $DEBUG && $child;

    # this is in the child
    exec( $self->{prog}, @$params ) || die "failed to exec '$self->{prog}' $!"
        unless $child;



    
    $self->{_start_time} = time;
    $self->{_handle}     = $fh;
    $self->{_child}      = $child;
    delete $self->{_abort};

    my $hits;



    # Use Sys::Signal under mod_perl to restore Apache's signal handler
    # Should be fixed under perl 5.6.1, but check with mod_perl list to be sure.

    eval {
        my $h;

        local $SIG{ALRM};
        
        if ( $settings->{timeout} && $settings->{timeout} =~ /\d+/ ) {

            # Load Sys/Signal if available.

            eval { require 'Sys/Signal.pm' };
            if ( $@ ) {
                $SIG{ALRM} = sub { die "Timeout after $settings->{timeout} seconds\n" };
            } else {
                $h = Sys::Signal->set(ALRM => sub { die "Timeout after $settings->{timeout} seconds\n" });
            }

            alarm $settings->{timeout};
        }
        $hits = $self->_read_results( $settings );
        alarm 0 if $settings->{timeout};
    };

    if ( $@ ) {
        $self->errstr( $@ );
        kill( 'HUP', $self->{_child} );
        delete $self->{total_hits} if $self->{total_hits};
    }

    # xxx what to do with failed close here?
    close( $self->{_handle} );
    delete $self->{_handle};
    delete $self->{_child};


    #make method?
    return $hits;
    
}


sub _read_results {
    my ( $self, $settings ) = @_;

    my $error;
    my $eof;

    my $current_index_file;  # for multiple headers with -x under >= 2.1


    # Should these be method calls?
    $self->{cur_record} = 0;
    $self->{total_hits} = 0;

    my %headers;
    $self->{_indexheaders} = \%headers;


    # Set fields to grab
    

    my $fh = $self->{_handle};

    local $/ = "\n";  # just in case

    while (my $line = <$fh> ) {

    	warn ">$line" if $DEBUG;

        # a way to exit;
        die (( $self->{_abort} || 'aborted') . "\n") if exists $self->{_abort};


  
        if ( $line =~ /^\d/ ) {  # assume it's a result

            $line = $1 if $line =~ /^0\Q$settings->{output_separator}\E(.+)$/;

            # If no fields specified (this would be because -x was defined by the customer)

            unless ( $settings->{_fields} ) {
                $settings->{results}->( $self, $line  );
                next;
            }
            
            chomp $line;

            # Raw output
            if ( $self->{_raw} ) {
                push @{$self->{_raw}}, $line;
                next;
            }


            $self->{rawline} = $line;    # chomped version
            
            $self->{cur_record}++;       # this record
            my %result;

            if (  $settings->{output_separator} ) {
                @result{ @{ $settings->{_fields} } } = split /\Q$settings->{output_separator}/, $line;

            } else {
                ( @result{ @{ $settings->{_fields} } } ) = $line =~ /^(\d+)\s+([^\s]+)\s+"(.+)"\s+(\d+)$/;

            }

            $result{_settings}  = $settings;                        # so can get a list of the property names passed
            $result{swishreccount}  ||= $self->{cur_record};        # Just in case not set
            $result{total_hits} = $headers{'number of hits'}->[0] || 0;  # doesn't work with multiple indexes up to 2.0



            my $result = SWISH::Results->new( \%result );                


            $settings->{results}->( $self, $result  );

            next;
        }
        


        chomp $line; 

        # Raw output
        if ( $self->{_raw} ) {
            push @{$self->{_raw}}, $line;
            next;
        }

        $self->{rawline} = $line;


        # save the headder
        if ( $line =~ /^#/ ) {
            if ( $line =~ /^# ([^:]+):\s+(.+)$/ ) {
                my ( $name, $value ) = ( lc($1), $2 );

                push @{$headers{ $name }}, $value;  # Save the value

                # As of 2.1-dev-19 swish can (with -H) return a different set of headers for every index file
                $current_index_file = $value if $name eq 'index file';

                my $cur_index = $current_index_file
                    unless $name =~ /^(?:number of hits|run time|search time)/;

                push @{$headers{INDEX}{$cur_index}{$name}}, $value
                    if $cur_index;
                

                # Call callback for each header, passing the index file, too, if any.
            
                $settings->{headers}->( $self, $name, $value, $cur_index )
                    if $settings->{headers} && ref($settings->{headers}) eq 'CODE';

            }

            next;
        }


        # Catch errors, but not 'no results' since could be more than one index
        $error = $1 if $line =~ /^err:\s*(.+)/;

        
        # Detect eof;    
        $eof++ if $line =~ m[^\.];       # make sure we get all the results;

        # Should check for unexpected data here.
    }



    if ( $error && $error ne 'no results' ) {
        $self->errstr( $error );

        return;
    }


    return $self->{cur_record} if $self->{cur_record} && $eof;

    $self->errstr('Failed to find results') if $eof;
    $self->errstr('Failed to find end of results') unless $eof;
    return;
}



sub DESTROY {
}


sub AUTOLOAD {
    my $self = shift;
    no strict "refs";


    my $attribute = $1 if $AUTOLOAD =~ /.*::(\w+)/;
    die "failed to find attribute in autoload '$AUTOLOAD'" unless $attribute;


    die "Method '$attribute' not available"
        unless $self->_readable( $attribute );

    if ( $self->_writable( $attribute ) ) {
        *{$AUTOLOAD} = sub {
            my $me = shift;

            if ( @_ ) {
                my @params = @_;
                $me->{$attribute} = @_ > 1 ? \@params : $params[0];
            }

            return $me->{$attribute} || undef;
        };


    } else {
        *{$AUTOLOAD} = sub {
            return shift->{$attribute} || undef;
        };
    }

    return $self->$AUTOLOAD( @_ );
    
}
    


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

SWISH::Fork - Perl extension for accessing the SWISH-E search engine via a fork/exec.

=head1 SYNOPSIS

    use SWISH;

    $sh = SWISH->connect('Fork',
       prog     => '/usr/local/bin/swish-e',
       indexes  => 'index.swish-e',
       results  => sub { print $_[1]->as_string,"\n" },
    );


=head1 DESCRIPTION

This module is a driver for the SWISH search engine using the forked access method.
Please see L<SWISH> for usage instructions.

This module has been tested with the following versions of SWISH-E

    1.2.4
    1.3.2
    2.0.4
    2.1 (pre 2.2 development version)

B<NOTE:> This module is now depreciated.  Use the SWISH::API module instead.
SWISH::API is bundled with Swish-e version 2.4.0, but will soon be available
from the CPAN.  SWISH::API is an xs interface to the Swish-e library.

=head2 REQUIRED MODULES

The following module is required (and needs to be installed before installing this module.

    SWISH - the front-end for module for accessing the SWISH search engine.

These modules are required, but are standard.

    Symbol - localized file handles (standard module)

    IO::Handle - For flushing buffers

This module is not required, but *should* be installed when running under mod_perl or any situation
where a C signal handler must be restored.  (Under mod_perl we need to restore Apache's SIGALRM handler.)
The module will only be used if installed, otherwise will fall back to $SIG{ALRM}.

    Sys::Signal - Use instead of C<local $SIG{ALRM}> to restore signal handlers.
    Should be fixed in Perl 5.6.1, but check with the mod_perl list.

=head1 RUNNING UNDER Win32

This module will run under Windows, but uses a piped open to run Swish, and does not offer
timeout support.
In addition, parameters passed to swish are B<blindly> untainted -- shell escapes are not removed.
All parameters are placed in double-quotes when running under Win32.  Please let me know if there's
a better way under Win32.

It is recommended that the security issues of running CGI scripts under Windows be
carefully considered.


=head1 AUTHOR

Bill Moseley -- moseley@hank.org

=head1 SEE ALSO

L<SWISH>

=cut
