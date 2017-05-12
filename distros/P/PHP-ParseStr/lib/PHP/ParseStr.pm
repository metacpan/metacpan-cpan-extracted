package PHP::ParseStr;

use 5.010;
use strict;
use warnings;

our $VERSION = "0.0.2";

use Exporter::Easy (
    OK => [qw( php_parse_str )]
);

use URI;

=head1 NAME

PHP::ParseStr - Implements PHP's parse_str function

=for markdown [![Build Status](https://travis-ci.org/abayliss/php-parsestr.svg?branch=master)](https://travis-ci.org/abayliss/php-parsestr)

=head1 SYNOPSIS

  use PHP::ParseStr qw(php_parse_str);
  my $hr = php_parse_str("stuff[0]=things&stuff[1]=otherthings&widgit[name]=thing&widgit[id]=123");

=head1 DESCRIPTION

A simple implementation of PHP's C<parse_str> function. The inverse of
C<http_build_query> (implemented by L<PHP::HTTPBuildQuery>).

=head1 USAGE

Pass your query string into C<php_parse_str> and get a hash ref back.

  my $hr = php_parse_str("stuff[0]=things&stuff[1]=otherthings&widgit[name]=thing&widgit[id]=123");
  # {
  #     stuff => [ 'things', 'otherthings' ],
  #     widgit => {
  #         id => '123',
  #         name => 'thing'
  #     }
  # }

Note that unlike PHP's C<parse_str>, we return a hash ref, rather than
automagically creating variables in the passing scope, or filling a hash passed
in by reference. This is A Good Thing.

=head1 BUGS / LIMITATIONS

Currently I assume that anything where the "key" is numeric will be an array.
This will cause problems if you get structures with mixed numeric and
alphanumeric keys if a numeric one is encountered first.

This module worked well enough for my purposes. YMMV. Patches welcome.

=head1 SEE ALSO

L<PHP::HTTPBuildQuery> does the inverse of this module.

=head1 AUTHOR

Andrew Bayliss <abayliss@gmail.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# inspired by http://www.perlmonks.org/?node_id=872864
sub php_parse_str {
    my ( $str ) = @_;

    my $u = URI->new;
    $u->query($str);

    my %in = $u->query_form;
    my $out = {};
    while ( my ( $k, $v ) = each %in ) {
        my $level = \$out;

        my @parts = $k =~ /([^\[\]]+)/g;
        foreach (@parts) { 
            if ( $_ =~ /^\d+$/ ) {
                $$level //= [];
                $level = \($$level->[$_]);
            } else {
                $$level //= {};
                $level = \($$level->{$_});
            }
        }
        $$level = $v;
    }

    return $out;
}

return "Perfectly Horrible Poppycock";
