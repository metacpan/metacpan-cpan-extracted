package SWISH::Prog::Doc;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( SWISH::Prog::Class );
use overload(
    '""'     => \&as_string,
    'bool'   => sub {1},
    fallback => 1,
);

use SWISH::Prog::Headers;

our $VERSION = '0.75';

__PACKAGE__->mk_accessors(
    qw( url modtime type parser content action size charset data version ));

my $default_version = $ENV{SWISH3} ? 3 : 2;

my ( $locale, $lang, $charset );
{

    # inside a block to reduce impact on any regex
    use POSIX qw(locale_h);
    use locale;

    $locale = setlocale(LC_CTYPE);
    ( $lang, $charset ) = split( m/\./, $locale );
    $charset ||= 'iso-8859-1';
}

=pod

=head1 NAME

SWISH::Prog::Doc - Document object class for passing to SWISH::Prog::Indexer

=head1 SYNOPSIS

  # subclass SWISH::Prog::Doc
  # and override filter() method
  
  package MyDoc;
  use base qw( SWISH::Prog::Doc );
  
  sub filter {
    my $doc = shift;
    
    # alter url
    my $url = $doc->url;
    $url =~ s/my.foo.com/my.bar.org/;
    $doc->url( $url );
    
    # alter content
    my $buf = $doc->content;
    $buf =~ s/foo/bar/gi;
    $doc->content( $buf );
  }
  
  1;

=head1 DESCRIPTION

SWISH::Prog::Doc is the base class for Doc objects in the SWISH::Prog
framework. Doc objects are created by SWISH::Prog::Aggregator classes
and processed by SWISH::Prog::Indexer classes.

You can subclass SWISH::Prog::Doc and add a filter() method to alter
the values of the Doc object before it is indexed.

=head1 METHODS

All of the following methods may be overridden when subclassing
this module, but the recommendation is to override only filter().

=head2 new

Instantiate Doc object.

All of the following params are also available as accessors/mutators.

=over

=item url

=item type

=item content

=item parser

=item modtime

=item size

=item action

=item debug

=item charset

=item data

=item version

Swish-e 2.x or Swish3 style headers. Value should be C<2> or C<3>.
Default is C<2>.

=back

=cut

=head2 init

Calls filter() on object.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{charset} ||= $charset;
    $self->{version} ||= $default_version;
    $self->filter();
    return $self;
}

=head2 filter

Override this method to alter the values in the object prior to it
being process()ed by the Indexer.

The default is to do nothing.

This method can also be set using the filter() callback in SWISH::Prog->new().

=cut

sub filter { }

=head2 as_string

Return the Doc object rendered as a scalar string, ready to be indexed.
This will include the proper headers. See SWISH::Prog::Headers.

B<NOTE:> as_string() is also used if you use a Doc object as a string.
Example:

 print $doc->as_string;     # one way
 print $doc;                # same thing

=cut

# TODO cache this higher up? how else to set debug??
my $headers = SWISH::Prog::Headers->new();

sub as_string {
    my $self = shift;

    # we ignore size() and let Headers compute it based on actual content()
    return $headers->head(
        $self->content,
        {   url     => $self->url,
            modtime => $self->modtime,
            type    => $self->type,
            action  => $self->action,
            parser  => $self->parser,
            version => $self->version,
        }
    ) . $self->content;

}

1;

__END__

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
