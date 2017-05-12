package SWISH::Prog::Config;
use strict;
use warnings;
use Carp;
use File::Slurp;
use Config::General;
use Data::Dump qw( dump );
use File::Temp ();
use Search::Tools::XML;
use Search::Tools::UTF8;
use SWISH::Prog::Utils;
use File::Spec;
use overload(
    '""'     => \&stringify,
    bool     => sub {1},
    fallback => 1,
);

our $VERSION = '0.75';

my $XML = Search::Tools::XML->new;

use base qw( SWISH::Prog::Class );

my %unique = map { $_ => 1 } qw(
    MetaNames
    PropertyNames
    PropertyNamesNoStripChars
    IncludeConfigFile
);

my %takes_single_value = map { $_ => 1 } qw(
    IndexFile
    FuzzyIndexingMode
);

my @Opts = qw(
    AbsoluteLinks
    BeginCharacters
    BumpPositionCounterCharacters
    Buzzwords
    CascadeMetaContext
    ConvertHTMLEntities
    DefaultContents
    Delay
    DontBumpPositionOnEndTags
    DontBumpPositionOnStartTags
    EnableAltSearchSyntax
    EndCharacters
    EquivalentServer
    ExtractPath
    FileFilter
    FileFilterMatch
    FileInfoCompression
    FileMatch
    FileRules
    FollowSymLinks
    FollowXInclude
    FuzzyIndexingMode
    HTMLLinksMetaName
    IgnoreFirstChar
    IgnoreLastChar
    IgnoreLimit
    IgnoreMetaTags
    IgnoreNumberChars
    IgnoreTotalWordCountWhenRanking
    IgnoreWords
    ImageLinksMetaName
    IncludeConfigFile
    IndexAdmin
    IndexAltTagMetaName
    IndexComments
    IndexContents
    IndexDescription
    IndexDir
    IndexFile
    IndexName
    IndexOnly
    IndexPointer
    IndexReport
    MaxDepth
    MaxWordLimit
    MetaNameAlias
    MetaNames
    MetaNamesRank
    MinWordLimit
    NoContents
    obeyRobotsNoIndex
    ParserWarnLevel
    PreSortedIndex
    PropCompressionLevel
    PropertyNameAlias
    PropertyNames
    PropertyNamesCompareCase
    PropertyNamesDate
    PropertyNamesIgnoreCase
    PropertyNamesMaxLength
    PropertyNamesNoStripChars
    PropertyNamesNumeric
    PropertyNamesSortKeyLength
    RecursionDepth
    ReplaceRules
    ResultExtFormatName
    SpiderDirectory
    StoreDescription
    SwishProgParameters
    SwishSearchDefaultRule
    SwishSearchOperators
    TagAlias
    TmpDir
    TranslateCharacters
    TruncateDocSize
    UndefinedMetaTags
    UndefinedMetaNames
    UndefinedXMLAttributes
    UseSoundex
    UseStemming
    UseWords
    WordCharacters
    Words
    XMLClassAttributes
);
my %Opts = map { $_ => $_ } @Opts;

__PACKAGE__->mk_accessors(qw( file debug verbose ));

=head1 NAME

SWISH::Prog::Config - read/write Swish-e config files

=head1 SYNOPSIS

 use SWISH::Prog::Config;
 
 my $config = SWISH::Prog::Config->new;
 $config->write2();
 $config->read2('path/to/file.conf');
 $config->write3();
 
 
=head1 DESCRIPTION

The SWISH::Prog::Config class is intended to be accessed via SWISH::Prog->new().

See the Swish-e documentation for a list of configuration parameters.
Each parameter has an accessor/mutator method as part of the Config object.
Some preliminary compatability is offered for SWISH::3::Config
with XML format config files.

B<NOTE:> Every config parameter can take either a scalar or an array ref as a value.
In addition, you may append config values to any existing values by passing an additional
true argument. The return value of any 'get' is always an array ref.

Example:

 $config->MetaNameAlias( ['foo bar', 'one two', 'red yellow'] );
 $config->MetaNameAlias( 'green blue', 1 );
 print join("\n", @{ $config->MetaNameAlias }), " \n";
 # would print:
 # foo bar
 # one two
 # red yellow
 # green blue
 

=head1 METHODS

=head2 new( I<params> )

Instantiate a new Config object. 
Takes a hash of key/value pairs, where each key
may be a Swish-e configuration parameter.

Example:

 my $config = SWISH::Prog::Config->new( DefaultContents => 'HTML*' );
 
 print "DefaultContents is ", $config->DefaultContents, "\n";
 
=cut

sub new {
    my $class = shift;
    my ( %args, $file2read );
    if ( @_ == 1 && !ref $_[0] ) {
        $file2read = shift;
    }
    elsif ( !ref $_[0] ) {
        %args = @_;
    }
    else {
        %args = %{ $_[0] };
    }

    # do our own init here because we rely on AUTOLOAD magic
    my $self = bless {}, $class;
    for my $k ( keys %args ) {
        $self->$k( $args{$k} );
    }

    # set some defaults
    $self->{'_start'} = time;
    $self->IgnoreTotalWordCountWhenRanking(0)
        unless defined $self->IgnoreTotalWordCountWhenRanking;

    if ($file2read) {
        $self->read2($file2read);
    }

    return $self;
}

=head2 debug

Get/set the debug level. Default is 0.

=head2 verbose

Get/set flags affecting the verbosity of the program.

=cut

=head2 get_opt_names

Class method.

Returns array ref of all the option (method) names supported.

=cut

sub get_opt_names {
    return [@Opts];
}

sub _set {
    my $self = shift;
    my ( $key, $val, $append ) = @_;

    if ( $key eq 'file' or $key eq 'debug' ) {
        return $self->{$key} = $val;
    }
    elsif ( exists $unique{$key} ) {
        return $self->_name_hash( $key, $val );
    }

    $self->{$key} = [] unless defined $self->{$key};

    # save everything as an array ref regardless of input
    if ( ref $val ) {
        if ( ref($val) eq 'ARRAY' ) {
            $self->{$key} = $append ? [ @{ $self->{$key} }, @$val ] : $val;
        }
        else {
            croak "$key cannot accept a " . ref($val) . " ref as a value";
        }
    }
    else {
        $self->{$key} = $append ? [ @{ $self->{$key} }, $val ] : [$val];
    }

}

sub _get {
    my $self = shift;
    my $key  = shift;

    if ( exists $unique{$key} ) {
        return $self->_name_hash($key);
    }
    elsif ( exists $takes_single_value{$key} ) {
        return $self->{$key}->[0];
    }
    else {
        return $self->{$key};
    }
}

sub _name_hash {
    my $self = shift;
    my $name = shift;

    if (@_) {

        #carp "setting $name => " . join(', ', @_);
        for my $v (@_) {
            my @v = ref $v ? @$v : ($v);
            $self->{$name}->{ lc($_) } = 1 for @v;
        }
    }
    else {

        #carp "getting $name -> " . join(', ', sort keys %{$self->{$name}});

    }

    return [ sort keys %{ $self->{$name} } ];
}

=head2 read2( I<path/file> )

Reads version 2 compatible config file and stores in current object.
Returns parsed config file as a hashref or undef on failure to parse.

Example:

 use SWISH::Prog::Config;
 my $config = SWISH::Prog::Config->new();
 my $parsed = $config->read2( 'my/file.cfg' );
 
 # should print same thing
 print $config->WordCharacters->[0], "\n";
 print $parsed->{WordCharacters}, "\n";
 
 
=cut

sub read2 {
    my $self = shift;
    my $file = shift or croak "version2 type file required";

    # stringify $file in case it is an object
    my $buf = read_file("$file");

    # filter include syntax to work with Config::General's
    $buf =~ s,IncludeConfigFile (.+?)\n,Include $1\n,g;

    my ( $volume, $dir, $filename ) = File::Spec->splitpath($file);

    my $c = Config::General->new(
        -String           => $buf,
        -IncludeRelative  => 1,
        -ConfigPath       => [$dir],
        -ApacheCompatible => 1,
    ) or return;

    my %conf = $c->getall;

    for ( keys %conf ) {
        my $v = $conf{$_};
        $self->$_( $v, 1 );
    }

    return \%conf;
}

=head2 write2( I<path/file> [,I<prog_mode>] )

Writes version 2 compatible config file.

If I<path/file> is omitted, a temp file will be
written using File::Temp.

If I<prog_mode> is true all config directives 
inappropriate for the -S prog mode in the Native::Indexer
are skipped. The default is false.

Returns full path to file.

Full path is also available via file() method.

=head2 file

Returns name of the file written by write2().

=cut

sub write2 {
    my $self      = shift;
    my $file      = shift || File::Temp->new();
    my $prog_mode = shift || 0;

    # stringify both
    write_file( "$file", $self->stringify($prog_mode) );

    #warn "$self";

    warn "wrote config file $file" if $self->debug;

    # remember file. this especially crucial for File::Temp
    # since we want it to hang around till $self is DESTROYed
    if ( ref $file ) {
        $self->{__tmpfile} = $file;
    }
    $self->file("$file");

    return $self->file;
}

=head2 write3( I<path/file> )

Write config object to file in SWISH::3::Config XML format.

=cut

sub write3 {
    my $self = shift;
    my $file = shift or croak "file required";

    write_file( "$file", $self->ver2_to_ver3 );

    warn "wrote config file $file" if $self->debug;

    return $self;
}

=head2 as_hash

Returns current Config object as a hash ref.

=cut

sub as_hash {
    my $self = shift;
    my $c = Config::General->new( -String => $self->stringify );
    return { $c->getall };
}

=head2 all_metanames

Returns array ref of all MetaNames, regardless of whether they
are declared as MetaNames, MetaNamesRank or MetaNameAlias config
options.

=cut

sub all_metanames {
    my $self = shift;
    my @meta = @{ $self->MetaNames };
    for my $line ( @{ $self->MetaNamesRank || [] } ) {
        my ( $bias, @list ) = split( m/\ +/, $line );
        push( @meta, @list );
    }
    for my $line ( @{ $self->MetaNameAlias || [] } ) {
        my ( $orig, @alias ) = split( m/\ +/, $line );
        push( @meta, @alias );
    }
    return \@meta;
}

=head2 stringify([I<prog_mode>])

Returns object as version 2 formatted scalar.

If I<prog_mode> is true skips inappropriate directives for
running the Native::Indexer. Default is false. See write2().

This method is used to overload the object for printing, so these are
equivalent:

 print $config->stringify;
 print $config;

=cut

sub stringify {
    my $self = shift;
    my $prog_mode = shift || 0;
    my @config;

   # must pass metanames and properties first, since others may depend on them
   # in swish config parsing.
    for my $method ( keys %unique ) {
        my $v = $self->$method;

        next unless scalar(@$v);

        #carp "adding $method to config";
        push( @config, "$method " . join( ' ', @$v ) );
    }

    for my $name (@Opts) {
        next if exists $unique{$name};
        if ( $prog_mode && $name =~ m/^File/ ) {
            next;
        }

        my $v = $self->$name;
        next unless defined $v;
        if ( ref $v ) {
            push( @config, "$name $_" ) for @$v;
        }
        else {
            push( @config, "$name $v" );
        }
    }

    my $buf = join( "\n", @config ) . "\n";

    print STDERR $buf if $self->debug;

    return $buf;
}

sub _write_utf8 {
    my ( $self, $file, $buf ) = @_;
    binmode $file, ':utf8';
    print {$file} $buf;
}

=head2 ver2_to_ver3( I<file> )

Utility method for converting Swish-e version 2 style config files
to SWISH::3::Config XML style.

Converts I<file> to XML format and returns as XML string.

  my $xmlconf = $config->ver2_to_ver3( 'my/file.config' );

If I<file> is omitted, uses the current values in the calling object.

=cut

sub ver2_to_ver3 {
    my $self         = shift;
    my $file         = shift;
    my $no_timestamp = shift || 0;

    # list of config directives that take arguments to the opt value
    # i.e. the directive has 3 or more parts
    my %takes_arg = map { $_ => 1 } qw(
        DefaultContents
        ExtractPath
        FileFilter
        FileRules
        IgnoreWords
        IndexContents
        MetaNameAlias
        MetaNamesRank
        PropertyNameAlias
        PropertyNamesMaxLength
        PropertyNamesSortKeyLength
        ReplaceRules
        StoreDescription
        TagAlias
        Words
    );

    my %parser_map = (
        'XML'  => 'application/xml',
        'HTML' => 'text/html',
        'TXT'  => 'text/plain',
    );

    my %remap = (
        'IndexDir'    => 'SourceDir',
        'IndexOnly'   => 'SourceOnly',
        'IndexReport' => 'Verbosity',
    );

    my %unsupported = map { $_ => 1 } qw(
        BeginCharacters
        Delay
        EndCharacters
        EquivalentServer
        FileFilter
        FileFilterMatch
        FileMatch
        FileRules
        FileRules
        IgnoreFirstChar
        IgnoreLastChar
        MaxDepth
        SpiderDirectory
        SwishProgParameters
        TmpDir
        WordCharacters
    );
    my $disclaimer = "<!-- WARNING: CONFIG ignored by Swish3 -->\n ";

    my $class = ref($self) || $self;
    my $config = $file ? $class->new->read2($file) : $self->as_hash;
    my $time = $no_timestamp ? '' : localtime();

    # if we were not passed a file name, all the config resolution
    # has already been done, so do not perpetuate.
    if ( !$file ) {
        delete $config->{IncludeConfigFile};
    }

    my $xml = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<!-- converted with SWISH::Prog::Config ver2_to_ver3() $time -->
<swish>
EOF

    my $debug = ref($self) ? $self->debug : 0;
    $debug and warn dump $config;

    # first convert the $config ver2 hash into a ver3 hash
    my %conf3 = (
        MetaNames     => {},
        PropertyNames => {},
        Index         => { Format => ['Native'], },
        MIME          => {},
        Parsers       => {},
        TagAlias      => {},
    );

    #warn dump $config;

KEY: for my $k ( sort keys %$config ) {
        my @args = ref $config->{$k} ? @{ $config->{$k} } : ( $config->{$k} );

        $debug and warn "$k => " . dump( \@args );

        if ( $k eq 'MetaNames' ) {
            for my $line (@args) {
                for my $metaname ( split( m/\ +/, $line ) ) {
                    $conf3{'MetaNames'}->{$metaname} ||= {};
                }
            }
        }
        elsif ( $k eq 'MetaNamesRank' ) {
            for my $pair (@args) {
                my ( $bias, $names ) = ( $pair =~ m/^([\-\d]+) +(.+)$/ );
                for my $name ( split( m/\ +/, $names ) ) {
                    $conf3{'MetaNames'}->{$name}->{bias} = $bias;
                }
            }
        }
        elsif ( $k eq 'TagAlias' ) {
            for my $pair (@args) {
                my ( $name, $aliases ) = ( $pair =~ m/^(\S+) +(.+)$/ );
                for my $alias ( split( m/\ +/, $aliases ) ) {
                    $conf3{'TagAlias'}->{$alias} = $name;
                }
            }
        }
        elsif ( $k eq 'MetaNameAlias' ) {
            for my $pair (@args) {
                my ( $name, $aliases ) = ( $pair =~ m/^(\S+) +(.+)$/ );
                for my $alias ( split( m/\ +/, $aliases ) ) {
                    $conf3{'MetaNames'}->{$alias}->{alias_for} = $name;
                }
            }
        }
        elsif ( $k eq 'PropertyNames' ) {
            for my $line (@args) {
                for my $name ( split( m/\ +/, $line ) ) {
                    $conf3{'PropertyNames'}->{$name} ||= {};
                }
            }
        }
        elsif ( $k eq 'PropertyNamesCompareCase' ) {
            for my $line (@args) {
                for my $name ( split( m/\ +/, $line ) ) {
                    $conf3{'PropertyNames'}->{$name}->{ignore_case} = 0;
                }
            }
        }
        elsif ( $k eq 'PropertyNamesIgnoreCase' ) {
            for my $line (@args) {
                for my $name ( split( m/\ +/, $line ) ) {
                    $conf3{'PropertyNames'}->{$name}->{ignore_case} = 1;
                }
            }
        }
        elsif ( $k eq 'PropertyNamesNoStripChars' ) {
            for my $line (@args) {
                for my $name ( split( m/\ +/, $line ) ) {
                    $conf3{'PropertyNames'}->{$name}->{verbatim} = 1;
                }
            }
        }
        elsif ( $k eq 'PropertyNamesNumeric' ) {
            for my $line (@args) {
                for my $name ( split( m/\ +/, $line ) ) {
                    $conf3{'PropertyNames'}->{$name}->{type} = 'int';
                }
            }
        }
        elsif ( $k eq 'PropertyNamesDate' ) {
            for my $line (@args) {
                for my $name ( split( m/\ +/, $line ) ) {
                    $conf3{'PropertyNames'}->{$name}->{type} = 'date';
                }
            }
        }
        elsif ( $k eq 'PropertyNameAlias' ) {
            for my $pair (@args) {
                my ( $name, $aliases ) = ( $pair =~ m/^(\S+) +(.+)$/ );
                for my $alias ( split( m/\ +/, $aliases ) ) {
                    $conf3{'PropertyNames'}->{$alias}->{alias_for} = $name;
                }
            }
        }
        elsif ( $k eq 'PropertyNamesMaxLength' ) {
            for my $pair (@args) {
                my ( $max, $names ) = ( $pair =~ m/^([\d]+) +(.+)$/ );
                for my $name ( split( m/\ +/, $names ) ) {
                    $conf3{'PropertyNames'}->{$name}->{max} = $max;
                }
            }
        }
        elsif ( $k eq 'PropertyNamesSortKeyLength' ) {
            for my $pair (@args) {
                my ( $len, $names ) = ( $pair =~ m/^([\d]+) +(.+)$/ );
                for my $name ( split( m/\ +/, $names ) ) {
                    $conf3{'PropertyNames'}->{$name}->{sort_length} = $len;
                }
            }
        }
        elsif ( $k eq 'PreSortedIndex' ) {
            for my $line (@args) {
                for my $name ( split( m/\ +/, $line ) ) {
                    $conf3{'PropertyNames'}->{$name}->{sort} = 1;
                }
            }
        }
        elsif ( $k eq 'StoreDescription' ) {
            for my $line (@args) {
                my ( $parser_type, $tag, $len )
                    = ( $line =~ m/^(XML|HTML|TXT)[2\*]? +<(.+?)> ?(\d*)$/ );
                if ( !$tag ) {
                    warn "unparsed config2 line for StoreDescription: $line";
                    next;
                }
                $conf3{'PropertyNames'}->{$tag}->{alias_for}
                    = 'swishdescription';
            }
        }

        elsif ( $k eq 'IndexContents' ) {
            for my $line (@args) {
                my ( $parser_type, $file_ext )
                    = ( $line =~ m/^(XML|HTML|TXT)[2\*]? +(.+)$/ );

                if ( !exists $parser_map{$parser_type} ) {
                    warn "Unsupported Parser type: $parser_type\n";
                    next;
                }

                for my $ext ( split( m/\ +/, $file_ext ) ) {
                    $ext =~ s/^\.//;
                    my $mime
                        = SWISH::Prog::Utils->mime_type( "null.$ext", $ext )
                        || $parser_map{$parser_type};
                    if (    exists $conf3{Parsers}->{$parser_type}
                        and exists $conf3{Parsers}->{$parser_type}->{$mime} )
                    {
                        warn
                            "parser type $parser_type already defined for $mime\n";
                        next;
                    }
                    if ( exists $parser_map{$parser_type}
                        and $parser_map{$parser_type} eq $mime )
                    {

                        # already a default
                        next;
                    }
                    $conf3{Parsers}->{$parser_type}->{$mime} = $ext;
                    if ( exists $conf3{MIME}->{$ext} ) {
                        warn "file extension '$ext' already defined\n";
                        next;
                    }
                    $conf3{MIME}->{$ext} = $mime;
                }
            }
        }
        elsif ( $k eq 'DefaultContents' ) {
            my $parser = $args[0];
            $conf3{Parsers}->{default}->{$parser} = $parser;
        }
        elsif ( exists $remap{$k} ) {
            push( @{ $conf3{ $remap{$k} } }, @args );
        }
        elsif ( $k =~ m/^Index(\w+)/ ) {
            my $tag = $1;
            push( @{ $conf3{'Index'}->{$tag} }, join( ' ', @args ) );
        }

        else {
            push( @{ $conf3{$k} }, @args );
        }

    }

    # now convert %conf3 to XML

    # deal with these special cases separately
    my $metas     = delete $conf3{'MetaNames'};
    my $props     = delete $conf3{'PropertyNames'};
    my $index     = delete $conf3{'Index'};
    my $mimes     = delete $conf3{'MIME'};
    my $parsers   = delete $conf3{'Parsers'};
    my $tag_alias = delete $conf3{'TagAlias'};

    for my $k ( sort keys %conf3 ) {
        my $key = to_utf8($k);
        for my $v ( @{ $conf3{$k} } ) {
            my $val  = $XML->escape( to_utf8($v) );
            my $note = '';

            # $key fails to register in exists() below under 5.10
            if ( exists $unsupported{$k} ) {
                $note = $disclaimer;
                $note =~ s/CONFIG/$key/;
            }
            $xml .= " $note<$key>$val</$key>\n";
        }
    }

    if ( keys %$metas ) {
        $xml .= " <MetaNames>\n";
        for my $name ( sort keys %$metas ) {
            my $uname = to_utf8($name);
            $xml .= sprintf( "  <%s />\n",
                $self->_make_tag( $uname, $metas->{$name} ) );
        }
        $xml .= " </MetaNames>\n";
    }
    if ( keys %$props ) {
        $xml .= " <PropertyNames>\n";
        for my $name ( sort keys %$props ) {
            my $uname = to_utf8($name);
            $xml .= sprintf( "  <%s />\n",
                $self->_make_tag( $uname, $props->{$name} ) );
        }
        $xml .= " </PropertyNames>\n";
    }

    $xml .= " <Index>\n";
    for my $tag ( sort keys %$index ) {
        for my $val ( @{ $index->{$tag} } ) {
            $xml .= sprintf( "  <%s>%s</%s>\n", $tag, $XML->escape($val),
                $tag );
        }
    }
    if ( $conf3{FuzzyIndexingMode} ) {
        $debug
            and warn "got FuzzyIndexingMode: $conf3{FuzzyIndexingMode}->[0]";
        $xml .= sprintf(
            "  <%s>%s</%s>\n",
            "Stemmer",
            $XML->escape(
                $self->get_stemmer_lang( $conf3{FuzzyIndexingMode}->[0] )
            ),
            "Stemmer"
        );
    }
    $xml .= " </Index>\n";

    if ( keys %$mimes ) {
        $xml .= " <MIME>\n";
        for my $ext ( sort keys %$mimes ) {
            my $mime = $mimes->{$ext};
            $xml .= sprintf( "  <%s>%s</%s>\n",
                $XML->tag_safe($ext), $XML->escape($mime),
                $XML->tag_safe($ext) );
        }
        $xml .= " </MIME>\n";
    }

    if ( keys %$parsers ) {
        $xml .= " <Parsers>\n";
        for my $parser ( sort keys %$parsers ) {
            for my $mime ( sort keys %{ $parsers->{$parser} } ) {
                $xml .= sprintf( "  <%s>%s</%s>\n",
                    $XML->tag_safe($parser),
                    $XML->escape($mime), $XML->tag_safe($parser) );
            }
        }
        $xml .= " </Parsers>\n";
    }

    if ( keys %$tag_alias ) {
        $xml .= " <TagAlias>\n";
        for my $alias ( sort keys %$tag_alias ) {
            my $name = $tag_alias->{$alias};
            $xml .= sprintf( "  <%s>%s</%s>\n",
                $XML->tag_safe($alias),
                $XML->escape($name), $XML->tag_safe($alias) );
        }
        $xml .= " </TagAlias>\n";
    }

    $xml .= "</swish>\n";

    return $xml;

}

sub _make_tag {
    my ( $self, $tag, $attrs ) = @_;
    return $XML->tag_safe($tag) . $XML->attr_safe($attrs);
}

=head2 get_stemmer_lang([ I<fuzzymode> ])

Returns the 2-letter language code for the Snowball stemmer
corresponding to I<fuzzymode>. If I<fuzzymode> is not defined,
calls FuzzyIndexingMode() method on the config object.

=cut

sub get_stemmer_lang {
    my $self = shift;
    my $lang = shift || $self->FuzzyIndexingMode;
    $self->debug and warn "get_stemmer_lang for '$lang'";
    if ( $lang and $lang =~ m/^Stemming_(\w\w)/ ) {
        return $1;
    }
    return 'none';
}

sub AUTOLOAD {
    my $self   = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*://;
    return if $method eq 'DESTROY';
    if ( !exists $Opts{$method} ) {
        croak("method '$method' not implemented in $self");
    }
    if (@_) {
        return $self->_set( $method, @_ );
    }
    else {
        return $self->_get($method);
    }
}

1;

__END__

=head1 TODO

IgnoreTotalWordCountWhenRanking defaults to 0 
which is B<not> the default in Swish-e.
This is to make the RankScheme feature work by default. 
Really, the default should be 0 in Swish-e itself.

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
