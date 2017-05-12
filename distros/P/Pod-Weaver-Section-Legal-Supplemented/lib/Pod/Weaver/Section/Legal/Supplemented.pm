use strict;
use warnings;

package Pod::Weaver::Section::Legal::Supplemented;

our $VERSION = '0.0100'; # VERSION
# ABSTRACT: Add text to the Legal section

use Moose;
extends 'Pod::Weaver::Section::Legal';
with 'Pod::Weaver::Role::AddTextToSection';
use Types::Standard qw/ArrayRef Str/;

sub mvp_multivalue_args { qw/text_before text_after/ }

for my $where (qw/text_before text_after/) {
    has $where => (
        is => 'rw',
        isa => ArrayRef->plus_coercions(Str, sub { [$_] }),
        coerce => 1,
        traits => ['Array'],
        predicate => "has_$where",
        default => sub { [] },
        handles => {
            "all_$where"  => 'elements',
            "join_$where" => 'join',
        },
    );
}

around weave_section => sub {
    my $next = shift;
    my $self = shift;
    my $document = shift;
    my $input = shift;

    $self->$next($document, $input);
    my $place = $document->children->[-1];

    if($self->has_text_before) {
        $self->add_text_to_section($document, $self->join_text_before("\n"), $self->header, { top => 1 });
    }
    if($self->has_text_after) {
        $self->add_text_to_section($document, $self->join_text_after("\n") . "\n\n", $self->header);
    }
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Legal::Supplemented - Add text to the Legal section



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.10.1-brightgreen.svg" alt="Requires Perl 5.10.1" /> <a href="https://travis-ci.org/Csson/p5-Pod-Weaver-Section-Legal-Supplemented"><img src="https://api.travis-ci.org/Csson/p5-Pod-Weaver-Section-Legal-Supplemented.svg?branch=master" alt="Travis status" /></a></p>

=end HTML


=begin markdown

![Requires Perl 5.10.1](https://img.shields.io/badge/perl-5.10.1-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Pod-Weaver-Section-Legal-Supplemented.svg?branch=master)](https://travis-ci.org/Csson/p5-Pod-Weaver-Section-Legal-Supplemented)

=end markdown

=head1 VERSION

Version 0.0100, released 2015-11-24.

=head1 SYNOPSIS

    ; in weaver.ini
    [Legal::Supplemented]
    before = This text is rendered before the auto-generated
    before = from [Legal]
    after = And this text comes after
    after =
    after = More text here

=head1 DESCRIPTION

Pod::Weaver::Section::Legal::Supplemented is a sub-class of L<Pod::Weaver::Section::Legal> that gives the possibility to add text before and/or after the auto-generated
text that C<[Legal]> renders. Sometimes it might be nice/necessary to mention relationships to companies, trademarks, et cetera used or mentioned. This plugin gives the
opportunity to do that without losing the functionality of C<[Legal]> and without having to create another section.

=head1 ATTRIBUTES

This plugin inherits all attributes from L<Pod::Weaver::Section::Legal>.

=head2 text_before

Optional.

The text that should come before the C<[Legal]> rendered text. Allowed multiple times.

=head2 text_after

Optional.

The text that should come after the C<[Legal]> rendered text. Allowed multiple times.

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver::Section::LegalWithAddendum> which inspired this

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Pod-Weaver-Section-Legal-Supplemented>

=head1 HOMEPAGE

L<https://metacpan.org/release/Pod-Weaver-Section-Legal-Supplemented>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
