package PLP::Fields;

use strict;
use warnings;

our $VERSION = '1.00';

# Has only one function: doit(), which ties the hashes %get, %post, %fields
# and %header in PLP::Script. Also generates %cookie immediately.
sub doit {

	# %get
	
	my $get = \%PLP::Script::get;
	if (defined $ENV{QUERY_STRING} and length $ENV{QUERY_STRING}){
		for (split /[&;]/, $ENV{QUERY_STRING}) {
			my @keyval = split /=/, $_, 2;
			PLP::Functions::DecodeURI(@keyval);
			$get->{$keyval[0]} = $keyval[1] unless $keyval[0] =~ /^\@/;
			push @{ $get->{ '@' . $keyval[0] } }, $keyval[1];
		}
	}

	# %post

	tie %PLP::Script::post, 'PLP::Tie::Delay', 'PLP::Script::post', sub {
		my %post;
		return \%post unless $ENV{CONTENT_TYPE} and $ENV{CONTENT_LENGTH} and
			$ENV{CONTENT_TYPE} =~ m!^(?:application/x-www-form-urlencoded|$)!;
		
		my $post = $PLP::read->($ENV{CONTENT_LENGTH});
		return \%post unless defined $post and length $post;
		
		for (split /&/, $post) {
			my @keyval = split /=/, $_, 2;
			PLP::Functions::DecodeURI(@keyval);
			$post{$keyval[0]} = $keyval[1] unless $keyval[0] =~ /^\@/;
			push @{ $post{ '@' . $keyval[0] } }, $keyval[1];
		}
		
		return \%post;
	};

	# %fields

	tie %PLP::Script::fields, 'PLP::Tie::Delay', 'PLP::Script::fields', sub {
		return { %PLP::Script::get, %PLP::Script::post };
	};

	# %header

	tie %PLP::Script::header, 'PLP::Tie::Headers';

	# %cookie

	if (defined $ENV{HTTP_COOKIE} and length $ENV{HTTP_COOKIE}) {
		for (split /; ?/, $ENV{HTTP_COOKIE}) {
			my @keyval = split /=/, $_, 2;
			$PLP::Script::cookie{$keyval[0]} ||= $keyval[1];
		}
	}
}

1;

=head1 NAME

PLP::Fields - Special hashes for PLP

=head1 DESCRIPTION

For your convenience, PLP uses hashes to put things in. Some of these are tied
hashes, so they contain a bit magic. For example, building the hash can be
delayed until you actually use the hash.

=over 10

=item C<%get> and C<%post>

These are built from the C<key=value&key=value> (or C<key=value;key=value>
strings in query string and post content. C<%post> is not built if the content
type is not C<application/x-www-form-urlencoded>. In post content, the
semi-colon is not a valid separator.

%post isn't built until it is used, to speed up your script if you
don't use it. Because POST content can only be read once, you can C<use CGI;>
and just never access C<%post> to avoid its building.

With a query string of C<key=firstvalue&key=secondvalue>, C<$get{key}> will
contain only C<secondvalue>. You can access both elements by using the array
reference C<$get{'@key'}>, which will contain C<[ 'firstvalue', 'secondvalue'
]>.

=item C<%fields>

This hash combines %get and %post, and triggers creation of %post. POST gets
precedence over GET (note: not even the C<@>-keys contain both values).

This hash is built on first use, just like %post.

=item C<%cookie>, C<%cookies>

This is built immediately, because cookies are usually short in length. Cookies
are B<not> automatically url-decoded.

=item C<%header>, C<%headers>

In this hash, you can set headers. Underscores are converted to normal minus
signs, so you can leave out quotes. The hash is case insensitive: the case used
when sending the headers is the one you used first. The following are equal:

    $header{CONTENT_TYPE}
    $header{'Content-Type'}
    $header{Content_Type}
    $headers{CONTENT_type}

If a value contains newlines, the header is repeated for each line:

	$header{Allow} = "HEAD\nGET";  # equivalent to HEAD,GET

=back

=head1 AUTHOR

Juerd Waalboer <juerd@cpan.org>

Current maintainer: Mischa POSLAWSKY <shiar@cpan.org>

=cut

