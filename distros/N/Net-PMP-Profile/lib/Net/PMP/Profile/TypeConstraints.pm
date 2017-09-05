package Net::PMP::Profile::TypeConstraints;
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.102';

# The Net::PMP::Type::* prefix is used for all our type constraints
# to avoid stepping on anyone's toes

# locales
use Locale::Language;
my %all_langs = map { $_ => $_ } all_language_codes();
subtype 'Net::PMP::Type::ISO6391' => as 'Str' =>
    where { length($_) == 2 and exists $all_langs{$_} } =>
    message {"The provided hreflang ($_) is not a valid ISO639-1 value."};

# datetimes
use DateTime::Format::Strptime;
use DateTime::Format::DateParse;
my $coerce_datetime = sub {
    my $thing = shift;
    my $iso8601_formatter
        = DateTime::Format::Strptime->new( pattern => '%FT%T.%3NZ' );
    if ( blessed $thing) {
        if ( $thing->isa('DateTime') ) {

            # enforce UTC
            $thing->set_time_zone('UTC');
            $thing->set_formatter($iso8601_formatter);
            return $thing;
        }
        confess "$thing is not a DateTime object";
    }
    else {
        my $dt = DateTime::Format::DateParse->parse_datetime($thing);
        if ( !$dt ) {
            confess "Invalid date format: $thing";
        }

        # enforce UTC
        $dt->set_time_zone('UTC');
        $dt->set_formatter($iso8601_formatter);
        return $dt;
    }
};
subtype 'Net::PMP::Type::DateTimeOrStr' => as class_type('DateTime');
coerce 'Net::PMP::Type::DateTimeOrStr'  => from 'Object' =>
    via { $coerce_datetime->($_) } => from 'Str' =>
    via { $coerce_datetime->($_) };
subtype 'Net::PMP::Type::ValidDates' => as
    'HashRef[Net::PMP::Type::DateTimeOrStr]';
coerce 'Net::PMP::Type::ValidDates' => from 'HashRef' => via {
    if ( !exists $_->{to} or !exists $_->{from} ) {
        confess "ValidDates must contain 'to' and 'from' keys";
    }
    $_->{to}   = $coerce_datetime->( $_->{to} );
    $_->{from} = $coerce_datetime->( $_->{from} );
    $_;
};

# Content types
use Media::Type::Simple qw(is_type);

#confess "MediaType defined!";
subtype 'Net::PMP::Type::MediaType' => as 'Str' => where {
    is_type($_);
} => message {
    "The value ($_) does not appear to be a valid media type.";
};

# MediaEnclosure
my $coerce_enclosure = sub {

    # defer till runtime to avoid circular dependency
    require Net::PMP::Profile::MediaEnclosure;

    if ( ref( $_[0] ) eq 'HASH' ) {
        return Net::PMP::Profile::MediaEnclosure->new( $_[0] );
    }
    else { return $_[0]; }
};
subtype 'Net::PMP::Type::MediaEnclosure' =>
    as class_type('Net::PMP::Profile::MediaEnclosure');
coerce 'Net::PMP::Type::MediaEnclosure' => from 'Any' =>
    via { $coerce_enclosure->($_) };
subtype 'Net::PMP::Type::MediaEnclosures' => as
    'ArrayRef[Net::PMP::Type::MediaEnclosure]';
coerce 'Net::PMP::Type::MediaEnclosures' => from 'ArrayRef[HashRef]' => via {
    [ map { $coerce_enclosure->($_) } @$_ ];
} => from 'HashRef' => via { [ $coerce_enclosure->($_) ] };

no Moose::Util::TypeConstraints;

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::PMP::Profile::TypeConstraints - enforce attribute values

=head1 SYNOPSIS

 package My::Class;
 use Moose;
 use Net::PMP::Profile::TypeConstraints;

 # provide validation checking
 has 'uri' => (isa => 'Net::PMP::Type::Href');

 1;

=head1 DESCRIPTION

Net::PMP::Profile::TypeConstraints defines validation constraints for Net::PMP classes.
This is a utility class defining types with L<Moose::Util::TypeConstraints>
in the C<Net::PMP::Type> namespace.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP-Profile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::CollectionDoc::Link


You can also look for information at:

=over 4

=item RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP-Profile>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP-Profile>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP-Profile>

=item Search CPAN

L<http://search.cpan.org/dist/Net-PMP-Profile/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut

