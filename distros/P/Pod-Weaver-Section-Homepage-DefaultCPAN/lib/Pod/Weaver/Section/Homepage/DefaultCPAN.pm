package Pod::Weaver::Section::Homepage::DefaultCPAN;

our $DATE = '2015-04-02'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use Moose;
#use Text::Wrap ();
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

has text => (
    is => 'rw',
    isa => 'Str',
    default => q{Please visit the project's homepage at L<%s>.},
);

sub weave_section {
  my ($self, $document, $input) = @_;

  my $name = $input->{zilla}->name;
  my $homepage = $input->{distmeta}{resources}{homepage} //
      "https://metacpan.org/release/$name";

  my $text = sprintf($self->text, $homepage) . "\n\n";

  #$text = Text::Wrap::wrap(q{}, q{}, $text);

  $self->add_text_to_section($document, $text, 'HOMEPAGE');
}

no Moose;
1;
# ABSTRACT: Add a HOMEPAGE section (homepage defaults to MetaCPAN release page)

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Homepage::DefaultCPAN - Add a HOMEPAGE section (homepage defaults to MetaCPAN release page)

=head1 VERSION

This document describes version 0.05 of Pod::Weaver::Section::Homepage::DefaultCPAN (from Perl distribution Pod-Weaver-Section-Homepage-DefaultCPAN), released on 2015-04-02.

=head1 SYNOPSIS

In your C<weaver.ini>:

 [Homepage::DefaultCPAN]

To specify homepage other than C<https://metacpan.org/release/NAME>, in
dist.ini:

 [MetaResources]
 homepage=http://example.com/

=head1 DESCRIPTION

This section plugin adds a HOMEPAGE section using C<homepage> metadata, or
MetaCPAN release page if C<homepage> is not specified.

=for Pod::Coverage weave_section

=head1 ATTRIBUTES

=head2 text

The text that is added. C<%s> is replaced by the homepage url.

Default: C<Please visit the project's homepage at LE<lt>%sE<gt>.>

=head1 SEE ALSO

L<Pod::Weaver::Section::Availability>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Section-Homepage-DefaultCPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Section-Homepage-DefaultCPAN>.=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Section-Homepage-DefaultCPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.
=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
