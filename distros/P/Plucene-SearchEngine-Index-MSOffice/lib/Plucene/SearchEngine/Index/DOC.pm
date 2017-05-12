package Plucene::SearchEngine::Index::DOC;
use strict;
use warnings;
our $VERSION = '0.001'; # VERSION
# ABSTRACT: a Plucene backend for indexing Microsoft Word documents
use parent qw(Plucene::SearchEngine::Index::Text);

use IPC::Run3;
use File::Temp;

__PACKAGE__->register_handler('application/doc', '.doc');


sub gather_data_from_file {
    my ($self, $filename) = @_;
    return unless $filename =~ m/\.doc$/;

    my $tmp_txt = File::Temp->new();
    run3 ['antiword', $filename],
        \undef,     # stdin is /dev/null
        $tmp_txt,   # some temporary file
        undef;      # inherit the parent's stderr
    $self->gather_data_from_file( $tmp_txt->filename );
    return $self;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plucene::SearchEngine::Index::DOC - a Plucene backend for indexing Microsoft Word documents

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This backend analyzes a DOC file for its textual content (using C<antiword>).

B<This code is not currently actively maintained.>

=head1 METHODS

=head2 gather_data_from_file

Overrides the method from L<Plucene::SearchEngine::Index::Text>
to provide DOC parsing.

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
