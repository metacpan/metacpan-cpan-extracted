package SPOPS::Tool::DateConvert;

# $Id: DateConvert.pm,v 1.10 2004/02/26 01:01:37 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;

my $log = get_logger();

my $DEFAULT_DATE_CLASS  = 'DateTime';
my $DEFAULT_DATE_FORMAT = '%Y-%m-%d %H:%M:%S';

my %REQUIRED = ();

sub ruleset_factory {
    my ( $class, $ruleset ) = @_;
    push @{ $ruleset->{post_fetch_action} }, \&convert_to_object;
    push @{ $ruleset->{pre_save_action} }, \&convert_to_string;
    push @{ $ruleset->{post_save_action} }, \&convert_to_object;
    $log->is_info &&
        $log->info( "DateConvert added post_fetch, pre/post_save rules to [$class]" );
    return __PACKAGE__;
}

sub convert_to_object {
    my ( $self ) = @_;
    my ( $date_fields, $date_class ) = _init( $self );
    unless ( ref $date_fields eq 'ARRAY' and scalar @{ $date_fields } ) {
        $log->warn( "Using date conversion for ", ref( $self ), " but there ",
            "are no date fields in 'convert_date_field'" );
        return 1;
    }
    foreach my $field ( @{ $date_fields } ) {
        $self->{ $field } = eval {
            _create_date_object( $self, $date_class, $self->{ $field } )
        };
        return undef if ( $@ );
    }
    return 1;
}

sub _create_date_object {
    my ( $self, $date_class, $date ) = @_;
    return undef unless ( $date );
    if ( ref $date eq $date_class ) {
        return $date;
    }
    if ( $date_class eq 'Class::Date' ) {
        return Class::Date->new( $date );
    }
    elsif ( $date_class eq 'Time::Piece' ) {
        my $date_format = $self->CONFIG->{convert_date_format}
                          || $DEFAULT_DATE_FORMAT;
        return Time::Piece->strptime( $date, $date_format );
    }
    elsif ( $date_class eq 'DateTime' ) {
        my $date_format = $self->CONFIG->{convert_date_format}
                          || $DEFAULT_DATE_FORMAT;
        return DateTime::Format::Strptime->new( pattern => $date_format )
                                         ->parse_datetime( $date );
    }
    die "Given date class [$date_class] is not supported for conversion\n";
}

sub convert_to_string {
    my ( $self ) = @_;
    my ( $date_fields, $date_class ) = _init( $self );
    unless ( ref $date_fields eq 'ARRAY' and scalar @{ $date_fields } ) {
        $log->warn( "Using date conversion for ", ref( $self ), " but there ",
            "are no date fields in 'convert_date_field'" );
        return 1;
    }
    foreach my $field ( @{ $date_fields } ) {
        $self->{ $field } = _create_date_string( $self, $date_class, $self->{ $field } );
    }
    return 1;
}

sub _create_date_string {
    my ( $self, $date_class, $date_object ) = @_;

    # NULLs are ok...

    unless ( $date_object ) {
        return undef;
    }

    # Strings are semi-ok...

    unless ( ref( $date_object ) ) {
        $log->info( "Expected date object of type '$date_class' but item ",
                    "is not a reference, which probably means it's a ",
                    "string representation of a date ($date_object). ",
                    "Hope it's in the right format, it's going in as is." );
        return $date_object
    }

    # ... but getting something that's not an object when we expect
    # something is a different matter and deserves a warning

    unless ( ref( $date_object ) eq $date_class ) {
        $log->warn( "Expected date object of type '$date_class' but ",
               "got '", ref( $date_object ), "'; not converting." );
        return undef;
    }
    my $date_format = $self->CONFIG->{convert_date_format}
                      || $DEFAULT_DATE_FORMAT;
    if ( $date_class eq 'Class::Date' ) {
        return $date_object->strftime( $date_format );
    }
    elsif ( $date_class eq 'Time::Piece' ) {
        return $date_object->strftime( $date_format );
    }
    elsif ( $date_class eq 'DateTime' ) {
        return $date_object->strftime( $date_format );
    }
    die "Given date class [$date_class] is not supported for conversion\n";
}

sub _init {
    my ( $self ) = @_;
    my $date_fields = $self->CONFIG->{convert_date_field};
    return () unless ( ref $date_fields eq 'ARRAY'
                           and scalar @{ $date_fields } );
    my $date_class = $self->CONFIG->{convert_date_class}
                     || $DEFAULT_DATE_CLASS;
    unless ( $REQUIRED{ $date_class } ) {
        _require_class( $date_class );
    }
    return ( $date_fields, $date_class );
}

sub _require_class {
    my ( $date_class ) = @_;
    eval "require $date_class";
    if ( $@ ) {
        die "Cannot bring in date library $date_class: $@\n";
    }
    $REQUIRED{ $date_class }++;

    # HACK!
    if ( $date_class eq 'DateTime' ) {
        require DateTime::Format::Strptime;
        $REQUIRED{ 'DateTime::Format::Strptime' }++;
    }
}

1;

__END__

=head1 NAME

SPOPS::Tool::DateConvert - Convert dates to objects to/from your datastore

=head1 SYNOPSIS

 # Class configuration with date convertion rule and metadata
 
 my $spops = {
    class               => 'This::Class',
    isa                 => [ 'SPOPS::DBI' ],
    field               => [ 'email', 'language', 'birthtime' ],
    id_field            => 'email',
    base_table          => 'test_table',
    rules_from          => [ 'SPOPS::Tool::DateConvert' ],
    convert_date_field  => [ 'birthtime' ],
    convert_date_class  => 'Time::Piece',
    convert_date_format => '%Y-%m-%d %H:%M:%S',
 };
 SPOPS::Initialize->process({ config => { test => $spops } });
 
 my $item = This::Class->fetch(55);
 print "Birthdate field isa: ", ref( $item->{birthtime} ), "\n";
 --> Birthdate field isa: Time::Piece
 
 # Format some other way
 
 print "Birthday occurred on day ", $item->{birthtime}->strftime( '%j' ),
       "which was a ", $item->{birthtime}->strftime( '%A' ), "\n";
 
 # When creating a new object, just set the correct type of object as
 # the field value
 
 my $newborn = This::Class->new({ email     => 'foo@bar.com',
                                  language  => 'en',
                                  birthtime => Time::Piece->new });
 $newborn->save;

=head1 DESCRIPTION

This SPOPS tool converts data coming from the database into a date
object, and translates the date object into the proper format before
it's put back into the database.

=head1 CONFIGURATION

This tool uses three configuration fields:

B<convert_date_field> (\@)

An arrayref of fields that will be converted.

If not specified or if empty no action will be taken.

B<convert_date_class> ($)

Class for date object to be instantiated. Supported classes are:

=over 4

=item *

L<DateTime|DateTime> (along with supporting parse class
L<DateTime::Format::Strptime|DateTime::Format::Strptime>)

=item *

L<Time::Piece|Time::Piece>

=item *

L<Class::Date|Class::Date>.

=back

If not specified, 'DateTime' will be used.

B<convert_date_format> ($)

Format (in L<strftime> format) for date conversions. All
implementations will likely use this for converting the object to a
string. Some implementations (like L<Time::Piece|Time::Piece> and
L<DateTime|DateTime>) will use this for parsing the date from the
database into the date object as well.

If not specified, '%Y-%m-%d %H:%M:%S' will be used.

=head1 IMPLEMENTATIONS

L<DateTime|DateTime>

Uses the L<DateTime::Format::Strptime|DateTime::Format::Strptime> and
C<convert_date_format> to translate the date from the database.

Uses the L<DateTime|DateTime> C<strftime()> method from along with
C<convert_date_format> configuration to translate the date into a
string.

L<Time::Piece|Time::Piece>

Uses the C<strptime()> method and C<convert_date_format> to translate
the date from the database.

Uses the C<strftime()> method along with C<convert_date_format>
configuration to translate the date into a string.

L<Class::Date|Class::Date>

Uses the C<new()> method to translate the date from the database.

Uses the C<strftime()> method along with C<convert_date_format>
configuration to translate the date into a string.

=head1 TO DO

If necessary, make this a factory and refactor if clauses into
subclasses for the different implementations.

=head1 SEE ALSO

L<DateTime|DateTime>

L<DateTime::Format::Strptime|DateTimee::Format::Strptime>

L<Time::Piece|Time::Piece>

L<Class::Date|Class::Date>

=head1 AUTHOR

Chris Winters E<lt>chris@cwinters.comE<gt>
