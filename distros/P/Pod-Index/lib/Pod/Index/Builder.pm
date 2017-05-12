package Pod::Index::Builder;

use 5.008;
$VERSION = '0.14';

use strict;
use warnings;

use base qw(Pod::Parser);
use Pod::Index::Entry;
use File::Spec;

####### Pod::Parser overriden methods

sub begin_input {
    my ($self) = @_;
    $self->{pi_breadcrumbs} = [];
}

sub verbatim {
    #my ($self, $text, $line_num, $pod_para) = @_;
    # do nothing
}

sub textblock {
    my ($self, $text, $line_num, $pod_para) = @_;
    $self->{pi_pos} = [$pod_para->file_line, [ @{$self->{pi_breadcrumbs}} ] ];
    $self->interpolate($text, $line_num);
    return;
}

sub command {
    my ($self, $cmd, $text, $line_num, $pod_para)  = @_;
    my $breadcrumbs = $self->{pi_breadcrumbs};
    if ($cmd =~ /head(\d)/) {
        my $level = $1;
        splice @$breadcrumbs, $level-1 if @$breadcrumbs >= $level;
        $self->{pi_pos} = [$pod_para->file_line, [ @$breadcrumbs ] ];
        my $s = $self->interpolate($text, $line_num);
        $self->{pi_breadcrumbs}[$level - 1] = $s;
    } else {
        $self->{pi_pos} = [$pod_para->file_line, [ @$breadcrumbs ] ];
        $self->interpolate($text, $line_num);
    }
    return;
}

sub interior_sequence { 
    my ($self, $seq_command, $seq_argument, $seq_obj) = @_ ;
    if ($seq_command eq 'X') {
        $self->add_entry($seq_argument);
        return '';
    }
    return $seq_argument;
}


###### new methods

sub pod_index { shift->{pi_pod_index} }

sub add_entry {
    my ($self, $keyword) = @_;

    my ($filename, $line, $breadcrumbs) = @{$self->{pi_pos}};

    my $podname = $self->path2package($filename);

    my $context = $breadcrumbs->[-1];
    $context = '' unless defined $context;
    $context =~ s/\n.*//s;

    my $entry = Pod::Index::Entry->new(
        keyword  => $keyword,
        filename => $filename,
        podname  => $podname,
        line     => $line,
        context  => $context,
    );

    push @{$self->{pi_pod_index}{lc $keyword}}, $entry;
}

sub path2package {
    my ($self, $pathname) = @_;

    my $relname = File::Spec->abs2rel($pathname, $self->{pi_base});

    my ($volume, $dirstring, $file) = File::Spec->splitpath($relname);
    my @dirs = File::Spec->splitdir($dirstring);

    pop @dirs if ($dirs[-1] eq ''); # in case there was a trailing slash
    $file =~ s/\.\w+$//;

    my $package = join('::',@dirs,$file);
    return $package;
}

sub print_index {
    my ($self, $f) = @_;

    # figure out filehandle
    my $fh;
    if ($f and !ref $f) {
        open $fh, ">", $f or die "couldn't open $f: $!\n";
    } elsif ($f) {
        $fh = $f;
    } else {
        $fh ||= *STDOUT;
    }

    # print out the index
    my $idx = $self->pod_index;
    for my $key (
        sort { 
            $a cmp $b 
            or $idx->{$a}{keyword} cmp $idx->{$b}{keyword}
        } keys %$idx
    ) {
        for my $entry (
            sort {
                $a->{podname} cmp $b->{podname}
                or $a->{line} <=> $b->{line} 
            } @{$idx->{$key}}
        ) {
            print $fh join("\t", @$entry{qw(keyword podname line context)}), "\n";
        }
    }
}

1;

__END__

=head1 NAME

Pod::Index::Builder - Build a pod index

=head1 SYNOPSIS

    use Pod::Index::Builder;

    my $p = Pod::Index::Builder->new(
        pi_base => $base_path,
    );
    for my $file (@ARGV) {
        $p->parse_from_file($file);
    }

    $p->print_index;

=head1 DESCRIPTION

This is a subclass of L<Pod::Parser> that reads POD and outputs nothing.
However, it saves the position of every XE<lt>> entry it sees. The index can be
retrieved as a hashref, or printed in a format that is understandable by
L<Pod::Index::Search>.

=head1 METHODS

=over

=item new

The constructor, inherited from L<Pod::Parser>. The only optional argument
that X<Pod::Index> cares about is C<pi_base>. If given, it is used as a base
when converting pathnames to package names. For example, if C<pi_path> = "lib",
the filename F<lib/Pod/Index.pm> will turn into C<Pod::Index>, instead of
the undesirable C<lib::Pod::Index>.


=item pod_index

Retrieves the index as a hashref. The hash keys are the keywords contained in
the XE<lt>> tags, I<normalized to lowercase>; the values are array references
of L<Pod::Index::Entry> objects.

=item print_index

    $parser->print_index($fh);
    $parser->print_index($filename);
    $parser->print_index();

Prints the index to the given output filename or filehandle (or STDOUT by
default). The format is tab-delimited, with the following columns:

    1) keyword
    2) podname 
    3) line number
    4) context (title of section containing this entry)

The index is sorted by keyword in a case-insensitive way.

=back

=head1 VERSION

0.14

=head1 SEE ALSO

L<Pod::Index>,
L<Pod::Index::Entry>,
L<Pod::Index::Search>,
L<Pod::Parser>,
L<perlpod>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

