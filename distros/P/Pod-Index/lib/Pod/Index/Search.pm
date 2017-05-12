package Pod::Index::Search;

use 5.008;
$VERSION = '0.14';

use strict;
use warnings;
use Search::Dict ();
use Pod::Index::Entry;
use Carp qw(croak);
use File::Spec::Functions;

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        %args,
    }, $class;

    if ($self->{filename}) {
        open my $fh, "<", $self->{filename} 
            or die "couldn't open $self->{filename}: $!\n";
        $self->{fh} = $fh;
    }

    unless ($self->{fh}) {
        require perlindex;
        $self->{fh} = *perlindex::DATA;
    }

    $self->{start} = tell $self->{fh};
    $self->{filemap} ||= sub { 
        my ($podname)    = @_;
        my @path_elems   = split /::/, $podname;
        for my $inc (@INC) {
            my $file = catfile($inc, @path_elems);
            return "$file.pod" if -e "$file.pod";
            return "$file.pm"  if -e "$file.pm";
        }
        return undef;
    };

    return $self;
}

sub subtopics {
    my ($self, $keyword, %args) = @_;

    croak "need a keyword " unless defined $keyword;
    my $fh = $self->{fh};

    $self->look($keyword);

    my $i = $self->{nocase} ? 'i' : '';

    my $re_filter = qr/^\Q$keyword\E/i;
    my $re_select = $args{deep} 
        ? qr/^((?$i)\Q$keyword\E,.*)/
        : qr/^((?$i)\Q$keyword\E,[^,]*)/;

    local $_;
    my @ret;
    my %seen;
    while (<$fh>) {
        my ($topic) = split /\t/;
        last unless $topic =~ $re_filter;
        
        if ($topic =~ $re_select and not $seen{$1}++) {
            push @ret, $1;
        }
    }
    return @ret;
}

# hack to make 'look' skip everything before __DATA__:
# everything before start always compares negatively
sub look {
    my ($self, $keyword) = @_;

    my $fh    = $self->{fh};
    my $start = $self->{start};

    # the search is case-insensitive (fold => 1), but the results are filtered
    # later if the user wanted it case-sensitive
    Search::Dict::look($fh, $keyword, {
        comp => sub { 
            tell($fh) <= $start ? -1 : $_[0] cmp $_[1];
        },
        fold => 1,
    });
}

sub search {
    my ($self, $keyword) = @_;

    croak "need a keyword " unless defined $keyword;
    my $fh = $self->{fh};

    $self->look($keyword);

    local $_;
    my @ret;
    my $keyword_lc = lc $keyword;
    my %seen;
    while (<$fh>) {
        chomp;
        my ($entry, $podname, $line, $context) = split /\t/;
        last unless lc $entry eq $keyword_lc;
        next if !$self->{nocase} and $entry ne $keyword;
        next if $seen{"$podname\t$line"}++;
        push @ret, Pod::Index::Entry->new(
            keyword  => $entry,
            podname  => $podname, 
            line     => $line,
            filename => $self->{filemap}($podname),
            context  => $context,
        );
    }
    return @ret;
}


1;

__END__

=head1 NAME

Pod::Index::Search - Search for keywords in an indexed pod

=head1 SYNOPSIS

    use Pod::Index::Search;

    my $q = Pod::Index::Search->new;

    my @results = $q->search('getprotobyname');

    for my $r (@results) {
        printf "%s\t%s\n", $r->podname, $r->line;
        print $r->pod;
    }

    my @subtopics = $q->subtopics('operator');

=head1 DESCRIPTION

This module searches an index created by L<Pod::Index::Builder>. Search results
are returned as L<Pod::Index::Entry> objects.

It is also possible to search for subtopics for a keyword. For example, a
search for "operator" might return things like

    operator, conditional
    operator, filetest
    operator, logical
    operator, precedence
    operator, relational

The subtopics returned are simple strings.

=head1 METHODS

=over

=item new

    my $q = Pod::Index::Search->new(%args);

Create a new search object. Possible arguments are:

=over

=item C<fh>

The filehandle of the index to use. If omitted, C<perlindex::DATA> is used.

=item C<filename>

The filename of the index to use. Note that you can specify either C<fh> or
filename, but not both.

=item C<filemap>

A subroutine reference that takes a podname and returns a filename. A simple
example might be:

    sub {
        my $podname = shift;
        return "/usr/lib/perl5/5.8.7/pod/$podname.pod";
    }

The podname is in colon-delimited Perl package syntax.

The default C<filemap> returns the first file in @INC that seems to have the 
proper documentation (either a .pod or .pm file).

=item C<nocase>

If true, the search will be case-insensitive.

=back

=item search($keyword)

Do the actual search in the index.  Returns a list of search results, as
L<Pod::Index::Entry> objects.

=item subtopics($keyword, %options)

    my @topics = $q->subtopics('operator');
    my @topics = $q->subtopics('operator', deep => 1);

Lists the subtopics for a given keyword. If C<deep> is given, it includes
all subtopics; otherwise, only the first level of subtopics is included.

=back

=head1 VERSION

0.14

=head1 SEE ALSO

L<Pod::Index::Entry>, L<Pod::Index::Builder>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut


