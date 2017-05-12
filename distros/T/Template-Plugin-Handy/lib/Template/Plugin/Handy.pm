package Template::Plugin::Handy;

use warnings;
use strict;
use base qw( Template::Plugin::VMethods );
use Carp;
use Data::Dump;
use JSON::XS;

our $VERSION = '0.003';

our @SCALAR_OPS = our @LIST_OPS = our @HASH_OPS
    = qw( as_json dump_stderr dump_data );
push( @SCALAR_OPS, qw( increment decrement ) );
push( @LIST_OPS,   qw( sort_by ) );
push( @HASH_OPS,   qw( sort_by ) );

=head1 NAME

Template::Plugin::Handy - handy vmethods for Template Toolkit

=head1 SYNOPSIS

 [% USE Handy;
    mything.dump_data;
    mything.dump_stderr;
    mything.as_json;
 %]
  

=head1 DESCRIPTION

Handy virtual methods I always use in my Template Toolkit files,
especially for debugging.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

# package object
my $JSON = JSON::XS->new;
$JSON->convert_blessed(1);
$JSON->allow_blessed(1);

# mysql serial fields are rendered with Math::BigInt objects in RDBO.
# monkeypatch per JSON::XS docs
sub Math::BigInt::TO_JSON {
    my ($self) = @_;
    return $self . '';
}

# same with URI objets
sub URI::TO_JSON {
    my ($uri) = @_;
    return $uri . '';
}

=head2 dump_data

Replacement for the Dumper plugin. You can call this method on any variable
to see its Data::Dump representation in HTML-safe manner.

 [% myvar.dump_data %]
 
=cut

# virt method replacements for Dumper plugin
sub dump_data {
    my $s = shift;
    my $d = Data::Dump::dump($s);
    $d =~ s/&/&amp;/g;
    $d =~ s/</&lt;/g;
    $d =~ s/>/&gt;/g;
    $d =~ s,\n,<br/>\n,g;
    return "<pre>$d</pre>";
}

=head2 dump_stderr

Like dump_data but prints to STDERR instead of returning HTML-escaped string.
Returns undef.

=cut

sub dump_stderr {
    my $s = shift;
    print STDERR Data::Dump::dump($s);
    return;
}

=head2 as_json

Encode the variable as a JSON string. Wrapper around the JSON->encode method.
The string will be encoded as UTF-8, and the special JSON flags for converted_blessed
and allow_blessed are C<true> by default.

=cut

sub as_json {
    my $v = shift;
    if (@_) {
        $JSON->pretty(1);
    }
    my $j = $JSON->encode($v);
    if (@_) {
        $JSON->pretty(0);
    }
    return $j;
}

=head2 increment( I<n> )

Increment a scalar number by one.
Aliased as a scalar vmethod as 'inc'.

=cut

sub increment {
    $_[0]++;
    return;
}

=head2 decrement( I<n> )

Decrement a scalar number by one.
Aliased as a scalar vmethod as 'dec'.

=cut

sub decrement {
    $_[0]--;
    return;
}

=head2 sort_by( I<method_name> )

Sort an array or hash ref of objects according to I<method_name>. The
sort assumes a C<cmp> comparison and the return value of I<method_name>
is run through lc() first.

Returns a new sorted arrayref.

=cut

sub sort_by {
    my $stuff  = shift;
    my $method = shift;
    if ( ref $stuff eq 'HASH' ) {
        return [
            sort {
                lc( $stuff->{$a}->$method ) cmp lc( $stuff->{$b}->$method )
                } keys %$stuff
        ];
    }
    elsif ( ref $stuff eq 'ARRAY' ) {
        return [ sort { lc( $a->$method ) cmp lc( $b->$method ) } @$stuff ];
    }
    elsif ( ref $stuff ) {

        # might be a single blessed object
        return $stuff;
    }
    else {
        croak "sort_by only works with ARRAY or HASH references";
    }

}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-plugin-handy@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

