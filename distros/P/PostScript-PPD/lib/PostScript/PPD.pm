package PostScript::PPD;

# use 5.008008;
use strict;
use warnings;

use Compress::Zlib qw( gzopen );
use Carp qw( carp croak confess cluck );
use Storable qw( dclone );
use IO::File;

our $VERSION = '0.0206';

################################################
sub new
{
    my( $package, $file ) = @_;
    my $self = bless { file => $file }, $package;
    $self->load if $file;
    return $self;
}

################################################
sub load
{
    my( $self, $file ) = @_;
    croak "Usage: $self->load( [ $file ] );"
            unless $file or $self->{file};
    
    $file ||= $self->{file};
    return unless $file;

    delete @{ $self }{ keys %$self };

    local $self->{__read_state};

    my $linenum = 0;
    eval {
        if( $file =~ /\.gz$/ ) {
            my $gz = gzopen( $file, "rb" );
            croak "Unable to read $file: $!" unless $gz;
            $self->{file} = $file;

            my( $line, $size );
            while( $size = $gz->gzreadline( $line ) ) {
                $linenum++;
                $self->__read_line( $line );
            }
        }
        else {
            my $fh = IO::File->new( $file );
            croak "Unable to read $file: $!" unless $fh;
            $self->{file} = $file;
            while( <$fh> ) {
                $DB::single = 1 if $. == 109;
                $linenum++;
                $self->__read_line( $_ );
            }
        }
    };
    if( $@ ) {
        die "File $file line $linenum: $@";
    }
}

################################################
sub __read_line
{
    my( $self, $line ) = @_;

    $self->{__read_state} ||= { state => 0, 
                                value => '',
                                key   => '',
                                current => [ $self ]
                              };
    my $S = $self->{__read_state};

#    $DB::single = 1 if $line =~ /CloseUI \*HPCollateSupported/;
    if( $S->{key} ) {
        $self->__append( $line );
        return;
    }

    # comment
    return if $line =~ /^\*%/;
    # End a multi-line tupple
    if( $line =~ /^\*End\s*$/ ) {
        $self->__new_tupple if $S->{key};
        return;
    }

    # Start a config group
    if( $line =~ /^\*OpenGroup:\s*(.+)/ ) {
        $self->__new_group( $1 );
        return;
    }
    # End a config group
    if( $line =~ /^\*CloseGroup:\s*(.+)/ ) {
        $self->__end_group( $1 );
        return;
    }
    # Open a UI option
    if( $line =~ /^\*OpenUI\s*\*(.+?):\s*(.+)/ ) {
        $self->__new_UI( $1, $2 );
        return;
    }
    # End the UI option
    if( $line =~ /^\*CloseUI:?\s*\*(.+)/ ) {
        $self->__end_UI( $1 );
        return;
    }
    # New tupple
    if( $line =~ /^(\*([^:]+):\s*)/ ) {
        $S->{key} = $2;
        $S->{value} = '';
        $self->__append( substr $line, length $1 );
        return;
    }
    return unless $line =~ /\S/;
    
    warn "What's with line '$line'";
}

################################################
sub __append
{
    my( $self, $line, $len ) = @_;

    my $S = $self->{__read_state};
    my $exit = 0;
    $exit = 1 if not $S->{value};
    
    if( $line =~ m/^"(.*)"\s+$/ ) {
        $exit = 1;
    }    
    elsif( $line =~ m/^"/ ) {
        $exit = ( 0 != length $S->{value} );
    }
    elsif( not $S->{value} ) {
        $line =~ s/\s+$//;
    }

    if( $line =~ /"\s*$/ and $line ne qq("\n) ) {
        $exit = 1;
    }
    if( $line =~ s/&&\s*$// ) {
        $exit = 0;
    }

    $S->{value} .= $line;

    if( $exit ) {
        $self->__new_tupple;
        return;
    }
}

################################################
sub __new_tupple
{
    my( $self ) = @_;
    my $S = $self->{__read_state};
    return unless $S->{key};

    my $C = $S->{current}[-1];
    if( $S->{key} =~ /^([^ ]+)\s+(.+(\/.+)?)$/ ) {
        $self->__new_option( $1, $2, $S->{value} );
    }
    else {
        my $v = $self->__fix_value( $S->{value} );
        my $k = $S->{key};
        if( $C->{ $k } ) {
            $C->{ $k } = [ $C->{$k} ] unless ref $C->{$k};
            push @{ $C->{$k} }, $v;
        }
        else {
            $C->{ $k } = $v;
        }
        $C->{__sorted} ||= [];
        $self->__new_key( $k );
    }
    $S->{key} = '';
    $S->{value} = '';
}

sub __fix_value
{
    my( $self, $v ) = @_;
    if( $v eq 'False' ) {
        return 0;
    }
    elsif( $v =~ s/"(.+)"\s*/$1/s ) {
        $v =~ s/&quot;?/"/g;
    }
    return $v;
}

sub __new_key
{
    my( $self, $key ) = @_;
    my $S = $self->{__read_state};
    my $C = $S->{current}[-1];
    push @{ $C->{__sorted} }, $key unless $C->{$key};
}

################################################
sub __new_option
{
    my( $self, $key, $name, $value ) = @_;
    my( $tname, $text ) = $self->__parse_name( $name );
    my $S = $self->{__read_state};
    my $C = $S->{current}[-1];

    $self->__new_key( $key );

    $C->{$key} ||= {
                       __sorted => []
                   };

    $C->{$key}{$tname} = { __name => $tname,
                           __text => $text,
                           value  => $self->__fix_value( $value )
                         };
    push @{ $C->{$key}{__sorted} }, $tname;
}

################################################
sub __new_group
{
    my( $self, $name ) = @_;
    my( $tname, $text ) = $self->__parse_name( $name );
    $self->__push( group => { __name => $tname,
                              __text => $text
                            }
                 );
}

################################################
sub __end_group
{
    my( $self, $name ) = @_;
    $self->__pop( group => $name );
}

################################################
sub __new_UI
{
    my( $self, $name, $type ) = @_;
    my( $tname, $text ) = $self->__parse_name( $name );
    $self->__push( UI => { __name => $tname,
                           __text => $text,
                           __type => $type
                         }
                 );
}

################################################
sub __end_UI
{
    my( $self, $name ) = @_;
    $self->__pop( UI => $name );
}

################################################
sub __parse_name
{
    my( $self, $name ) = @_;
    my @bits = split '/', $name, 2;
    $bits[1] ||= $name;
    return @bits;
}

################################################
sub __push
{
    my( $self, $type, $data ) = @_;
    $data->{__type} = $type;

    my $S = $self->{__read_state};
    my $C = $S->{current}[-1];
    $C->{$type}{ $data->{__name} } = $data;
    push @{ $C->{"__${type}_sorted"} }, $data->{__name};

    $self->__new_key( "$type.$data->{__name}" );
    push @{ $self->{__read_state}{current} }, $data;
}

################################################
sub __pop
{
    my( $self, $type, $name ) = @_;

    my $S = $self->{__read_state};

#    die "Trying to pop unknown $type $name" 
#            unless $C->{$type}{$name};
    my $current = pop @{ $S->{current} };
    $name =~ s/\s+$//;
    $name =~ s(/.+$)();
    die "Current $type is $current->{__name}, not $name"
            unless $current->{__name} eq $name;
}

############################################################################
## Introspection

our $AUTOLOAD;
sub AUTOLOAD
{
    my $self = shift;
    $AUTOLOAD =~ s/^PostScript::PPD:://;
    return if $AUTOLOAD eq 'DESTROY';
    return $self->get( $self, $AUTOLOAD, @_ );
}

sub get
{
    my( $self, $D, $name, $subkey ) = @_;

    return unless exists $D->{$name};
    my $ret = $D->{$name};
    if( ref $ret ) {
        if( $subkey ) {
            $D = $ret;
            $name = $subkey;
            $ret = $D->{ $name };
        }
        $ret = $self->__mk_subkey( $ret, $D, $name ) if 'HASH' eq ref $ret;
    }
    return $ret;
}

sub __mk_subkey
{
    my( $self, $value, $parent, $subkey ) = @_;
    return PostScript::PPD::Subkey->new( $value, ($parent||$self), $subkey );
}

sub Group
{
    my( $self, $name ) = @_;
    if( $name eq '_default' ) {
        my $ret = dclone $self;
        return $self->__mk_subkey( $ret, $self, $name );
    }
    return $self->get( $self->{group}, $name );
}

sub Groups
{
    my( $self ) = @_;
    my @ret = @{ $self->{__group_sorted}||[] };
    unshift @ret, '_default' if $self->{__UI_sorted};
    return @ret if wantarray;
    return \@ret;
}

############################################################################
package PostScript::PPD::Subkey;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use overload '""' => \&as_string,
    fallback => 1;

sub new
{
    my( $package, $data, $parent, $subkey ) = @_;
    my $self = bless { %$data }, $package;
    $self->{__parent} = $parent;
    $self->{__subkey} = $subkey;
    confess "Need a subkey" unless defined $subkey;
    return $self;
}

sub default
{
    my( $self ) = @_;
    die Dumper $self unless $self->{__subkey};
    return $self->{__parent}->get( "Default$self->{__subkey}" );
}

sub as_string
{
    my( $self ) = @_;
    return $self->{value} if $self->{value};
    return $self;
}

sub name
{
    my( $self ) = @_;
    return $self->{__name};
}

sub text
{
    my( $self ) = @_;
    return $self->{__text};
}

sub list
{
    my( $self ) = @_;
    return $self->{__sorted} unless wantarray;
    return @{ $self->{__sorted} };
}

sub sorted_list
{
    my( $self ) = @_;
    my @ret = sort { $self->{$a}{__text} cmp $self->{$b}{__text} }
                    @{ $self->{__sorted} };
}

our $AUTOLOAD;
sub AUTOLOAD
{
    my $self = shift;
    $AUTOLOAD =~ s/^PostScript::PPD::Subkey:://;
    return if $AUTOLOAD eq 'DESTROY';
    return $self->get( $self, $AUTOLOAD, @_ );
}

sub UIs
{
    my( $self ) = @_;
    return unless $self->{__UI_sorted};
    return @{ $self->{__UI_sorted} } if wantarray;
    return [ @{ $self->{__UI_sorted} } ];
}

sub UI
{
    my( $self, $name, $subkey ) = @_;
    return $self->get( $self->{UI}, $name, $subkey );
}

sub get
{
    my( $self, $D, $name, $subkey ) = @_;
    if( @_ == 2 ) {
        $name = $D;
        $D = $self;
    }

    if( $name =~ s/^UI\.// ) {
        $D = $self->{UI};
    }

    return unless exists $D->{$name};
    my $ret = $D->{$name};
    if( ref $ret ) {
        if( $subkey ) {
            $ret = $ret->{ $subkey };
        }
        $ret = $self->__mk_subkey( $ret, $D, $name ) if 'HASH' eq ref $ret;
    }
    return $ret;
}

sub __mk_subkey
{
    my( $self, $value, $parent, $subkey ) = @_;
    return PostScript::PPD::Subkey->new( $value, ($parent||$self), $subkey );
}

sub Dump
{
    my( $self ) = @_;
    local $self->{__parent} = $self->{__parent}{__name};
    return Dumper $self;
}


1;
__END__

=head1 NAME

PostScript::PPD - Read PostScript Printer Definition files

=head1 SYNOPSIS

    use PostScript::PPD;

    my $ppd = PostScript::PPD->new( $file );

    print "Maker: ", $ppd->Manufacturer, "\n", 
          "Mode: ", $ppd->ModelName;

    # Also:
    print "Maker: ", $ppd->get( 'Manufacturer' ), "\n", 
          "Mode: ", $ppd->get( 'ModelName' );

    # Get a list of UI groups
    my @groups = $ppd->Groups;

    # Get one UI group
    my $G = $ppd->Group( $groups[0] );

    # Get a list of UI options in that group
    my @UIs = $G->UIs;
    
    # Get one UI option
    my $ui = $G->UI( $UIs[0] );

    print "Default $groups[0] $UIs[0]: ", $ui->default;

=head1 ABSTRACT

PostScript::PPD reads and parses PostScript Printer Definition files, called
PPDs.  

=head1 DESCRIPTION

PostScript::PPD reads and parses PostScript Printer Definition files, called
PPDs.  

PPDs contain key/value tuples that describe the printer, its capabilities
and the printing options available.  The printing options are classified as
User Interface (UI) options, which are grouped into groups.

I huge database of PPDs is available from
L<http://www.linuxfoundation.org/en/OpenPrinting/Database/Foomatic>.

=head2 Schema

A PPD is a series of key/value pairs in two groups.  The first group
provides information about the printer and some of its features.  The second
group describe all the options that the PPD provides, as well as an
organised UI for setting them.  This UI is organised into a hierarchy :

    Group1
        Option1 
            key1: value
            key2: value
        Option2
            key1: value
            key2: value
    Group2
        OtherOption1 
            key1: value
            key2: value

A value can be a block of PostScript, to be executed on the printer, or
a value to be passed to C<lp -o>.

Very simple example:

    *OpenGroup: General/General
    *OpenUI *PageSize/Page Size: PickOne
    *OrderDependency: 100 AnySetup *PageSize
    *DefaultPageSize: Letter
    *PageSize Letter/US Letter: "<</PageSize[612 792]/ImagingBBox null>>setpagedevice"
    *CloseGroup: General

So if you wanted to use "US Letter" sized paper, you would use the following
command:

    lp -o PageSize=Letter


=head1 METHODS

=head2 new

    my $ppd = PostScript::PPD->new;
    my $ppd = PostScript::PPD->new( $ppdfile );

Create the object, optionally loading C<$ppdfile>.
    
=head2 load

    $ppd->load( $ppdfile );

Load a PPD file.

=head2 get

    my $value = $ppd->get( $name );
    my $value = $ppd->get( $name, $subkey );
    
    my $value = $ppd->$name();
    my $value = $ppd->$name( $subkey );

Returns one value from the PPD.

    my $ps = $ppd->CustomPageSize( 'True' );
    my $ps = $ppd->get( 'CustomPageSize', 'True' );

No, this doesn't set the I<CustomPageSize> to I<True>; it returns the PostScript
needed by the printer to set I<CustomPageSize> to I<True>.

The value returned is a L</PostScript::PPD::Subkey> object or a simple
string for information keys.

=head2 AUTOLOAD

C<AUTOLOAD> is used to implement accessor methods for all keys in the PPD.

=head2 Groups

    my @groups = $ppd->Groups;
    my $arrayref = $ppd->Groups;

Returns a list of available groups, in the order they are defined in the
PPD.

=head2 Group

    my $group = $ppd->Group( $groupname );

Returns one UI option group named C<$groupname>.  An option group would
be displayed as one tab in the printer configuration widget.

Syntatic sugar for 

    my $group = $ppd->get( group => $groupname );


=head1 PostScript::PPD::Subkey

A C<PostScript::PPD::Subkey> represents a group of UI options, a single UI
option, or the value of one UI option key.

=head2 get

Get a key from this subkey.  Itself returning either a
C<PostScript::PPD::Subkey> or a simple scalar.

=head2 AUTOLOAD

    my $text = $PageSize->Letter

Syntatic sugar for 

    my $text = $PageSize->get( 'Letter' );

=head2 as_string

    print "$subkey";
    print $subkey->get('value')||$subkey;

A PPD subkey will stringies to it's C<value>.

    

=head2 name

Returns the name of this UI group, option or key.

=head2 default

Get the default value for this UI option.  That is, for option I<PageSize>,
returns the option I<PageSize>BI<Default>.

=head2 text

Returns the text you will want to display.

=head2 UIs

Get a list of all UI options in a group.

=head2 UI

Get a single UI option from a group.

=head1 list

Returns a list of all values for this UI option.

=head1 sorted_list

Returns a list of all values for this UI option, sort by their L</text>.

=head2 Dump

Handy method to dump out the object.  Because Data::Dumper will print the
entire PPD.



=head1 SEE ALSO


L<Net::CUPS>

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn-at-cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
