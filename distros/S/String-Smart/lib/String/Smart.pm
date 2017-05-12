package String::Smart;

use warnings;
use strict;
use Carp;
use Exporter;
use Scalar::Util qw( blessed );

use overload '""' => \&str_val;

=head1 NAME

String::Smart - Strings that know how to escape themselves.

=head1 VERSION

This document describes String::Smart version 0.4

=cut

use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );

$VERSION     = '0.4';
@ISA         = qw( Exporter );
@EXPORT_OK   = qw( already as add_rep literal plain rep str_val );
%EXPORT_TAGS = ( all => \@EXPORT_OK );

my %rep_map = ();

=head1 SYNOPSIS

    use String::Smart;
    my $plain =            "<This is plain text>";
    my $html  = as html => "<p>&lt;This is HTML&gt;</p>";
    
    print as html => $plain, as html => $html;
    # Prints "&lt;This is plain text&gt;<p>&lt;This is HTML&gt;</p>"

    print plain $html;
    # Croaks: "Can't decode markup"

=head1 DESCRIPTION

String::Smart implements overloaded string values that know how they are
currently encoded or escaped and are capable of transforming themselves
into other encodings.

In many applications it is necessary to apply various escaping rules to
strings before they can safely be used. For example when building a SQL
query string literals must be escaped to avoid SQL injection
vulnerabilities.

Typically this is achieved by SQL escaping all strings that are passed
to the query builder. But what if you pass a string that has already
been SQL escaped? Or a string that is URL encoded? If you wish to pass a
mixture of already-encoded strings and plain string literals you have to
arrange some out of band means of communicating the encoding state of
each string.

With C<String::Smart> you simply make the query building routine
ask for SQL escaped strings and behind the scenes the appropriate
transformations will be applied to each string based on its
current encoding.

For example:

    my $uri_enc = already uri => 'Spaces+are+evil';
    my $sql_enc = already sql => "\\'Quotes are backslashed\\'";
    my $not_enc =                "Just some literal punctuation: %'+";

    print literal sql => $uri_enc;
    # removes URI encoding
    # applies SQL encoding
    # prints
    #   Spaces are evil

    print literal sql => $sql_enc;
    # already sql encoded
    # prints
    #   \'Quotes are backslashed\'

    print literal sql => $not_enc;
    # applies SQL encoding
    # prints
    #   Just some literal punctuation: %\'+

The important point is that the requested encoding is absolute rather
than relative. A C<String::Smart> knows how it is currently encoded and
can work out how to re-encode itself in the requested way.

=head2 A note on the examples

Throughout the documentation I assume that various encoding
representations (C<sql>, C<html>, C<uri>) have already been defined.
These are not defined by C<String::Smart> and must be set up by calling
C<add_rep> with the appropriate conversion subroutines before the
examples will run.

=head1 INTERFACE 

=head2 C<< add_rep >>

Add an encoding representation. The namespace for encodings is global.
This may turn out to be a problem - and may therefore change.

    add_rep reversed => sub { reverse $_[0] }, sub { reverse $_[0] };
    my $this = "Hello";
    my $that = reversed "Hello";
    print as reversed => $this, "\n";
    # prints "olleH"
    print as reversed => $that, "\n";
    # also prints "olleH"

A representation consists of a name and two subroutine references. The
first subroutine applies the encoding, the second reverses it. If either
subroutine is undefined a boilerplate subroutine that throws a
descriptive error will be used in its place.

=cut

sub add_rep($$$) {
  my ( $name, $to, $from ) = @_;

  croak "$name contains an underscore"
   if $name =~ /_/;

  my %spec = ( from => $from, to => $to );
  for my $dir ( keys %spec ) {
    unless ( defined $spec{$dir} ) {
      $spec{$dir} = sub {
        croak "Don't know how to convert $dir $name";
      };
    }
  }

  $rep_map{$name} = \%spec;
}

=head2 C<< as >>

Coerce a string into the specified encoding.

    my $representation = as html => $some_string;

Optionally multiple encodings my be supplied either like this:

    my $rep = as html_nl2br => $some_string;

Or like this:

    my $rep = as ['html', 'nl2br'], $some_string;

The returned object (actually a hash blessed to C<String::Smart>)
will have the specified encoding irrespective of it's current
encoding. For example the sequence:

    my $html1 = as html => $some_string;
    my $html2 = as html => $html1;

Does I<not> result in double encoding. The encodings you request are
'absolute'. A path of transformations that will convert the string from
whatever its current encoding is will be computed and applied.

=cut

sub as($$) {
  my ( $desired, $str ) = @_;

  my @desired
   = map { split /_/ } 'ARRAY' eq ref $desired ? @$desired : $desired;

  unless ( blessed $str && $str->isa( __PACKAGE__ ) ) {
    $str = bless { val => $str, rep => [] };
  }

  my @got_rep  = $str->rep;
  my @want_rep = @desired;

  # Prune common reps
  while ( @got_rep && @want_rep && $got_rep[0] eq $want_rep[0] ) {
    shift @got_rep;
    shift @want_rep;
  }

  $str = $str->{val};

  for my $spec ( [ 'from', reverse @got_rep ], [ 'to', @want_rep ] ) {
    my $dir = shift @$spec;
    for my $rep ( @$spec ) {
      my $handler = $rep_map{$rep} || croak "Don't know about $rep";
      $str = $handler->{$dir}->( $str );
    }
  }

  return bless {
    val => $str,
    rep => \@desired,
  };
}

=head2 C<< already >>

Declare that a string is already encoded in a particular way. For example:

    my $html = already html => '<p>This is a paragraph</p>';
    my $text =                 'This is just << some text >>';
    
    print literal html => $html;
    # already HTML encoded
    # prints
    #    <p>This is a paragraph</p>
    
    print literal html => $text;
    # applies HTML encoding
    # prints
    #   This is just &lt;&lt; some text &gt;&gt;

=cut

sub already($$) {
  return bless {
    val => $_[1],
    rep => [ map { split /_/ } 'ARRAY' eq ref $_[0] ? @$_[0] : $_[0] ]
  };
}

=head2 C<< literal >>

Convert a string to the specified encoding and return it as a normal
unblessed string.

=cut

sub literal($$) { as( $_[0], $_[1] )->{val} }

=head2 C<< plain >>

Remove any encoding from a string.

    my $uri_enc = already uri => 'Spaces+are+evil%21';
    print plain $uri_enc;
    # prints
    #    Spaces are evil!

=cut

sub plain($) { literal( [], $_[0] ) }

=head2 C<< str_val >>

Get the string representation of a C<String::Smart>. No encoding
coercion takes place; C<str_val> returns a string encoded according to
the current encodings.

=cut

sub str_val($) {
  my $str = $_[0];
  blessed $str && $str->isa( __PACKAGE__ ) ? $str->{val} : $str;
}

=head2 C<< rep >>

Return a list of encodings that currently applies to the specfied
string.

    my $text = 'Just text';
    my @trep = rep $text;   # @trep gets ()
    
    my $html = already html => '<p>Boo!</p>';
    my @hrep = rep $html;   # @hrep gets ( 'html' )

=cut

sub rep {
  my $str = $_[0];
  if ( blessed $str && $str->isa( __PACKAGE__ ) ) {
    my @r = @{ $str->{rep} };
    return wantarray ? @r : join '_', @r;
  }
  return;
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
String::Smart requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-string-smart@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head2 Inspiration

Inspired in part by http://xkcd.com/327/

=for html <img src="http://imgs.xkcd.com/comics/exploits_of_a_mom.png"
    title="Her daughter is named Help I'm trapped in a driver's license factory." 
    alt="Exploits of a Mom" />

Thanks Rich for the lead!

=head1 SEE ALSO

L<String::EscapeCage>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
