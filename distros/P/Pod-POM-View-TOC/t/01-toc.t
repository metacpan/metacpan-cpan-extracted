#!/usr/bin/perl

use Test::More tests => 1;
use strict;
use lib qw( lib ../lib );
use Pod::POM;
use Pod::POM::View::HTML;




my $text;
{   local $/ = undef;
    $text = <DATA>;
}
my $parser = Pod::POM->new();

Pod::POM->default_view("Pod::POM::View::TOC");

my $pom = $parser->parse_text($text);

my $toc = "$pom";

is($toc, qq{NAME
SYNOPSIS
DESCRIPTION
METHODS => OTHER STUFF
	new()
		deep
	old()
TESTING FOR AND BEGIN
TESTING URLs hyperlinking
SEE ALSO
});

__DATA__
=head1 NAME

Test

=head1 SYNOPSIS

    use My::Module;

=head1 DESCRIPTION

This is the description.

    Here is a verbatim section.

=head1 METHODS =E<gt> OTHER STUFF

Here is a list of methods

=head2 new()

new

=over

=item

Cat

=back

=head3 deep

=head2 old()

Destructor method

=head1 TESTING FOR AND BEGIN

=for html    <br>
<p>
blah blah
</p>

intermediate text

=begin html

<more>
HTML
</more>

some text

=end

=head1 TESTING URLs C<hyperlinking>

This is an href link1: http://example.com

=head1 SEE ALSO

See also L<Test Page 2|pod2>,

=cut
