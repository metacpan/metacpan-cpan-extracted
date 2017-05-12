package PAR::Filter::Squish;

use strict;
use vars qw/$VERSION/;
$VERSION = '0.03';

use Perl::Squish;
use base 'PAR::Filter';

=head1 NAME

PAR::Filter::Squish - PAR filter for reducing code size

=head1 SYNOPSIS

    # transforms $code
    PAR::Filter::Squish->apply(\$code, $filename, $name);

=head1 DESCRIPTION

This filter uses L<Perl::Squish> to reduce the size of a module
as much as possible.

It does not preserve line numbers, comments or documentation.

Do not expect miracles. Unless you include B<a lot> of modules,
the major component of a binary produced by C<pp> will be
shared object files and the perl run-time.

=head1 METHODS

=head2 apply

Class method which applies the filter to source code. Expects a reference
to the code string as first argument optionally followed by file and
module name. Those names are particularily accepted for compatibility to
other PAR filters.

=cut

sub apply {
    my ($class, $ref, $filename, $name) = @_;

    return if $filename =~ /\.bs$/i;
    no warnings 'uninitialized';

    my $data = '';
    $data = $1 if $$ref =~ s/((?:^__DATA__\r?\n).*)//ms;

    my $doc = PPI::Document->new($ref);
    my $trafo = Perl::Squish->new();
    if (not defined $doc) {
      warn __PACKAGE__ . ": Could not parse '$filename' using PPI!";
      $$ref .= $data;
      return;
    }
    $trafo->apply($doc);
    if (not defined $doc) {
      warn __PACKAGE__ . ": Could not apply transformation to '$filename'!";
      $$ref .= $data;
      return;
    }

    $$ref = $doc->serialize();
    
    $$ref .= $data;
}

1;

=head1 SEE ALSO

L<PAR>

L<PAR::Filter>

L<Perl::Squish>

=head1 AUTHORS

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

L<http://par.perl.org/> is the official PAR website.  You can write
to the mailing list at E<lt>par@perl.orgE<gt>, or send an empty mail to
E<lt>par-subscribe@perl.orgE<gt> to participate in the discussion.

Please submit bug reports to E<lt>bug-par-filter-squish@rt.cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2006-2008 by Steffen Mueller E<lt>smueller@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
