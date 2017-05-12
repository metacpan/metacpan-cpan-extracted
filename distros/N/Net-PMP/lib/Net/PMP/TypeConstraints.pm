package Net::PMP::TypeConstraints;
use Moose;
use Moose::Util::TypeConstraints;
use Data::Dump qw( dump );

our $VERSION = '0.006';

# The Net::PMP::Type::* prefix is used for all our type constraints
# to avoid stepping on anyone's toes

# links
my $coerce_link = sub {

    # defer till runtime to avoid circular dependency
    require Net::PMP::CollectionDoc::Link;

    if ( ref( $_[0] ) eq 'HASH' ) {
        return Net::PMP::CollectionDoc::Link->new( $_[0] );
    }
    elsif ( blessed $_[0] and $_[0]->isa('URI') ) {
        return Net::PMP::CollectionDoc::Link->new( href => $_[0] . "" );
    }
    elsif ( blessed $_[0] ) {
        return $_[0];
    }
    else {
        return Net::PMP::CollectionDoc::Link->new( href => $_[0] );
    }
};
subtype 'Net::PMP::Type::Link' =>
    as class_type('Net::PMP::CollectionDoc::Link') => message {
    'Value ' . dump($_) . ' is not a valid Net::PMP::CollectionDoc::Link';
    };
coerce 'Net::PMP::Type::Link' => from 'Any' => via { $coerce_link->($_) };
subtype 'Net::PMP::Type::Links' => as 'ArrayRef[Net::PMP::Type::Link]' =>
    message {
    'Value '
        . dump($_)
        . ' is not a valid ArrayRef of type Net::PMP::Type::Link';
    };
coerce 'Net::PMP::Type::Links' => from 'ArrayRef' => via {
    [ map { $coerce_link->($_) } @$_ ];
} => from 'HashRef' => via { [ $coerce_link->($_) ] } => from 'Any' =>
    via { [ $coerce_link->($_) ] };

# permission links (special link case)
my $coerce_permission = sub {

    # defer till runtime to avoid circular dependency
    require Net::PMP::CollectionDoc::Permission;

    if ( ref( $_[0] ) eq 'HASH' ) {
        return Net::PMP::CollectionDoc::Permission->new( $_[0] );
    }
    elsif ( blessed $_[0] ) {
        return $_[0];
    }
    else {
        return Net::PMP::CollectionDoc::Permission->new( href => $_[0] );
    }
};
subtype 'Net::PMP::Type::Permission' =>
    as class_type('Net::PMP::CollectionDoc::Permission');
coerce 'Net::PMP::Type::Permission' => from 'Any' =>
    via { $coerce_permission->($_) };
subtype 'Net::PMP::Type::Permissions' => as
    'ArrayRef[Net::PMP::Type::Permission]';
coerce 'Net::PMP::Type::Permissions' => from 'ArrayRef' => via {
    [ map { $coerce_permission->($_) } @$_ ];
} => from 'HashRef' => via { [ $coerce_permission->($_) ] } => from 'Any' =>
    via { [ $coerce_permission->($_) ] };

# URIs
use Data::Validate::URI qw(is_uri);
subtype 'Net::PMP::Type::Href' => as 'Str' => where {
    is_uri($_);
} => message { "Value " . dump($_) . " is not a valid href." };
coerce 'Net::PMP::Type::Href' => from 'Object' => via {"$_"};

# GUIDs
subtype 'Net::PMP::Type::GUID' => as 'Str' => where {
    m/^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/;
} => message {"Value ($_) does not look like a valid guid."};

no Moose::Util::TypeConstraints;

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::PMP::CollectionDoc::Link - link from a Net::PMP::CollectionDoc::Links object

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

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-PMP/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut

