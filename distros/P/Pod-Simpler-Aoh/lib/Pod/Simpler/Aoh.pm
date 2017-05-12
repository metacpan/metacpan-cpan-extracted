package Pod::Simpler::Aoh;

use Moo;
use MooX::LazierAttributes;
use Types::Standard qw/Str ArrayRef HashRef/;

extends 'Pod::Simple';

our $VERSION = '0.06';

attributes(
    pod => [ rw, ArrayRef, { lzy_array, clr } ],
    section => [ rw, HashRef, { lzy_hash, clr } ],
    pod_elements => [ HashRef, { lzy, bld } ],
    element_name => [ rw, Str, { clr } ],    
);

sub _build_pod_elements {
    return {
        Document    => 'skip',
        head1       => 'title',
        head2       => 'title',
        head2       => 'title',
        head4       => 'title',
        Para        => 'content',
        'item-text' => 'content',
        'over-text' => 'content',
        Verbatim    => 'content',
        Data        => 'content',
        C           => 'content',
        L           => 'content',
        B           => 'content',
        I           => 'content',
        E           => 'content',
        F           => 'content',
        S           => 'content',
        X           => 'content',
        join        => 'content',
    };
}

for (qw/parse_file parse_from_file parse_string_document/) {
    around $_ => sub {
        my ( $orig, $self, $args ) = @_;
        $self->clear_pod;
        $self->$orig($args);
        return $self->pod;
    };
}

sub get {
    return $_[0]->pod->[ $_[1] ];
}

sub aoh {
    return @{ $_[0]->pod };
}

sub _handle_element_start {
    $_[0]->element_name( $_[1] );
    if ( $_[0]->pod_elements->{ $_[1] } eq 'title' ) {
        $_[0]->section->{title} && $_[0]->section->{identifier}
          and $_[0]->_insert_pod;
        not $_[0]->section->{identifier}
          and $_[0]->section->{identifier} = $_[1];
    }
}

sub _handle_text {
    my $el_name = $_[0]->element_name || 'join';
    $_[0]->clear_element_name;
    my $pel = $_[0]->pod_elements->{$el_name};
    if ($pel =~ m#content#) {
        my $el_args = {
            text         => $_[1],
            element_name => $el_name,
            content      => $_[0]->section->{content},
        };
        $_[0]->section->{content} =
          $_[0]->_parse_text( 'content', $el_args );
    }
    elsif ($pel =~ m!title!) {
        $_[0]->section->{title} = $_[1];
    }
}

sub _handle_element_end {
    if ( $_[0]->source_dead ) {
        $_[0]->_insert_pod
          if $_[0]->section->{title}
          && $_[0]->section->{identifier};
    }
}

sub _insert_pod {
    push @{ $_[0]->pod }, $_[0]->section;
    return $_[0]->clear_section;
}

sub _parse_text {
    if ( my $content = $_[2]->{ $_[1] } ) {
        if ( $_[2]->{element_name} =~ m{item-text|over-text} ) {
            return sprintf "%s\n\n%s\n\n", $content, $_[2]->{text};
        }
        # expecting a code example
        elsif ( $content =~ /[\.\;\:\*]$/ ) {
            return sprintf "%s\n\n%s", $content, $_[2]->{text};
        }
        return sprintf "%s%s", $content, $_[2]->{text};
    }
    return $_[2]->{text};
}

1;

__END__

=head1 NAME

Pod::Simpler::Aoh - Parse pod into an array of hashes.

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

Parse POD into an array of hashes

    use Pod::Simpler::Aoh;

    my $pod_parser = Pod::Simpler::Aoh->new();
    my $pod = $pod_parser->parse_file( 'perl.pod' );

    @pod_aoh = $parser->aoh;

    ...

    [
        {
            identifier => 'head1',
            title => NAME,
            content => 'Some::Module - Mehhhh?',
        },
        ......

    ]

=head1 SUBROUTINES/METHODS

L<Pod::Simpler::Aoh> Extends L<Pod::Simple>

=head2 parse_file

Parse a file containing pod.

=head2 parse_string_document

Parse a string containing pod.

=head2 pod

Returns the parsed pod as an arrayref of hashes.

=head2 aoh

Returns the parsed pod as an array of hashes.

=head2 get

Accepts an index, returns a single *section* of pod.

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-simpler-hash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Simpler-Aoh>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::Simpler::Aoh

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Simpler-Aoh>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-Simpler-Aoh>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-Simpler-Aoh>

=item * Search CPAN

L<http://search.cpan.org/dist/Pod-Simpler-Aoh/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

