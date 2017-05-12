use 5.008;
use strict;
use warnings;

package Pod::Weaver::Section::BugsAndLimitations;
# ABSTRACT: Add a BUGS AND LIMITATIONS pod section
our $VERSION = '1.20'; # VERSION
use Moose;
with 'Pod::Weaver::Role::Section';

use namespace::autoclean;
use Moose::Autobox;


sub weave_section {
    my ($self, $document, $input) = @_;
    my $bugtracker = $input->{zilla}->distmeta->{resources}{bugtracker}{web}
      || 'http://rt.cpan.org';
    $document->children->push(
        Pod::Elemental::Element::Nested->new(
            {   command  => 'head1',
                content  => 'BUGS AND LIMITATIONS',
                children => [
                    Pod::Elemental::Element::Pod5::Ordinary->new(
                        {   content => <<EOPOD,
You can make new bug reports, and view existing ones, through the
web interface at L<$bugtracker>.
EOPOD
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

Pod::Weaver::Section::BugsAndLimitations - Add a BUGS AND LIMITATIONS pod section

=head1 VERSION

version 1.20

=head1 SYNOPSIS

In C<weaver.ini>:

    [BugsAndLimitations]

=head1 OVERVIEW

This section plugin will produce a hunk of Pod that refers to the bugtracker
URL.

You need to use L<Dist::Zilla::Plugin::Bugtracker> in your C<dist.ini> file,
because this plugin relies on information that other plugin generates.

=head2 weave_section

adds the C<BUGS AND LIMITATIONS> section.

=for test_synopsis 1;
__END__

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Pod::Weaver::Section::BugsAndLimitations/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Pod-Weaver-Section-BugsAndLimitations>
and may be cloned from L<git://github.com/doherty/Pod-Weaver-Section-BugsAndLimitations.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Pod-Weaver-Section-BugsAndLimitations/issues>.

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

