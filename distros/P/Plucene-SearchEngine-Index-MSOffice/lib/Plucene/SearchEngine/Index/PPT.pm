package Plucene::SearchEngine::Index::PPT;
use strict;
use warnings;
our $VERSION = '0.001'; # VERSION
# ABSTRACT: a Plucene backend for indexing Microsoft Powerpoint presentations
use parent qw(Plucene::SearchEngine::Index::HTML);

use IPC::Run3;
use File::Temp;

__PACKAGE__->register_handler('text/ppt', '.ppt');


sub gather_data_from_file {
    my ($self, $filename) = @_;
    return unless $filename =~ m/\.ppt$/;

    my $tmp_html = File::Temp->new();
    run3 ['ppthtml', $filename],
        \undef,     # redirect from /dev/null
        $tmp_html,  # write to a temp file
        undef;      # inherit the parent's stderr

    $self->gather_data_from_file( $tmp_html->filename );
    return $self;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plucene::SearchEngine::Index::PPT - a Plucene backend for indexing Microsoft Powerpoint presentations

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This backend analysis a PPT file. The module use the tool called
ppthtml, provided by xlhtml packges available from
L<http://chicago.sourceforge.net/xlhtml/>, or your operating
system's package manager.

B<This code is not currently actively maintained.>

=over 3

=item text

The text part of the PPT

=item link

A list of links in the HTML

=back

Additionally, any C<META> tags are turned into Plucene fields.

=head1 METHODS

=head2 gather_data_from_file

Overrides the method from L<Plucene::SearchEngine::Index::HTML>
to provide PPT parsing.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Plucene::SearchEngine::Index::MSOffice/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Plucene-SearchEngine-Index-MSOffice>
and may be cloned from L<git://github.com/doherty/Plucene-SearchEngine-Index-MSOffice.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Plucene-SearchEngine-Index-MSOffice/issues>.

=head1 AUTHORS

=over 4

=item *

Sopan Shewale <sopan.shewale@gmail.com>

=item *

Mike Doherty <doherty@pythian.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sopan Shewale <sopan.shewale@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
