package SWISH::Prog::Aggregator::Object;

use strict;
use warnings;
use base qw( SWISH::Prog::Aggregator );

use Carp;
use YAML::Syck ();
use JSON       ();
use SWISH::Prog::Utils;
use Scalar::Util qw( blessed );

__PACKAGE__->mk_accessors(
    qw( methods class title url modtime serial_format ));

our $VERSION = '0.75';

my $XMLer = Search::Tools::XML->new();    # included in Utils

=pod

=head1 NAME

SWISH::Prog::Aggregator::Object - index Perl objects with Swish-e

=head1 SYNOPSIS
    
    my $aggregator = SWISH::Prog::Aggregator::Object->new(
        methods => [qw( foo bar something something_else )],
        class   => 'MyClass',
        title   => 'mytitle',
        url     => 'myurl',
        modtime => 'mylastmod'
        indexer => SWISH::Prog::Indexer::Native->new,
    );
    
    my $data = my_func_for_fetching_data();
    # $data is either iterator or arrayref of objects
    
    $aggregator->indexer->start;
    $aggregator->crawl( $data );
    $aggregator->indexer->finish;

=head1 DESCRIPTION

SWISH::Prog::Aggregator::Object is designed for providing full-text
search for your Perl objects with Swish-e.

Since SWISH::Prog::Aggregator::Object inherits from SWISH::Prog::Aggregator,
read that documentation first. Any overridden methods are documented here.

If it seems odd at first to think of indexing objects, consider the advantages:

=over

=item sorting

Particularly for scalar method values, time for sorting objects by method 
value is greatly decreased thanks to Swish-e's pre-sorted properties.

=item SWISH::API::Object integration

If you use SWISH::API::Object, you can get a Storable-like freeze/thaw effect with
SWISH::Prog::Aggregator::Object.

=item caching

If some methods in your objects take a long while to calculate values, 
but don't change often, you can use Swish-e to cache those values, 
similar to the Cache::* modules, but in a portable, fast index.

=back

=head1 METHODS

=head2 new( I<opts> )

Create new aggregator object.

I<opts> may include:

=over

=item methods

The B<methods> param takes an array ref of method names. Each method name
will be called on each object in crawl(). Each method name will also be stored
as a PropertyName in the Swish-e index, unless you explicitly create a 
SWISH::Prog::Config object that that defines your PropertyNames.

=item class

The name of the class each object belongs to. The class value will be stored in the 
index itself for later use with SWISH::API::Object (or for your own amusement).

If not specified, the first object crawl()ed will be tested with the blessed()
function from Scalar::Util.

=item title

Which method to use as the B<swishtitle> value. Defaults to C<title>.

=item url

Which method to use as the B<swishdocpath> value. Defaults to C<url>.

=item modtime

Which method to use as the B<swishlastmodified> value. Defaults to Perl built-in
time().

=item serial_format

Which format to use in serialize(). Default is C<json>. You can also use C<yaml>.
If you don't like either of those, subclass SWISH::Prog::Aggregator::Object 
and override serialize() to provide your own format.

=back

=head2 init

Initialize object. This overrides SWISH::Prog::Aggregator init() base method.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{title}         ||= 'title';
    $self->{url}           ||= 'url';
    $self->{modtime}       ||= 'modtime';
    $self->{serial_format} ||= 'json';

    unless ( $self->{methods} ) {
        croak "methods required";
    }

    # set up the config object
    my $config = $self->{indexer}->{config};

    ( my $class_meta = $self->class ) =~ s/\W/\./g;
    $self->{_class_meta} = $class_meta;

    # make urls find-able (really should adjust WordCharacters too...)
    $config->MaxWordLimit(256) unless $config->MaxWordLimit;

    # similar to DBI, we alias top-level tag
    # so all words are find-able via swishdefault
    $config->MetaNameAlias( 'swishdefault ' . $class_meta )
        unless $config->MetaNameAlias;
    $config->MetaNames( @{ $self->methods } ) unless @{ $config->MetaNames };

    $config->PropertyNames( @{ $self->methods } )
        unless @{ $config->PropertyNames };

    # IMPORTANT to do this because whitespace matters in YAML
    # NOTE that due to swish-e cache buffering, YAML fields
    # that are longer than 10k can get seriously messed up.
    # this is a swish-e bug that should be fixed.
    $config->PropertyNamesNoStripChars( @{ $self->methods } )
        unless @{ $config->PropertyNamesNoStripChars };

    $config->IndexDescription(
        join(
            ' ', 'class:' . $self->class, 'format:' . $self->serial_format
        )
    ) unless $config->IndexDescription;

}

=head2 crawl( I<data> )

Index your objects.

I<data> should either be an array ref of objects, or an iterator object with
a C<next> method. If I<data> is an iterator, it will be used like:

 while( my $object = $data->next )
 {
     $aggregator->method_to_index( $object );
 }
 
Returns number of objects indexed.

=cut

sub crawl {
    my $self    = shift;
    my $data    = shift;
    my $indexer = $self->indexer;

    # IMPORTANT! that this not be undef since url defaults to it.
    $self->{count} = 0;

    if ( ref($data) eq 'ARRAY' ) {

        $self->{class} ||= blessed( $data->[0] );
        for my $o (@$data) {
            $indexer->process( $self->get_doc($o) );
            $self->_increment_count;
        }

    }
    elsif ( ref($data) && $data->can('next') ) {
        my $first = $data->next;
        $self->{class} ||= blessed($first);
        $indexer->process( $self->get_doc($first) );

        while ( my $o = $data->next ) {
            $indexer->process( $self->get_doc($o) );
            $self->_increment_count;
        }
    }
    else {
        croak "\$data $data doesn't look like it's in the expected format";
    }

    return $self->{count};
}

=head2 get_doc( I<object> )

Returns a doc_class() instance representing I<object>.

=cut

sub get_doc {
    my $self = shift;
    my $object = shift or croak "need object";

    my $titlemeth   = $self->{title};
    my $urlmeth     = $self->{url};
    my $modtimemeth = $self->{modtime};

    my $title
        = $object->can($titlemeth) ? $object->$titlemeth : '[ no title ]';

    my $url
        = $object->can($urlmeth)
        ? $object->$urlmeth
        : $self->{count};

    my $modtime
        = $object->can($modtimemeth)
        ? $object->$modtimemeth
        : time();

    my $xml = $self->_obj2xml( $self->{_class_meta}, $object, $title );

    my $doc = $self->doc_class->new(
        content => $xml,
        url     => $url,
        modtime => $modtime,
        parser  => 'XML*',
        type    => 'application/xml',
        data    => $object
    );

    $self->debug and print $doc;

    return $doc;
}

sub _obj2xml {
    my ( $self, $class, $o, $title ) = @_;

    my $xml
        = $XMLer->start_tag($class)
        . "<swishtitle>"
        . $XMLer->utf8_safe($title)
        . "</swishtitle>";

    for my $m ( @{ $self->methods } ) {
        my $v = $self->serialize( $o, $m );

        my @x = (
            $XMLer->start_tag($m), $XMLer->utf8_safe($v), $XMLer->end_tag($m)
        );

        $xml .= join( '', @x );
    }
    $xml .= $XMLer->end_tag($class);

    $self->debug and print STDOUT $xml . "\n";

    return $xml;
}

=head2 serialize( I<object>, I<method_name> )

Returns a serialized (stringified) version of the return value of I<method_name>.
If the return value is already a scalar string (i.e., if ref() returns false)
then the return value is returned untouched. Otherwise, the return value is serialized
with either JSON or YAML, depending on how you configured C<serial_format> in new().

If you subclass SWISH::Prog::Aggregator::Object, 
then you can (of course) return whatever serialized format you prefer.

=cut

sub serialize {
    my $self = shift;
    my ( $o, $m ) = @_;
    my $v = $o->$m;
    unless ( ref $v ) {
        return $v;
    }
    else {
        if ( $self->serial_format eq 'json' ) {
            return JSON->new->convert_blessed(1)->allow_blessed(1)
                ->encode($v);
        }
        elsif ( $self->serial_format eq 'yaml' ) {
            return YAML::Syck::Dump($v);
        }
        else {
            croak "unknown serial_format: " . $self->serial_format;
        }
    }

}

1;

__END__


=head1 REQUIREMENTS

L<SWISH::Prog>, L<YAML::Syck>, L<JSON::Syck>

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
