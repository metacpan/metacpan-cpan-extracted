#
# This file is part of Template-Plugin-Filter-IDN
#
# This software is copyright (c) 2018 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

package Template::Plugin::Filter::IDN;
$Template::Plugin::Filter::IDN::VERSION = '0.03';
# ABSTRACT: Template Toolkit plugin for encoding and decoding International Domain Names.

use strict;
use warnings;
use syntax 'junction';

use parent 'Template::Plugin::Filter';

use Carp ();
use Net::IDN::Encode ();

our $DYNAMIC = 1;

sub init {
    my $self = shift;

    $self->install_filter('idn');

    return $self;
}

sub filter {
    my ($self, $text, $args) = @_;

    my ($type) = @$args;

    # if no "type" was given, try to guess what we should do.  If we have
    # non-ascii chars, assume that we want to_ascii
    unless (defined $type) {
        $type = ($text =~ /[^ -~\s]/) ? 'to_ascii' : 'to_utf8';
    }

    if ($type eq any(qw(encode to_ascii))) {
        return Net::IDN::Encode::domain_to_ascii($text);
    }
    elsif ($type eq any(qw(decode to_utf8))) {
        return Net::IDN::Encode::domain_to_unicode($text);
    }
    else {
        Carp::croak "Unknown IDN filter action: $type";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Plugin::Filter::IDN - Template Toolkit plugin for encoding and decoding International Domain Names.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 #
 # Convert a UTF-8 domain name to Punycode:
 #
 [%- USE Filter.IDN -%]
 <a href="http://[% '域名.org' | idn('to_ascii') %]">Link</a>

 # Output
 <a href="http://xn--eqrt2g.org">Link</a>

 #
 # Convert Punycode to UTF-8:
 #
 [%- USE Filter.IDN -%]
 [% 'xn--eqrt2g.org' | idn('to_utf8') %]

 # Output:
 域名.org

=head1 DESCRIPTION

This is a Template Toolkit filter which handles conversion of International
Domain Names from UTF-8 to ASCII (in Punycode encoding) and vice versa.

=for Pod::Coverage init filter

=head1 USAGE

Include C<[% USE Filter.IDN %]> in your template.  Then you will be able to use
the C<idn> filter to encode or decode International Domain Names.  The filter
takes a single required argument which is the action that is requested.  The
must be one of the following values:

=over 4

=item *

to_ascii

Convert a UTF-8 label to Punycode.  If the string is already an ASCII string,
the original string will be passed through the filter.

=item *

encode

This is an alias for C<to_ascii>.  Think "encode" to Punycode.

=item *

to_utf8

Convert a Punycode label to UTF-8.  If the string is not a Punycode string,
then the original string will be passed through the filter.

=item *

decode

This is an alias for C<to_utf8>.  Think "decode" from Punycode.

=back

=head1 SEE ALSO

L<Net::IDN::Encode>

=head1 SOURCE

The development version is on github at L<http://https://github.com/mschout/perl-template-plugin-filter-idn>
and may be cloned from L<git://https://github.com/mschout/perl-template-plugin-filter-idn.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/perl-template-plugin-filter-idn/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
