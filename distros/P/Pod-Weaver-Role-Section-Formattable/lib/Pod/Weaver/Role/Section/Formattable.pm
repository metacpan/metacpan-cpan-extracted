#
# This file is part of Pod-Weaver-Role-Section-Formattable
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Pod::Weaver::Role::Section::Formattable;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 64fd832
$Pod::Weaver::Role::Section::Formattable::VERSION = '0.001';

# ABSTRACT: Role for a formattable section

use Moose::Role;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use MooseX::CurriedDelegation;
use MooseX::Types::Common::String ':all';
use Moose::Autobox;
use Moose::Util::TypeConstraints 'class_type';

with 'Pod::Weaver::Role::Section';

use String::Formatter;

# debugging...
#use Smart::Comments '###';


sub codes {
    my ($self) = @_;

    my %codes = (
        V => sub { shift->{version} },
        d => sub { shift->{zilla}->name },

        #mm => sub { shift->{zilla}->main_module },
        #tf => sub { shift->{zilla}->is_trial ? '-TRIAL' : q{} },

        n => sub { "\n" },
        t => sub { "\t" },

        p => sub { shift
            ->{ppi_document}
            ->find_first('PPI::Statement::Package')
            ->namespace
            ;
        },

        $self->additional_codes,
    );

    return \%codes;
}

sub additional_codes { () }


sub default_formatter {
    my $self = shift @_;

    return String::Formatter->new({
        input_processor => 'require_single_input',
        string_replacer => 'method_replace',
        codes           => $self->codes,
    });
}


has formatter => (
    is      => 'ro',
    isa     => class_type('String::Formatter'),
    lazy    => 1,
    builder => 'default_formatter',
    handles => { format_section => { format => [ sub { shift->format } ] } },
);


has section_name => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    lazy    => 1,
    builder => 'default_section_name',
);

requires 'default_section_name';


has format => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => 'default_format',
);

requires 'default_format';


sub _para {
    my ($self, $content) = @_;

    return Pod::Elemental::Element::Pod5::Ordinary->new({ content => $content });
}

sub build_content {
    my ($self, $document, $input) = @_;

    # we're going to make the assumption here that we always end up with text.

    ### keys input: keys %$input
    my $text       = $self->format_section($input);
    my @paragraphs; # = ();
    my $paragraph  = q{};

    ### $text
    for my $line (split /\n/, $text) {
        
        chomp $line;
        if ($line =~ /^\s*$/) {

            ### new: $line
            ### $paragraph
            push @paragraphs, $paragraph
                unless $paragraph eq q{};
            $paragraph = q{};
        }
        else {

            ### append: $line
            $line =~ s/\s+$/ /;
            $paragraph .= "$line ";
        }
    }
    push @paragraphs, $paragraph
        unless $paragraph eq q{};

    ### @paragraphs
    return (map { $self->_para($_) } @paragraphs);
}


sub weave_section {
    my ($self, $document, $input) = @_;

    my $nested = Pod::Elemental::Element::Nested->new({
        command  => 'head1',
        content  => $self->section_name,
        children => [ $self->build_content($document, $input) ],
    });

    ### $nested
    $document->children->push($nested);
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Pod::Weaver::Role::Section::Formattable - Role for a formattable section

=head1 VERSION

This document describes version 0.001 of Pod::Weaver::Role::Section::Formattable - released July 12, 2015 as part of Pod-Weaver-Role-Section-Formattable.

=head1 OVERVIEW

This role is consumed by sections that operate through the mechanism of
L<String::Formatter>, namely that they take a format and input data, and
generate a top-level section from that.

=head1 REQUIRED METHODS

=head2 default_section_name

Generate our default section name.

This is a builder method for the C<section_name> attribute.

=head2 default_format

The default string to use as the format, when one has not been specified in
the configuration.

This is a builder method for the C<format> attribute.

=head1 ATTRIBUTES

=head2 formatter

This lazily-built attribute holds our formatter.

=head2 section_name

This attribute holds the section name a consuming plugin will use.

=head2 format

The string to use when generating the version string.

=head1 METHODS

=head2 codes

This method returns a hashref of codes suitable to building a
L<String::Formatter> with.  For our list of codes, see OVERVIEW, below.

Sections consuming this role should consider creating a C<additional_codes>
method, as codes returned by that method will be merged in with our default
codes.  C<additional_codes> should return a list, not a hashref.

Of course, the choice is yours.

=head2 format_section $input

Return the text representing the formatted section.  This method is called
with the C<$input> taken from C<weave_section>.

=head2 build_content($document, $input)

This method is passed the same C<$document> and C<$input> that the
C<weave_section> method is called with, and should return a list of pod
elements to insert.

In almost all cases, this method is used internally, but could be usefully
overridden in a subclass.

=head2 weave_section

Build our section.

=head1 CODES

We provide the following codes:

=over 4

=item *

%v - distribution version

=item *

%d - distribution name

=item *

%p - package name

=item *

%{mm} - "main module" name

=item *

%{tf} - "trial flag", e.g. "-TRIAL" if trial, an empty string if not

=item *

%t - a tab

=item *

%n - a newline

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/pod-weaver-role-section-formattable/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fpod-weaver-role-section-formattable&title=RsrchBoy's%20CPAN%20Pod-Weaver-Role-Section-Formattable&tags=%22RsrchBoy's%20Pod-Weaver-Role-Section-Formattable%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fpod-weaver-role-section-formattable&title=RsrchBoy's%20CPAN%20Pod-Weaver-Role-Section-Formattable&tags=%22RsrchBoy's%20Pod-Weaver-Role-Section-Formattable%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
