use strict;  # keep [TestingAndDebugging::RequireUseStrict] happy
use warnings;
package Pod::Weaver::Section::Installation;
our $VERSION = '1.101421'; # VERSION
# ABSTRACT: Add an INSTALLATION pod section

use Moose;
with 'Pod::Weaver::Role::Section';

use namespace::autoclean;
use Moose::Autobox;

sub weave_section {
    my ($self, $document) = @_;
    $document->children->push(
        Pod::Elemental::Element::Nested->new(
            {   command  => 'head1',
                content  => 'INSTALLATION',
                children => [
                    Pod::Elemental::Element::Pod5::Ordinary->new(
                        {   content =>
'See perlmodinstall for information and options on installing Perl modules.'
                        }
                    ),
                ],
            }
        ),
    );
}
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Pod::Weaver::Section::Installation - Add an INSTALLATION pod section

=head1 VERSION

version 1.101421

=head1 SYNOPSIS

In C<weaver.ini>:

    [Installation]

=head1 OVERVIEW

This section plugin will produce a hunk of Pod that describes how to install
the distribution.

=head1 METHODS

=head2 weave_section

Adds the C<INSTALLATION> section.

=for test_synopsis 1;
__END__

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Pod::Weaver::Section::Installation/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Pod-Weaver-Section-Installation>
and may be cloned from L<git://github.com/doherty/Pod-Weaver-Section-Installation.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Pod-Weaver-Section-Installation/issues>.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
