package SWISH::Prog::InvIndex::Meta;
use strict;
use warnings;
use base qw( SWISH::Prog::Class );
use Carp;
use XML::Simple;
use SWISH::3 qw( :constants );

our $VERSION = '0.75';

__PACKAGE__->mk_accessors(qw( invindex ));
__PACKAGE__->mk_ro_accessors(qw( file data ));

# index metadata. read/write libswish3 file xml format.
#

sub swish_header_file {
    return 'swish.xml';
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{file} ||= $self->invindex->path->file( $self->swish_header_file );
    if ( !-s $self->{file} ) {
        confess("No such file: $self->{file}");
    }
    $self->{data} = XMLin("$self->{file}");

    #warn Data::Dump::dump( $self->{data} );

    my $props = $self->{data}->{PropertyNames};

    # start with the built-in PropertyNames,
    # which cannot be aliases for anything.
    my %propnames = map { $_ => { alias_for => undef } }
        keys %{ SWISH_DOC_PROP_MAP() };
    $propnames{swishrank} = { alias_for => undef };
    $propnames{score}     = { alias_for => undef };
    my @pure_props;
    my %prop_map;
    for my $name ( keys %$props ) {
        $propnames{$name} = { alias_for => undef };
        if ( exists $props->{$name}->{alias_for} ) {
            $propnames{$name}->{alias_for} = $props->{$name}->{alias_for};
            $prop_map{$name} = $props->{$name}->{alias_for};
        }
        else {
            push @pure_props, $name;
        }
    }
    $self->{_propnames}  = \%propnames;
    $self->{_pure_props} = \@pure_props;
    $self->{_prop_map}   = \%prop_map;
}

sub get_properties {
    return shift->{_propnames};
}

sub get_property_map {
    return shift->{_prop_map};
}

sub get_pure_properties {
    return shift->{_pure_props};
}

sub AUTOLOAD {
    my $self   = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*://;
    return if $method eq 'DESTROY';

    if ( exists $self->{data}->{$method} ) {
        return $self->{data}->{$method};
    }
    croak "no such Meta key: $method";
}

1;

__END__

=pod

=head1 NAME

SWISH::Prog::InvIndex::Meta - read/write InvIndex metadata

=head1 SYNOPSIS

 use Data::Dump qw( dump );
 use SWISH::Prog::InvIndex;
 my $index = SWISH::Prog::InvIndex->new(path => 'path/to/index');
 my $meta = $index->meta;
 for my $key (keys %{ $meta->data }) {
    dump $meta->$key;
 }
 
=head1 DESCRIPTION

A SWISH::Prog::InvIndex::Meta object represents the metadata for an
InvIndex. It supports the Swish3 C<swish.xml> header file format only
at this time.

=head1 METHODS

=head2 swish_header_file

Class or object method. Returns the basename of the header file.
Default is C<swish.xml>.

=head2 init

Read and initialize the swish_header_file().

=head2 data

The contents of the header file as a Perl hashref. This is a read-only
accessor.

=head2 file

The full path to the swish_header_file() file. This is a read-only accessor.

=head2 invindex

The SWISH::Prog::InvIndex object which the SWISH::Prog::InvIndex::Meta
object represents.

=head2 get_properties

Returns hashref of PropertyNames with aliases resolved.

=head2 get_pure_properties

Returns arrayref of PropertyName values, excluding aliases.

=head2 get_property_map

Returns hashref of alias names to pure names.

=cut

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

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
