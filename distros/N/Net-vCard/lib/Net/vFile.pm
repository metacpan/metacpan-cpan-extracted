package Net::vFile;

use strict;
use warnings;
use Encode qw(decode is_utf8);

# This stuff will be in Net::vCalendar
# use DateTime::Format::ICal;

=head1 NAME

Net::vFile - Generic module which can read and write "vFile" files such as vCard (RFC 2426) and vCalendar (RFC 2445).
The result of loading this data is a collection of objects which will grant you easy access to the properties. Then 
the module can write your objects back to a data file.

=head1 SYNOPIS

    use Net::vCard;

    my $cards = Net::vCard->loadFile( "foo.vCard", "blort.vCard", "whee.vCard" );

    foreach my $card (@$cards) {
        spam ( $card->EMAIL('default') );
    }

=head1 DETAILS

The way this processor works is that it reads the vFile line by line.

1 - BEGIN:(.*) tag

   $1 is looked up in classMap; class is loaded; new object of this class is created
   ie/ $Net::vFile::classMap{'VCARD'}="Net::vCard";
       $object=$classMap{'VCARD'}->new;

    n.b. classMap is a package variable for Net::vFile

2 - All lines are read and stored until a BEGIN tag (goto 1) or END tag (goto 3) is reached

3 - END:(.*) tag

   Signals that all entry data has been obtained and now the rows of data are processed

4 - Data is concatenated - thanks to Net::iCal for the strategy; the tag label and data are obtained

5 - The data handler is identified via $object->varHandler->{$label}

    There are some generic handlers for common data types such as simple strings, dates, etc. More
    elaborate data types such as N, ADR, etc. need special treatment and are declared explititly
    in classes as "load_XXX" such as "load_N"

You should be able to override and extend the processing by taking Net::vCard.pm as your example
and adjusting as necessary.

The resulting data structure is a bit bulky - but is such that it can express vCard data completely and
reliably

  Put in a dump of a vCard here

=head1 DEPENDENCIES

 DateTime::Format::ICal

=over 4

=item \@objects = loadFile( filename [, filename ... ] )

Loads the vFiles and returns an array of objects

=cut

sub loadFile {

	my $self=shift;
       $self=$self->new unless ref($self);

	foreach my $fn (@_) {
        my $fh;
        if (open $fh, $fn) {
            until (eof $fh) {
                $self->load($fh, $fn);
            }
        } else {
            warn "Cannot open $fn\n";
            next;
        }
    	close $fh;
	}

    # Usually people only load one type - VCARD
    #   - which will be represented by a single top level
    #     hash entry
    # However it is not impossible to load VCARD, VCALENDAR and more all at once
    #   - in which case they get a scalar hashref
    
    if ( scalar values %$self == 0 ) {
        return undef;
    }

    if ( scalar values %$self == 1 ) {
        return (values %$self)[0];
    } else {
        return $self;
    }

}

# Classes inject their desired mappings
our %classMap=(

    # VCARD     => "Net::vCard",

    # VCALENDAR => "Net::vCalendar",
    # VALARM    => "Net::vCalendar::vAlarm",
    # VEVENT    => "Net::vCalendar::vEvent",
    # VTODO     => "Net::vCalendar::vTodo",

);

=item $object = class->new

Make a new object

=cut

sub new {

	my $class = ref($_[0]) ? ref(shift) : shift;

	my $self=bless {}, $class;

	return $self;

}

=item \@objects = Class->load( filehandle )

Loads data from file handle and creates objects as necessary

=cut


sub load {

	my ($class, $self);
	if (ref ($_[0])) {
		$self=shift;
		$class=ref($self);
	}
	else {
		$class=shift;
		$self=$class->new;
	}
    my $fh  =shift;
	my $parent=shift;

	$self->{'_parent'}=$parent if ref $parent;

    my @lines=();
    my $varHandler=$class->varHandler;

    my $decoder;
    $_ = <$fh>;
    $decoder=Encode::find_encoding("UTF-8");
    if ( /^\000/ ) {
        $decoder=Encode::find_encoding("UTF-16BE");
    }
    if ( /^[^\000]\000/ ) {
        $decoder=Encode::find_encoding("UTF-16LE");
    }

    my $thing="";
    while ( $_ ) {

        my $line = $decoder->decode($_);
        $line =~ s/[\r\n]+$//;

        if ($line =~ /^BEGIN:(.+)/) {
            $thing=$1;
            my $subclass= $classMap{uc $thing} || die "Don't know how to load ${thing}s\n";
            eval "use $subclass"; die $@ if $@;
            push @{$self->{$thing}}, $subclass->new->load($fh, $self);
            next;
        } 

        last if $line =~ /^END:${thing}/;

        push @lines, $line;

        $_ = <$fh>;
    }

    while ( @lines ) {

        my $line = shift @lines;
        while ( @lines && $lines[0] =~ /^\s(.*)/ ) {
            $line .= $1;
            shift @lines;
        }

        # Non-typed line data 
        if ( $line =~ /^([\w\-]+):(.*)/ && exists $varHandler->{$1} ) {
            my $h="load_$varHandler->{$1}";
            $self->$h($1, undef, $2);
            next;
        }

        # Typed line data
        if ( $line =~ /^([\w\-]+);([^:]*):(.*)/  && exists $varHandler->{$1} ) {

            my $h="load_$varHandler->{$1}";
            my ($var, $data)=($1, $3);

            my %attr=();
            map { /([^=]+)=(.*)/; push @{$attr{uc $1}}, $2 } split (/(?<!\\);/, $2);

            # XXX I want to split up the attributes here
            $self->$h($var, \%attr, $data);
            next;
        }

        # X-values
        if ( $line =~ /^(X-[\w\-]+);?([^:]*):(.*)/ ) {

            my ($var, $data)=($1, $3);

            my %attr=();
            map { /([^=]+)=(.*)/; push @{$attr{uc $1}}, $2 } split (/(?<!\\);/, $2);

            $self->load_singleTextTyped($var, \%attr, $data);
            next;
        }

        $self->error( $line );

    }

    return $self;

}

=item $object->error

Called when a line cannot be successfully decoded

=back

=cut

sub error  { warn ref($_[0]) . " ERRORLINE: $_[1]\n"; }

=head1 DATA HANDLERS

=over 4

=item varHandler

Returns a hash ref mapping the item label to a handler name. Ie:

   {
        'FN'          => 'singleText',
        'N'           => 'N',
        'NICKNAME'    => 'multipleText',
        'PHOTO'       => 'singleBinary',
        'BDAY'        => 'singleText',
        'ADR'         => 'ADR',
    };

=cut
 
sub varHandler {
    return {};
}

=item typeDefault

Additional information where handlers require type info. Such as ADR - is this
a home, postal, or whatever? If not supplied the RFC specifies what types they should
default to.

     from vCard:

     {
        'ADR'     => [ qw(intl postal parcel work) ],
        'LABEL'   => [ qw(intl postal parcel work) ],
        'TEL'     => [ qw(voice) ],
        'EMAIL'   => [ qw(internet) ],
    };

=cut

sub typeDefault {
    return {};
}

=item load_singleText

Loads a single text item with no processing other than unescape text

=cut

sub load_singleText { 

	my $val=$_[3];
	$val=~s/\\([\n,])/$1/gs;
    # $val=~s/\\n/\n/gs;
	$_[0]->{$_[1]}{'val'}=$val;
	$_[0]->{$_[1]}{'_attr'}=$_[2] if $_[2];

}

=item _singleText

Accessor for single text items

=cut

sub _singleText {

    if ($_[2]) {
        $_[0]->{$_[1]}{'val'}=$_[0];
    }
    return $_[0]->{$_[1]}{'val'};

}

=item load_singleDate

Loads a date creating a DateTime::Format::ICal object. Thanks Dave!

=cut

sub load_singleDate { 

	my $val=$_[3];
    eval {
	    $_[0]->{$_[1]}{'val'}=DateTime::Format::ICal->parse_datetime( iso8601 => $val );
    }; if ($@) {
        warn "$val; $@\n";
    }
	$_[0]->{$_[1]}{'_attr'}=$_[2] if $_[2];

}

=item load_singleDuration

Loads a data duration using DateTime::Format::ICal.

=cut

sub load_singleDuration { 

	my $val=$_[3];

    eval {
	    $_[0]->{$_[1]}{'val'}=DateTime::Format::ICal->parse_duration( $val );
    }; if ($@) {
        warn "$val; $@\n";
    }

	$_[0]->{$_[1]}{'_attr'}=$_[2] if $_[2];

}

=item load_multipleText

This is text that is separated by commas. The text is then unescaped. An array
of items is created.

=cut

sub load_multipleText {

	my @vals=split /(?<!\\),/, $_[3];
	map { s/\\,/,/ } @vals;

	$_[0]->{$_[1]}{'val'}=\@vals;
	$_[0]->{$_[1]}{'_attr'}=$_[2] if $_[2];

}

=item load_singleTextType

Load text that has a type attribute. Each text of different type attributes
will be handled independantly in as a hash entry. If no type attribute is supplied
then the typeDefaults types will be used. A line can have multiple types. In the
case where multiple types have the same value "_alias" indicators are created.
The preferred type is stored in "_pref"

=cut

sub load_singleTextTyped {
    
    my $typeDefault=$_[0]->typeDefault;

    my $attr=$_[2];

    my %type=();
    map { map { $type{lc $_}=1 } split /,/, $_ } @{$attr->{TYPE}};
    map { $type{ lc $_ }=1 } @{$typeDefault->{$_[1]}} unless scalar(keys %type);

    my $pref=0;
    if ($type{pref}) {
        delete $type{pref};
        $pref=1;
    }

    my @types=sort keys %type;
    my $actual=@types ? shift @types : "default";

    $_[0]->{$_[1]}{$actual}=$_[3];

    $_[0]->{$_[1]}{_pref}=$actual if $pref;
    delete $_[0]->{$_[1]}{_alias}{$actual} if exists $_[0]->{$_[1]}{_alias} && $_[0]->{$_[1]}{_alias}{$actual};
    map { $_[0]->{$_[1]}{_alias}{$_}=$actual unless exists $_[0]->{$_[1]}{$_} } @types;

	$_[0]->{$_[1]}{'_attr'}{$actual}=$_[2] if $_[2];

}

=item load_singleBinary

Not done as I don't have example data yet.

=cut

sub load_singleBinary {
	die "_singleBinary not done\n";
}


# sub setDefault {
# $_[0]->{"_setDefault"}=$_[1] if exists $_[1];
# return $_[0]->{"_setDefault"} if exists $_[0]->{"_setDefault"};
# die ref($_[0]) . " does not have a default set to iterate\n";
# }

=back

=head1 SUPPORT

For technical support please email to jlawrenc@cpan.org ... 
for faster service please include "Net::vFile" and "help" in your subject line.

=head1 AUTHOR

 Jay J. Lawrence - jlawrenc@cpan.org
 Infonium Inc., Canada
 http://www.infonium.ca/

=head1 COPYRIGHT

Copyright (c) 2003 Jay J. Lawrence, Infonium Inc. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

 Net::iCal - whose loading code inspired me for mine

=head1 SEE ALSO

RFC 2426, Net::iCal

=cut

1;

