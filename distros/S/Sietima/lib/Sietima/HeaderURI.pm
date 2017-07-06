package Sietima::HeaderURI;
use Moo;
use Sietima::Policy;
use Sietima::Types qw(Address AddressFromStr is_Address);
use Types::Standard qw(Str is_Str ClassName HashRef Optional);
use Type::Params qw(compile);
use Types::URI qw(Uri is_Uri);
use Email::Address;
use namespace::clean;

our $VERSION = '1.0.3'; # VERSION
# ABSTRACT: annotated URI for list headers


has uri => (
    is => 'ro',
    isa => Uri,
    required => 1,
    coerce => 1,
);


has comment => (
    is => 'ro',
    isa => Str,
);


sub _args_from_address {
    my ($address, $query) = @_;
    $query ||= {};

    my $uri = URI->new($address->address,'mailto');
    $uri->query_form($query->%*);

    my $comment = $address->comment;
    # Email::Address::comment always returns a string in paretheses,
    # but we don't want that, since we add them back in as_header_raw
    $comment =~ s{\A\((.*)\)\z}{$1} if $comment;

    return {
        uri => $uri,
        comment => $comment,
    };
}

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    if (@args != 1 or ref($args[0]) eq 'HASH' and $args[0]->{uri}) {
        return $class->$orig(@args);
    }

    my $item = $args[0];
    if (is_Address($item)) {
        return _args_from_address($item);
    }
    elsif (is_Uri($item)) {
        return { uri => $item };
    }
    elsif (is_Str($item) and my $address = AddressFromStr->coerce($item)) {
        return _args_from_address($address);
    }
    else {
        return { uri => $item };
    };
};


sub new_from_address {
    state $check = compile(
        ClassName,
        Address->plus_coercions(AddressFromStr),
        Optional[HashRef],
    );
    my ($class, $address, $query) = $check->(@_);

    return $class->new(_args_from_address($address,$query));
}


sub as_header_raw {
    my ($self) = @_;

    my $str = sprintf '<%s>',$self->uri;
    if (my $c = $self->comment) {
        $str .= sprintf ' (%s)',$c;
    }

    return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::HeaderURI - annotated URI for list headers

=head1 VERSION

version 1.0.3

=head1 SYNOPSIS

  around list_addresses => sub($orig,$self) {
   return +{
    $self->$orig->%*,
    one => Sietima::HeaderURI->new({
      uri => 'http://foo/',
      comment => 'a thing',
    }),
    two => Sietima::HeaderURI->new_from_address(
     $self->owner,
     { subject => 'Hello' },
    ),
    three => Sietima::HeaderURI->new('http://some/url'),
    four => Sietima::HeaderURI->new('(comment) address@example.com'),
   };
  }

=head1 DESCRIPTION

This class pairs a L<< C<URI> >> with a comment, and knows how to
render itself as a string that can be used in a list management header
(see L<< C<Sietima::Role::Headers> >>).

=head1 ATTRIBUTES

All attributes are read-only.

=head2 C<uri>

Required L<< C<URI> >> object, coercible from a string or a hashref
(see L<< C<Types::Uri> >> for the details). This is the URI that users
should follow to perform the action implied by the list management
header.

=head2 C<comment>

Optional string, will be added to the list management header as a
comment (in parentheses).

=head1 METHODS

=head2 C<new>

 Sietima::HeaderURI->new({
   uri => 'http://foo/', comment => 'a thing',
 });

 Sietima::HeaderURI->new(
  Email::Address->parse('(comment) address@example.com'),
 );

 Sietima::HeaderURI->new( '(comment) address@example.com' );

 Sietima::HeaderURI->new(
  URI->new('http://some/url'),
 );

 Sietima::HeaderURI->new( 'http://some/url' );

Objects of this class can be constructed in several ways.

You can pass a hashref with URI (or something that L<< C<Types::Uri>
>> can coerce into a URI) and a comment string, as in the first
example.

Or you can pass a single value that can be (or can be coerced into)
either a L<< C<Email::Address> >> or a L<< C<URI> >>.

Email addresse became C<mailto:> URIs, and the optional comment is
preserved.

=head2 C<new_from_address>

 Sietima::HeaderURI->new_from_address(
  $email_address,
  \%query,
 );

This constructor builds a complex C<mailto:> URI with the query hash
you provide. It's a shortcut for:

 my $uri = URI->new("mailto:$email_address");
 $uri->query_form(\%query);

Common query keys are C<subject> and C<body>. See RFC 6068 ("The
'mailto' URI Scheme") for details.

=head2 C<as_header_raw>

  $mail->header_raw_set('List-Thing' => $headeruri->as_header_raw);

This method returns a string representation of the L</URI> and
L</comment> in the format specified by RFC 2369 ("The Use of URLs as
Meta-Syntax for Core Mail List Commands and their Transport through
Message Header Fields").

For example:

 Sietima::HeaderURI->new({
   uri => 'http://foo/', comment => 'a thing',
 })->as_header_raw eq '<http://foo/> (a thing)';

 Sietima::HeaderURI->new( '(comment) address@example.com' )
 ->as_header_raw eq '<mailto:address@example.com> (comment)';

 Sietima::HeaderURI->new( 'http://some/url' )
 ->as_header_raw eq '<http://some/url>';

Notice that, since the list management headers are I<structured>, they
should always be set with L<<
C<header_raw_set>|Email::Simple::Header/header_raw_set >>.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
