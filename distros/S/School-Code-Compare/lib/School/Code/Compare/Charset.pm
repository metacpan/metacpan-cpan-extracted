package School::Code::Compare::Charset;
# ABSTRACT: trim whitespace, comments and unessential chars
$School::Code::Compare::Charset::VERSION = '0.101';
use strict;
use warnings;

use School::Code::Compare::Charset::NoComments;
use School::Code::Compare::Charset::NoWhitespace;
use School::Code::Compare::Charset::NumSignes;
use School::Code::Compare::Charset::Signes;

sub new {
    my $class = shift;

    my $self = {
                 language      => 'txt',
               };
    bless $self, $class;

    return $self;
}

sub set_language {
    my $self = shift;

    $self->{language} = shift;

    return $self;
}

sub sort_by_lines {
    my $self = shift;
    my $lines_ref = shift;

    my @sorted = sort { $a cmp $b } @{$lines_ref};

    return \@sorted;
}

sub trim_comments {
    my $self      = shift;
    my $lines_ref = shift;

    my $clean   = School::Code::Compare::Charset::NoComments->new();
    my $cleaned = '';
    my $lang    = $self->{language};

    if ($lang eq 'python'
     or $lang eq 'perl'
     or $lang eq 'bash'
     or $lang eq 'hashy'
     ) {
        $cleaned = $clean->hashy ( $lines_ref );
    }
    elsif ($lang eq 'php'
        or $lang eq 'js'
        or $lang eq 'cpp'
        or $lang eq 'cs'
        or $lang eq 'c'
        or $lang eq 'java'
        or $lang eq 'slashy'
     ) {
        $cleaned = $clean->slashy ( $lines_ref );
    }
    elsif ($lang eq 'html'
        or $lang eq 'xml'
    ) {
        $cleaned = $clean->html ( $lines_ref );
    }
    elsif ($lang eq 'txt') {
        $cleaned = $lines_ref; # do nothing
    }

    return $cleaned;
}

sub get_visibles {
    my $self      = shift;
    my $lines_ref = shift;

    my $cleaned = $self->trim_comments($lines_ref);

    return School::Code::Compare::Charset::NoWhitespace->new()
                                                       ->filter($cleaned);
}

sub get_numsignes {
    my $self      = shift;
    my $lines_ref = shift;

    my $no_comments = $self->trim_comments($lines_ref);

    # order is important:
    # first create numsigns, then remove whitespace.
    # otherwise "words" will loose their meaning.

    my $ns = School::Code::Compare::Charset::NumSignes->new()
                                                      ->filter($no_comments);

    return School::Code::Compare::Charset::NoWhitespace->new()
                                                       ->filter($ns);
}

sub get_signes {
    my $self      = shift;
    my $lines_ref = shift;

    my $no_comments = $self->trim_comments($lines_ref);

    my $ns = School::Code::Compare::Charset::Signes->new()
                                                   ->filter($no_comments);

    return School::Code::Compare::Charset::NoWhitespace->new()
                                                       ->filter($ns);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

School::Code::Compare::Charset - trim whitespace, comments and unessential chars

=head1 VERSION

version 0.101

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
