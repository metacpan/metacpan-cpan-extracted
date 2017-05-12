# ABSTRACT: Parser for Selenese
package Parse::Selenese;
use Moose;
use Parse::Selenese::TestCase;

our $VERSION = '0.006'; # VERSION

sub parse {
    Parse::Selenese::TestCase->new(shift);
}

1;



=pod

=head1 NAME

Parse::Selenese - Parser for Selenese

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use Parse::Selenese;

=head1 DESCRIPTION

Parse::Selenese makes it easy to parse Selenium Test Suites and Test Cases from
their HTML format into Perl.

=head2 Functions

=over

=item C<Parse::Selenese::parse($file_name|$content|%args)>

Return a Parse::Selenese::TestCase, Parse::Selenese::TestSuite or undef if
unable to parse the file name or content.

=back

=head1 NAME

Parse::Selenese - Easy Selenium Test Suite and Test Case parsing.

=head1 AUTHOR

Theodore Robert Campbell Jr.  E<lt>trcjr@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Selenese>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<http://github.com/trcjr/Parse-Selenese>

  git clone http://github.com/trcjr/Parse-Selenese

=head1 AUTHOR

Theodore Robert Campbell Jr <trcjr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Theodore Robert Campbell Jr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

