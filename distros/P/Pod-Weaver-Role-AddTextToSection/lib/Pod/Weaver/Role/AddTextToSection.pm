package Pod::Weaver::Role::AddTextToSection;

our $DATE = '2017-01-14'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use Moose::Role;

use Encode qw(decode encode);
#use Pod::Elemental;
use Pod::Elemental::Element::Nested;

sub add_text_to_section {
    my ($self, $document, $text, $section, $opts) = @_;

    $opts //= {};
    $opts->{create} //= 1;
    $opts->{ignore} //= 0;
    $opts->{top} //= 0;

    # convert characters to bytes, which is expected by read_string()
    $text = encode('UTF-8', $text, Encode::FB_CROAK);

    my $text_elem = Pod::Elemental->read_string($text);

    # dump document
    #use DD; dd $document->children;
    #say $document->as_debug_string;
    #say $document->as_pod_string;

    # get list of head1 commands with their position in document
    my %headlines_pos;
    {
        my $i = -1;
        for (@{ $document->children }) {
            $i++;
            next unless $_->can('command') && $_->command eq 'head1';
            my $name = $_->{content};
            next if defined $headlines_pos{$name};
            $headlines_pos{$name} = $i;
        }
    }
    #$self->log_debug(["current headlines in the document: %s", \%headlines_pos]);

    my $section_elem;
    $section_elem = $document->children->[ $headlines_pos{$section} ]
        if defined $headlines_pos{$section};

    # this comment is from the old code, i'm keeping it here in case i need it

    # sometimes we get a Pod::Elemental::Element::Pod5::Command (e.g. empty
    # "=head1 DESCRIPTION") instead of a Pod::Elemental::Element::Nested. in
    # that case, just ignore it.

  FIND_OR_CREATE_SECTION:
    {
        if (!$section_elem) {
            if ($opts->{create}) {
                $self->log_debug(["Creating section $section"]);
                $section_elem = Pod::Elemental::Element::Nested->new({
                    command  => 'head1',
                    content  => $section,
                });
                if ($opts->{after_section}) {
                    my @sections = ref($opts->{after_section}) eq 'ARRAY' ?
                        @{ $opts->{after_section} } : ($opts->{after_section});
                    for (@sections) {
                        if (defined $headlines_pos{$_}) {
                            $self->log_debug(["Putting newly created section after section '%s'", $_]);
                            splice @{ $document->children }, $headlines_pos{$_}+1, 0, $section_elem;
                            last FIND_OR_CREATE_SECTION;
                        }
                    }
                }
                if ($opts->{before_section}) {
                    my @sections = ref($opts->{before_section}) eq 'ARRAY' ?
                        @{ $opts->{before_section} } : ($opts->{before_section});
                    for (@sections) {
                        if (defined $headlines_pos{$_}) {
                            $self->log_debug(["Putting newly created section before section '%s'", $_]);
                            splice @{ $document->children }, $headlines_pos{$_}, 0, $section_elem;
                            last FIND_OR_CREATE_SECTION;
                        }
                    }
                }
                push @{ $document->children }, $section_elem;
            } else {
                die "Can't find section named '$section' in POD document";
            }
        } else {
            $self->log_debug(["Skipping adding text because section $section already exists"]);
            return 0 if $opts->{ignore};
        }
    }

  ADD_TEXT:
    {
        if ($opts->{top}) {
            $self->log_debug(["Adding text at the top of section $section"]);
            unshift @{ $section_elem->children }, @{ $text_elem->children };
        } else {
            $self->log_debug(["Adding text at the bottom of section $section"]);
            push @{ $section_elem->children }, @{ $text_elem->children };
        }
    }
    return 1;
}

no Moose::Role;
1;
# ABSTRACT: Add text to a section

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::AddTextToSection - Add text to a section

=head1 VERSION

This document describes version 0.06 of Pod::Weaver::Role::AddTextToSection (from Perl distribution Pod-Weaver-Role-AddTextToSection), released on 2017-01-14.

=head1 SYNOPSIS

 my $text = <<EOT;
 This module is made possible by L<Krating Daeng|http://www.kratingdaeng.co.id>.

 A shout out to my man Punk The Man.

 Thanks also to:

 =over

 =item * my mom

 =item * my dog

 =item * my peeps

 =back

 EOT

 $self->add_text_to_section($document, $text, 'THANKS');

=head1 DESCRIPTION

=head1 METHODS

=head2 $obj->add_text_to_section($document, $text, $section[, \%opts]) => bool

Add a string C<$text> to a section named C<$section>.

C<$text> will be converted into a POD element tree first.

Section are POD paragraphs under a heading (C<=head1>, C<=head2> and so on).
Section name will be searched case-insensitively.

If section does not yet already exist: will create the section (if C<create>
option is true) or will die. Section will be created with C<=head1> heading at
the bottom of the document (XXX is there a use-case where we need to add at the
top and need to provide a create_top option? XXX is there a use-case where we
need to create C<head2> and so on?).

If section already exists, will skip and do nothing (if C<ignore> option is
true, not unlike C<INSERT OR IGNORE> in SQL) or will add text. Text will be
added at the bottom the existing text, unless when C<top> option is true in
which case will text will be added at the top the existing text.

Will return a boolean status which is true when text is actually added to the
section.

Options:

=over

=item * create => bool (default: 1)

Whether to create section if it does not already exist in the document.

=item * after_section => str|array

When creating a section, attempt to put the new section after the specified
section(s). This is evaluated before C<before_section>.

=item * before_section => str|array

When creating a section, attempt to put the new section before the specified
section(s).

=item * ignore => bool (default: 0)

If set to true, then if section already exist will skip adding the text.

=item * top => bool (default: 0)

If set to true, will add text at the top of existing text instead of at the
bottom.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Role-AddTextToSection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Role-AddTextToSection>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Role-AddTextToSection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
