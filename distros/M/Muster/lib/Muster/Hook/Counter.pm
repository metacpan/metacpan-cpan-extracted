package Muster::Hook::Counter;
$Muster::Hook::Counter::VERSION = '0.93';
=head1 NAME

Muster::Hook::Counter - Muster counter directives.

=head1 VERSION

version 0.93

=head1 DESCRIPTION

L<Muster::Hook::Counter> creates directives "counter"
which makes a freeform query which returns a number,
"wordcount" which gives a wordcount, and
"pagecount" which gives a count of pages.

=cut

use Mojo::Base 'Muster::Hook::Directives';
use Muster::LeafFile;
use Muster::Hooks;
use Muster::Hook::Links;
use File::Basename qw(basename);
use YAML::Any;

use Carp 'croak';

=head1 METHODS

L<Muster::Hook::Counter> inherits all methods from L<Muster::Hook::Directives>.

=head2 register

Do some intialization.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{metadb} = $hookmaster->{metadb};

    $hookmaster->add_hook('pagecount' => sub {
            my %args = @_;

            return $self->do_directives(
                no_scan=>1,
                directive=>'pagecount',
                call=>sub {
                    my %args2 = @_;

                    return $self->process(directive=>'pagecount',%args2);
                },
                %args,
            );
        },
    );
    $hookmaster->add_hook('wordcount' => sub {
            my %args = @_;

            return $self->do_directives(
                no_scan=>1,
                directive=>'wordcount',
                call=>sub {
                    my %args2 = @_;

                    return $self->process(directive=>'wordcount',%args2);
                },
                %args,
            );
        },
    );
    $hookmaster->add_hook('counter' => sub {
            my %args = @_;

            return $self->do_directives(
                no_scan=>1,
                directive=>'counter',
                call=>sub {
                    my %args2 = @_;

                    return $self->process(directive=>'counter',%args2);
                },
                %args,
            );
        },
    );
    return $self;
} # register

=head2 process

Process wordcount/pagecount/counter.

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};
    my $directive = $args{directive};
    my @p = @{$args{params}};
    my %params = @p;
    my $pagename = $leaf->pagename;
    my $show = $params{show};
    delete $params{show};
    my $map_type = (defined $params{map_type} ? $params{map_type} : '');

    if (! exists $params{pages}
            and ! exists $params{titles}
            and ! exists $params{pagenames}
            and ! exists $params{where}
            and ! exists $params{sql})
    {
	return "ERROR: missing parameter";
    }
    if ($phase ne $Muster::Hooks::PHASE_BUILD)
    {
        return "";
    }

    # pagecount: get the count of pages matching the condition
    # wordcount: get the sum of the wordcount of pages matching the condition
    my $total = 0;
    if ($directive eq 'pagecount')
    {
        my @matching_pages = ();
        if (exists $params{pages})
        {
            my $pages = $self->{metadb}->query_pagespec($params{pages});
            @matching_pages = @{$pages} if $pages;
        }
        elsif (exists $params{titles} and exists $params{relto})
        {
            # titles are separated by | and may have spaces which should be _
            $params{titles} =~ s/ /_/g;
            @matching_pages =
            map { $self->{metadb}->bestlink($params{relto}, $_) } split /\|/, $params{titles};
        }
        elsif (exists $params{pagenames})
        {
            @matching_pages =
            map { $self->{metadb}->bestlink($pagename, $_) } split ' ', $params{pagenames};
        }
        elsif (exists $params{where})
        {
            my $pages = $self->{metadb}->query("SELECT page FROM pagefiles WHERE " . $params{where});
            @matching_pages = @{$pages} if $pages;
        }

        $total = scalar @matching_pages;
    }
    elsif ($directive eq 'wordcount')
    {
        my $where = '';
        if (exists $params{pages})
        {
            $where = $self->{metadb}->pagespec_translate($params{pages});
        }
        elsif (exists $params{titles})
        {
            # titles are separated by | and may have spaces
            $where = "title REGEXP '(" . $params{titles} . ")'";
        }
        elsif (exists $params{pagenames})
        {
            # pagenames are separated by spaces
            my $re = $params{pagenames};
            $re =~ s/ /\|/g;
            $where = "page REGEXP '($re)'";
        }
        elsif (exists $params{where})
        {
            $where = $params{where};
        }
        my $ret = $self->{metadb}->query("SELECT SUM(wordcount) FROM flatfields WHERE " . $where);
        $total = (scalar @{$ret} ? $ret->[0] : 0);
    }
    elsif (exists $params{sql})
    {
        my $ret = $self->{metadb}->query($params{sql});
        $total = (scalar @{$ret} ? $ret->[0] : 0);
    }

    my $result = $total;
    # only prepend if the result isn't zero
    if ($params{prepend} and $total > 0)
    {
        $result = $params{prepend} . $result;
    }
    return $result;
} # process

1;
