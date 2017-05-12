# =============================================================================
# $Id: Versions.pm 522 2006-09-19 11:26:13Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Find versions of loaded modules, format results flexibel
# ==============================================================================

package Module::Versions;

# -- Force Perl version
use 5.008006;

# -- Pragmas
use strict;
use warnings;

# -- Global modules
use IO::Handle;
use Data::Dumper;

our ( $VERSION, $v, $_VERSION );

# -- CPAN VERSION (='major.minor{2}')
#    With respect to historical versions of Perl itself prior to 5.6.0 and
#    the Camel rules ('...Leading zeros *are* significant...').
#    Should be CPAN and version.pm compatible... Ref: BUGS
$VERSION = do { my @r = ( ( $v = q<Version value="0.20.1"> ) =~ /\d+/g ); sprintf "%d.%02d", $r[0], int( $r[1] / 10 ) };

# -- Mumified VERSION (='major.minor{3}release{3}revision{3}')
$_VERSION = do {
    my @r = ( $v =~ /\d+/g, q$Revision: 522 $ =~ /\d+/g );
    sprintf "%d." . "%03d" x $#r, @r;
};

# *** Constructor **************************************************************

sub new {

    my $class;
    if ( $_[0] and UNIVERSAL::isa( $_[0], __PACKAGE__ ) ) {
        $class = shift;
        $class = __PACKAGE__ unless $class;
    }
    else { $class = __PACKAGE__ }

    my ( $names, $select ) = @_;

    # -- Make object, load defaults
    my $self = bless {

        names => ( ref $names eq 'ARRAY' and @{$names} )    # list of names
        ? $names                                            #
        : ( defined $names and !ref $names )                # single name
        ? [$names]                                          #
        : [ sort keys %INC ],                               #
        select => ( ref $select eq 'ARRAY' and @{$select} ) # select list
        ? $select                                           #
        : ( defined $select and !ref $select )              # single select
        ? [$select]                                         #
        : [],                                               #

        _oldver  => 0,              # default = 0
                                    # 0: try to load 'version.pm' to get
                                    #    Perl 5.10.0 compatibility
                                    # 1: try to be conservative/compatible -
                                    #    ignored if version module was loaded
                                    #    from another source part with 'use'
        _notme   => 0,              # default = 0
                                    # 0: show my own package version
                                    # 1: suppress my package version
        _all     => 0,              # default 0
                                    # 0: suppress unknown modules
                                    # 1: show unknown modules
        _version => 0,              # default 0
                                    # 0: suppress 'version' module
                                    # 1: show 'version' module
        _package => __PACKAGE__,    #

    }, $class;

    return $self;
}

# *** Methods ******************************************************************

# -- Retrieve data
sub get {

    my $self = shift->_isa_obj;     # ensure versions object
    my ($criteria) = @_;            # get params

    $self->{_criteria}
        = ( ref $criteria eq 'ARRAY' and @{$criteria} )    # list of criteria
        ? $criteria                                        #
        : ( $criteria and !ref $criteria )                 # single criteria
        ? [$criteria]                                      #
        : () if defined $criteria;                         # redefine criteria

    $self->_get;                                           # get versions

    return $self;
}

# -- Print list of modules
sub list {

    my $self = shift->_isa_obj;    # ensure versions object
    my ( $fd, $mask ) = @_;        # get params

    $self->get unless $self->_get_versions;    # get versions if missing

    $self->{fd}   = $fd   if defined $fd;      # redefine output file
    $self->{mask} = $mask if defined $mask;    # redefine output format
    $self->{fd}   ||= *STDOUT;                 # default print fd
    $self->{mask} ||= '%5d %s[ %s %s %s ]';    # default print mask
                                               # e.g. '%5d %s Module %s: %s %s'
                                               # or '%s|%s|%s', ...
    $self->_format;

    return $self;

}

# -- Return data structure with modules
sub data {

    my $self = shift->_isa_obj;                # ensure versions object
    my ($cb) = @_;                             # get params

    $self->get unless $self->_get_versions;    # get versions if missing

    $self->{cb} = $cb if defined $cb and ref $cb eq 'CODE';
    $self->{cb} ||= sub { $self->ARRAY };

    return $self->{cb}->( $self->_get_versions, $self->_get_names );
}

# -- Return ARRAY with modules - pre-formed ARRAY structure
sub ARRAY {

    my $self = shift->_isa_obj;                # ensure versions object

    $self->get unless $self->_get_versions;    # get versions if missing

    return $self->_get_versions;               # TODO: sort
}

# -- Return HASH with modules - pre-formed HASH structure
sub HASH {

    my $self = shift->_isa_obj;                # ensure versions object
    my $hash;

    $self->get unless $self->_get_versions;    # get versions if missing

    map { $hash->{ $_->[0] }{ $_->[1] } = $_->[2] }
        map { [ @{$_} ] } @{ $self->_get_versions };

    return $hash;
}

# -- Return SCALAR with modules - pre-formed SCALAR structure
sub SCALAR {

    my $self = shift->_isa_obj;                # ensure versions object

    $self->get unless $self->_get_versions;    # get versions if missing

    return
        join( qq{\n}, map { join q{,}, @{$_} } @{ $self->_get_versions } )
        ;                                      # TODO: sort
}

# -- Return CSV structure with modules - pre-formed CSV structure
sub CSV {

    my $self = shift->_isa_obj;                # ensure versions object

    my $header = q(Module,Name,Value);

    return join qq{\n}, $header, $self->SCALAR;
}

# -- Return XML structure with modules - pre-formed XML structure
sub XML {

    my $self = shift->_isa_obj;                # ensure versions object

    my $dtd = $self->{dtd}
        if defined $self->{dtd};    # Experimental: will be set by $self->DTD
    my $xsi = $self->{xsi}
        if defined $self->{xsi};    # Experimental: will be set by $self->XSD

    $self->get unless $self->_get_versions;    # get versions if missing

    my $header = q{<?xml version="1.0" encoding="UTF-8"?>};
    my ( $root, $elem, $att0, $att1 ) = (qw{versions version module name});

    my ( $open_root, $close_root ) = (
        qq{<$root}
            . ( defined $xsi ? $xsi : q{} )    # Experimental: assign W3C schema
            . qq{>},
        qq{</$root>}
    );

    return join qq{\n}, grep {$_} $header,
        ( defined $dtd ? $dtd : q{} ),         # Experimental: assign DTD
        $open_root,
        ( map {qq{\t<$elem $att0="$_->[0]" $att1="$_->[1]">$_->[2]</$elem>}}
            @{ $self->_get_versions } ), $close_root;
}

# -- Return XSD schema - set xsi in object
sub XSD {

    my $self = shift->_isa_obj;                # ensure versions object

    my $noNSL = "xsd/versions.xsd";   # Experimental: define W3C schema location
    $self->{xsi} = qq{ xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"}
        . qq{ xsi:noNamespaceSchemaLocation="$noNSL"};

    return $self->_xsd;
}

# -- Return DTD - set dtd in object
sub DTD {

    my $self = shift->_isa_obj;       # ensure versions object

    my $SYSTEM = "dtd/versions.dtd";  # Experimental: define DTD location
    $self->{dtd} = qq{<!DOCTYPE versions SYSTEM "$SYSTEM">};

    return $self->_dtd;
}

# *** Internal methods *******************************************************

# -- Check if object is valid - 'is_an_object?'
sub _isa_obj {

    my $self;

    # If this is not a method call with a valid object, create a new object
    if ( $_[0] and UNIVERSAL::isa( $_[0], __PACKAGE__ ) ) {

        $self = shift;
        $self = __PACKAGE__->new unless ref $self;    # *)
    }
    else {

        $self = __PACKAGE__->new;    # *)
    }

    # *) Attention: a new object contains implicitly the $VERSION from loaded
    #               modules only

    return $self;
}

# -- Retrieve module versions
sub _get {

    my $self = shift;

    my $names    = $self->_get_names;
    my $select   = $self->_get_select;
    my $criteria = $self->_get_criteria;
    my $package  = $self->_get_package;

    # -- Map
    my $_map = {
        'oldver' => sub { $self->{_oldver} = 1 },  # Be conservative/compatible
        'notme'  => sub { $self->{_notme}  = 1 },  # Suppress my package version
        'all'    => sub { $self->{_all}    = 1 },  # Show unknown modules also
        'version' => sub { push @{$names}, 'version'; $self->{_version} = 1 }
        ,                                          # Show version module also
    };

    # -- Criteria mapping
    foreach my $criteria ( @{$criteria} ) {
        $_map->{ lc $criteria }->()
            if ref $_map->{ lc $criteria } eq 'CODE';
    }

    # -- Clear result
    $self->{versions} = [];

    # -- Find modules
    my $_seen = {};
    foreach my $name ( @{$names} ) {

        next
            if $name =~ /\.(al|ix|bs)$/;    # ignore this  (DynaLoader, etc.)

        ( my $module = $name ) =~ s|/|::|g; # convert name to module
        $module =~ s|\.(pm)$||;             # clean module notation

        next if $_seen->{$module}++;                         # ignore duplicates
        next if $module =~ /^$package$/ and $self->{_notme}; # be demure
        next if $name =~ /^version$/ and !$self->{_version}; # be demure

        # -- Find version infos
        my $seen = { q{::} => { 'VERSION' => 1 } };    # avoid multiple scans
                                                       # of VERSION (object and
                                                       # veriable)
        push @{ $self->{versions} },

            grep { !$seen->{ $_->[0] }{ $_->[1] }++ }    # ignore duplicates
            grep { @{$_} }                               # ignore empty results

            ( eval "require $module" )                   # try to load module
            ? (

            # -- Mandantory scan of VERSION - as an object!
            [   (   eval "$module->VERSION"              # try to find VERSION
                    ? ( $module, 'VERSION',
                        eval "$module->VERSION"
                        ? eval "$module->VERSION"
                        : 'undefined'                    # ERROR! Ref: Camel ...
                        )
                    : ( $module, qw{VERSION unknown} )   # FATAL! Ref: Camel ...
                )
            ],

            # -- Optional scan of selected variables - no objects!
            map {
                [   (   eval "\$${module}::$_"           # try to find selection
                        ? ( $module, $_,
                            eval "\$${module}::$_"
                            ? eval "\$${module}::$_"
                            : 'undefined'                # !defined <variable>
                            )
                        : ()                             # can't find <variable>
                    )
                ]
                }
                grep { !$seen->{q{::}}{$_}++ } @{$select},
            )
            : [ ( $module, qw{Module unknown} ) ]        # can't load module
            if $self->{_all}              # check 'all modules wanted'
            or eval "require $module";    # check 'loadable modules only'
    }

    return $self;                         # object with versions
}

# -- Output formatting
sub _format {

    my $self     = shift;
    my $fd       = $self->_get_fd;
    my $mask     = $self->_get_mask;
    my $versions = $self->_get_versions;
    my $select   = $self->_get_select;

    # -- Map for pre-formed data format creation
    my $_map = {
        ARRAY => sub { Data::Dumper->Dump( [ shift->ARRAY ], [q{$versions}] ) },
        HASH  => sub { Data::Dumper->Dump( [ shift->HASH ],  [q{$versions}] ) },
        SCALAR => sub { shift->SCALAR },
        CSV    => sub { shift->CSV },
        XML    => sub { shift->XML },
        XSD    => sub { shift->XSD },
        DTD    => sub { shift->DTD },
    };

    # -- Valid fd only wanted...
    if ( fileno($fd) ) {

        # -- Try to use 'version' for overloading VERSION formatting
        unless ( $self->{_oldver} ) {
            eval "require version";    # try to load version.pm
            $self->{has_version} = version->can('new');    # version loaded?
        }

        # -- Message format creation
        if ( my @conv = ( $mask =~ /\%[^%]/g ) )
        {    # count universally-known conversions

            my $cnt = 0;
            foreach my $version ( @{$versions} ) {

                next unless @{$version};
                my ( $_module, $_name, $_value ) = @{$version};

                # -- Formatting
                printf $fd "$mask\n",
                    ( @conv == 5 )    # formatting with 5 conversions (%)
                    ? (
                    ++$cnt,           # 1. %
                    ( ( $_name and $_value !~ /^un/ ) ? q{ } : q{*} ),    # 2. %
                    )
                    : (),
                    (
                           @conv == 3
                        or @conv == 5
                    )    # formatting with 3 or 5 conversions (%)
                    ? (
                    ($_module),    # 3./1. %
                    ( $_name ? $_name : q{-} ),    # 4./2. %
                    (   ( defined $_value and $_value !~ /^un/ )    # 5./3. %
                        ? ( $self->{has_version}
                            ? version->new($_value)->normal    # v0.1.0
                            : $_value                          # 0.01 or 0.010
                            )
                        : ( defined $_value
                            ? $_value
                            : q{-}
                        )
                    )
                    )
                    : ();

            }
        }

        # -- Data format autoserialized preform mapping
        elsif ( $mask =~ m{^(ARRAY|HASH|SCALAR|CSV|XML|XSD|DTD)$} ) {

            local $Data::Dumper::Indent   = 0;
            local $Data::Dumper::Sortkeys = 1;

            print $fd $_map->{ uc $mask }->($self)
                if ref $_map->{ uc $mask } eq 'CODE';
        }

        # -- Data format serialized callback mapping
        elsif ( defined $mask and ref $mask eq 'CODE' ) {

            print $fd Data::Dumper->Dump(
                [ $mask->( $self->_get_versions, $self->_get_names ) ],
                [q{$versions}] );
        }
    }
}

# -- Internal getter
sub _get_versions { shift->{versions} }
sub _get_names    { shift->{names} }
sub _get_select   { shift->{select} }
sub _get_mask     { shift->{mask} }
sub _get_fd       { shift->{fd} }
sub _get_criteria { shift->{_criteria} }
sub _get_package  { shift->{_package} }

# *** Experimental *************************************************************

# -- W3C XML schema of generated XML file
sub _xsd {

    my $self = shift;

    my $localtime = scalar localtime;
    my $package   = $self->_get_package;

    return <<XSD;
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!-- \$Id XSD schema created by $package $VERSION at $localtime \$ -->
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
    <xs:element name="version">
	<xs:complexType mixed="true">
	    <xs:attribute name="module" use="required">
		<xs:simpleType>
		    <xs:restriction base="xs:string">
			<xs:pattern value="(\\w|_)+(::(\\w|_)+)*"/>
		    </xs:restriction>
		</xs:simpleType>
	    </xs:attribute>
	    <xs:attribute name="name" use="required">
		<xs:simpleType>
		    <xs:restriction base="xs:string">
			<xs:pattern value="VERSION"/>
			<xs:pattern value="Module"/>
			<xs:pattern value="(\\w|_)+"/>
		    </xs:restriction>
		</xs:simpleType>
	    </xs:attribute>
	</xs:complexType>
    </xs:element>
    <xs:element name="versions">
	<xs:complexType>
	    <xs:sequence>
		<xs:element ref="version" maxOccurs="unbounded"/>
	    </xs:sequence>
	</xs:complexType>
    </xs:element>
</xs:schema>
XSD
}

# -- DTD of generated XML file
sub _dtd {

    my $self = shift;

    my $localtime = scalar localtime;
    my $package   = $self->_get_package;

    return <<DTD;
<?xml version="1.0" encoding="UTF-8"?>
<!-- \$Id DTD created by $package $VERSION at $localtime \$ -->
<!ELEMENT version (#PCDATA)>
<!ATTLIST version
	module CDATA #REQUIRED
	name CDATA #REQUIRED
>
<!ELEMENT versions (version+)>    
DTD

}

1;

__END__

=head1 NAME

Module::Versions - Handle versions of loaded modules with flexible result interface

=head1 VERSION

This documentation refers to Module::Versions Version 0.01
$Revision: 522 $

Precautions: Alpha Release. 

=head1 SYNOPSIS

    use Module::Versions;
    
    # Simple Interface
    list Module::Versions;               # prints formatted results to STDOUT
    Module::Versions->list;              # prints formatted results to STDOUT
                  
    # Shortcuts      
    $vers  = get Module::Versions;       # retrieves loaded modules

    $vers  = Module::Versions->get;      # retrieves loaded modules
    
    $array = Module::Versions->ARRAY;    # returns array with version infos
    $hash  = Module::Versions->HASH;     # returns hash with version infos
    
    $list  = Module::Versions->SCALAR;   # returns text list with version infos
    $csv   = Module::Versions->CSV;      # returns csv list with version infos
    $xml   = Module::Versions->XML;      # returns xml struct with version infos
    $xsd   = Module::Versions->XSD;      # returns xml schema of version infos
    $dtd   = Module::Versions->DTD;      # returns DTD of version infos
    
    # Individual Parameters
    $vers = Module::Versions             # retrieves mods and vars as defined
            ->new($mods,$vars)
            ->get($criteria);
            
    $vers->list($fd,$mask);              # prints formatted results to file  
    $vers->list($fd,$preform);           # prints preformatted results to file
    $vers->list($fd,\&cb);               # prints serialied results as handled 
                                         # in callback routine
    $vers->data(\&cb);                   # returns transformed results as
                                         # defined in callback routine
    # Individual formatted output
    list Module::Versions(*LOG, '%5d %1s %-20s %10s %-16s');
                                         # prints individually formatted
                                         # results to LOG
    list Module::Versions(*DBIMPORT, '%s|%s|%s');
                                         # prints individually formatted
                                         # results to Database Import file
    
    list Module::Versions(*FD, 'SCALAR');# prints text list results to file
    list Module::Versions(*FD, 'CSV');   # prints csv list results to file
    list Module::Versions(*FD, 'XML');   # prints xml struct results to file
    list Module::Versions(*FD, 'XSD');   # prints xml schema to file
    list Module::Versions(*FD, 'DTD');   # prints DTD to file
    
    list Module::Versions(*FD, 'ARRAY'); # prints serialized results to file
    list Module::Versions(*FD, 'HASH');  # prints serialized results to file

    Module::Versions->list(*LOG);        # prints formatted results to LOG
    
    # Pretty Compact
    Module::Versions->list               # prints formatted results on STDOUT
    ->list(*XML,'XML');                  # prints xml struct results to XML file
    
    Module::Versions->list               # prints formatted results on STDOUT
    ->list(*XSD,'XSD')                   # prints xml schema to XSD file
    ->list(*XML,'XML');                  # prints xml struct results to XML file
    
    Module::Versions->list               # prints formatted results on STDOUT
    ->list(*DTD,'DTD')                   # prints DTD to DTD file
    ->list(*XML,'XML');                  # prints xml struct results to XML file
    

=head1 DESCRIPTION

Module::Versions handles versions of loaded modules with a flexible result
interface. The main goal is to get as much version informations as possible
about a module or module list with a simple call interface and an absolutely
flexible result interface. Module::Versions handles *loaded* and *loadable*
modules.

The motivation for writing this module was the need for better support
facilities to get  informations about the used modules and versions in the
productivity environment. Module::Versions allows shipping applications
basically with something like a '-version' option (See L<Getopt::Long>) but
with expanded functions.

Module::Versions tries to read the loaded/loadable module's $VERSION. For
extended purposes any private project 'version variables' can be fetched
($_VERSION, $version, $REV, etc.).

Module::Versions has a flexible result interface to satisfy different needs:
results can be lists and data structures with different formats - pre-formed
ARRAY, HASH, SCALAR, CSV, XML/XSD/DTD and a full flexible user callback
interface.

I<It is for example very simple to print a good formatted version list to the
console and save a version.xml file (in conjunction with an xsd-schema) at
the same time with an absolutely minimum of coding (L<SYNOPSIS>, Pretty
Compact) >.

Module::Versions tries to load 'version.pm' to support Perl 5.10.0's $VERSION
formatting.

=head1 METHODS

=over 2

=item Calling

Module::Versions Methods can be called as

    Class methods:              e.g.    Module::Versions->new;      
    Instance methods:           e.g.    $versions->new;
    Indirect objects:           e.q.    new Module::Versions;

=item Shortcuts

The standard chaining can be written with shortcuts:

    1.) Module::Versions->new->get;
    2.) Module::Versions->new->get->list;
    3.) Module::Versions->new->get->data;
    4.) Module::Versions->new->get->XML;
    5.) $versions = Module::Versions->new->get-list;
        $versions->list(*XSD, 'XSD');
        $versions->list(*XML, 'XML');
    
    can be written as
    
    1.) Module::Versions->get;      # result is an object
    2.) Module::Versions->list;     # result is an object and a printed list
    3.) Module::Versions->data;     # result is an ARRAY
    4.) Module::Versions->XML;      # result is a XML scalar 
    5.) Module::Versions->list      # result is an object and a printed list
        ->list(*XSD,'XSD')          # result is a XSD schema in file *XSD
        ->list(*XML,'XML');         # result is a XML scalar in file *XML

=back

=head2 Overview

=over 2

=item Constuctor

C<new>

=item Standard Methods

C<get>,
C<list>,
C<data>

=item Preformed Methods

C<ARRAY>,
C<HASH>,
C<SCALAR>,
C<CSV>,
C<XML>,
C<XSD>,
C<DTD>

=back

=head2 Constructor

=over 2

=item * new

=item * new(E<lt>MODULESE<gt>, E<lt>SELECTIONE<gt>)

Creates a new Versions object.

The object contains a list of module names and a list of variables, which will
be scanned in addition to $VERSION. The module list contains explicitely defined
names or the internal %INC names.

=over 10

=item E<lt>MODULESE<gt>

String or ARRAY of strings; default is content of %INC.

=item E<lt>SELECTIONE<gt>

String or ARRAY of strings; default is 'VERSION'.

I<This may be a list of project specific version variables that can be
observed in addition to the Perl standard variable '$VERSION', e.g. '$_VERSION',
'$version', '$REV'. See '$_VERSION' in this source (='Mumified VERSION')>.

The selection of the Perl standard variable '$VERSION' is mandantory and cannot
be reset.

=back

=back

=head2 Methods

=over 2

=item * get

=item * get(E<lt>CRITERIAE<gt>)

Retrieve C<E<lt>MODULESE<gt>> as defined before and use the
C<E<lt>SELECTIONE<gt>> as defined in object by the constructor.

The result can be accessed by C<list>, C<data> or the shortcuts C<ARRAY>,
C<HASH>, C<SCALAR>, C<CSV> and C<XML>.

=over 10

=item E<lt>CRITERIAE<gt>

String or ARRAY of strings; default formatting of the version info will be done
as 'normal' (e.g. B<v0.10.0>), if the module 'version.pm' (L<SEE ALSO>,
L<version>) is installed and can be 'required' - otherwise the original
presentation will be left untouched (e.q. B<0.01>). By default the result will
contain information about 'my own' module (Module::Versions) as well but will
ignore any information about 'unloadable' modules. A possibly loaded
'version.pm' module will not be shown.

Default is set to B<not C<oldver>>, B<not C<notme>>, B<not C<all>> and
B<not C<version>>.

=over 2

=item oldver

Tries to use the historical versions of Perl itself prior to 5.6.0, as
well as the Camel rules for the $VERSION (e.q. B<0.01>). This 'untouched'
presention can be ensured only if the module 'version.pm' had B<not> been
loaded before by the script or another module. If the 'version.pm'
was loaded, a 'version.pm' default will be used (e.q. B<0.010>). See
L<EXAMPLES>.

=item notme

Suppress 'my own' package version (Module::Versions).

=item all

Show 'unknown modules' also.

=item version

Show 'version' module also.  Influences C<oldver> criterium.

=back

=back

=item * list

=item * list(E<lt>FDE<gt>, E<lt>MASKE<gt>)

=item * list(E<lt>FDE<gt>, E<lt>PREFORME<gt>)

=item * list(E<lt>FDE<gt>, E<lt>CALLBACKE<gt>)

Prints a formatted module list to a file.

If no parameters are defiend C<list> prints to STDOUT in an predefined format.
An opened filedescriptor C<E<lt>FDE<gt>> can define another result file.

A mask C<E<lt>MASKE<gt>> redefines the standard format. ALternatively a
preformed fileformat (C<E<lt>PREFORME<gt>>) can be selected to print in standard
formats.

For indivudual requirements a C<E<lt>CALLBACKE<gt>> interface can be used.

=over 10

=item E<lt>FDE<gt>

Filedescriptor, default *STDOUT.

=item E<lt>MASKE<gt>

String, default '%5d %s[ %s %s %s ]' in sprintf format.
See L<perldoc> -f sprintf.

Default result:

    1  [ AutoLoader VERSION v5.600.0 ]
    2  [ Carp VERSION v1.30.0 ]
    3 *[ Config VERSION unknown ]
    4  [ Cwd VERSION v3.10.0 ]

Mask needs 3 or 5 arguments.

=over 10

=item * 5 Arguments

                                        ---- Examples ----
    1.  cnt           [numeric]         1           2
    2.  error         [string]                      *
    3.  module        [string]          Carp        File
    4.  variable      [string]          VERSION     Module
    5.  value         [string]          1.030       unknown

=item * 3 Arguments

                                        ---- Examples ----
    1.  module        [string]          Carp        File
    2.  variable      [string]          VERSION     Module
    3.  value         [string]          1.030       unknown

=back

=item E<lt>PREFORME<gt>

String, no default.

The following strings are valid:

=over 10

=item 'ARRAY'

Print a serialized ARRAY. Ref: C<ARRAY>.

    $versions = [['AutoLoader','VERSION','5.600'],...];

=item 'HASH'

Print a serialized HASH. Ref: C<HASH>.

    $versions = {'AutoLoader' => {'VERSION' => '5.600'},...};

=item 'SCALAR'

Print a simple text list.

    Carp,VERSION,1.030                          # Module, Name, Value
    strict,VERSION,1.030
    File,Module,unknown                         # 'all': Module 'File' not found
    Data::Dumper,VERSION,2.121_020
    Win32::PerlExe::Env,VERSION,0.050           # Standard variable $VERSION
    Win32::PerlExe::Env,_VERSION,0.050001507    # Project variable $_VERSION

=item 'CSV'

Print a simple CSV list.

    Module,Name,Value                           # Header 
    Carp,VERSION,1.030                          # Data
    strict,VERSION,1.030                        #   :
    File,Module,unknown                         #   
    Data::Dumper,VERSION,2.121_020              #   
    Win32::PerlExe::Env,VERSION,0.050           #   
    Win32::PerlExe::Env,_VERSION,0.050001507    #   

=item 'XML'

Print a XML file sructure.

Default format, if B<no> C<'XSD'> or C<'DTD'> call was executed before.

    <?xml version="1.0" encoding="UTF-8"?>
    <versions>
        <version module="Carp" name="VERSION">1.030</version>
        <version module="strict" name="VERSION">1.030</version>
        <version module="File" name="Module">unknown</version>
        <version module="Data::Dumper" name="VERSION">2.121_020</version>
        <version module="Win32::PerlExe::Env" name="VERSION">0.050</version>
        <version module="Win32::PerlExe::Env" name="_VERSION">0.050001507</version>
    </versions>

If C<'XSD'> was called before:

    <?xml version="1.0" encoding="UTF-8"?>
    <versions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:noNamespaceSchemaLocation="xsd/versions.xsd">
        <version module="Carp" name="VERSION">1.030</version>
        <version module="strict" name="VERSION">1.030</version>
            :
    </versions>

If C<'DTD'> was called before:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE versions SYSTEM "dtd/versions.dtd">
    <versions>
        <version module="Carp" name="VERSION">1.030</version>
        <version module="strict" name="VERSION">1.030</version>
            :
    </versions>

=item 'XSD'

Print a C<'XML'> file related XSD schema file.

=item 'DTD'

Print a C<'XML'> file related DTD file.

=back

=item E<lt>CALLBACKE<gt>

CODE reference, no default. Interface 

    sub cb {
        my ( $versions, $names ) = @_;
        # Do anything and build result...
        return $result;
    }

=back

=item * data

=item * data(E<lt>CALLBACKE<gt>)

Result from callback (C<E<lt>CALLBACKE<gt>>) routine, default callback is
C<ARRAY>;

=item * ARRAY

Result is an ARRAY:

        [
          [
            'AutoLoader',                   # Module
            'VERSION',                      # Variable
            '5.600'                         # Value
          ],
                :
                :
                :
          [
            'warnings::register',
            'VERSION',
            '1.000'
          ]
        ];

=item * HASH

Result is a HASH:

        {
          'Carp' => {                       # Module
                'VERSION' => '1.030'        # Variable and Value
                    },
          'Data::Dumper' => {
                'VERSION' => '2.121_020'
                            },
          'File' => {                       # Criterium was 'all'...
                'Module' => 'unknown'       # Module 'File' not found 
                    },
          'Win32::PerlExe::Env' => {
                'VERSION' => '0.050',       # Standard variable $VERSION
                '_VERSION' => '0.050001507  # Project variable $_VERSION
                                   },
        }

=item * SCALAR

Result is a simple text SCALAR. Ref: C<'SCALAR'>.

=item * CSV

Result is a simple CSV text scalar. Ref: C<'CSV'>.

=item * XML

Result is a XML text scalar. Ref: C<'XML'>.

=item * XSD

Result is a XSD text scalar. Ref: C<'XSD'>.

=item * DTD

Result is a DTD text scalar. Ref: C<'DTD'>.

=back

=head1 DIAGNOSTICS

The XML generation allows an experimental feature to build XML data which can
be validated. This will be done magically if one of the following sequences will
be used:

    1.) $v->list(*XSD,'XSD')->list(*XML,'XML');
    2.) $v->list(*DTD,'DTD')->list(*XML,'XML');

=head1 CONFIGURATION AND ENVIRONMENT

*** tbd ***

=head1 EXAMPLES

See F<examples> of this distributions.

=head1 DEPENDENCIES

L<IO::Handle> L<Data::Dumper>

=head1 BUGS

This is an Alpha Release.

The XSD/DTD methods are experimental.

Some parts of this documentation may be marked as *** tbd ***.

Send bug reports to my email address or use the CPAN RT system.

=head1 SEE ALSO

L<version>

L<Module::Find>,
L<Module::InstalledVersion>,
L<Module::Info>,
L<Module::List>,
L<Module::Locate>,
L<Module::Which>,
L<Module::Which::List>

=head1 AUTHOR

Thomas Walloschke E<lt>thw@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Thomas Walloschke (thw@cpan.org). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available. See
L<perlartistic>.

=head1 DATE

Last changed $Date: 2006-09-19 13:26:13 +0200 (Di, 19 Sep 2006) $.

=cut
