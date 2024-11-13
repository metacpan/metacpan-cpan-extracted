package Muster::Hook::Table;
$Muster::Hook::Table::VERSION = '0.92';
use Mojo::Base 'Muster::Hook::Directives';
use Muster::LeafFile;
use Muster::Hooks;
use Encode;

use Carp 'croak';

=head1 NAME

Muster::Hook::Table - Muster table directive.

=head1 VERSION

version 0.92

=head1 DESCRIPTION

L<Muster::Hook::Table> simple table formatting.
This does not implement the data-from-file which the IkiWiki plugin does.

=head1 METHODS

L<Muster::Hook::Table> inherits all methods from L<Muster::Hook::Directives>.

=head2 register

Do some intialization.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{metadb} = $hookmaster->{metadb};

    my $callback = sub {
        my %args = @_;

        return $self->process(%args);
    };
    $hookmaster->add_hook('table' => sub {
            my %args = @_;

            return $self->do_directives(
                no_scan=>1,
                directive=>'table',
                call=>$callback,
                %args,
            );
        },
    );
    return $self;
} # register

=head2 process

Process table formatting.

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};
    my @p = @{$args{params}};
    my %params = (
        format => 'auto',
        header => 'row',
        @p
    );

    # code from IkiWiki
    if (lc $params{format} eq 'auto')
    {
        # first try the more simple format
        if (is_dsv_data($params{data}))
        {
            $params{format} = 'dsv';
        }
        else {
            $params{format} = 'csv';
        }
    }
    my @data;
    if (lc $params{format} eq 'csv')
    {
        @data=split_csv($params{data},
            defined $params{delimiter} ? $params{delimiter} : ",",);
    }
    elsif (lc $params{format} eq 'dsv')
    {
        @data=split_dsv($params{data},
            defined $params{delimiter} ? $params{delimiter} : "|",);
    }
    else
    {
        return __PACKAGE__ . " unknown data format";
    }

    my $header;
    if (lc($params{header}) eq "row" || $params{header} =~ /yes|true|1/i)
    {
        $header=shift @data;
    }
    if (! @data)
    {
        return __PACKAGE__ . "empty data";
    }
    my @lines;
    push @lines, defined $params{class} ? "<table class=\"".$params{class}.'">' : '<table>';
    push @lines, "\t<thead>", 
    $self->genrow(\%params, "th", @$header), "\t</thead>" if defined $header;
    push @lines, "\t<tbody>" if defined $header;
    push @lines, 
    $self->genrow(\%params, "td", @$_) foreach @data;
    push @lines, "\t</tbody>" if defined $header;
    push @lines, '</table>';
    my $html = join("\n", @lines);

    return $html;
} # process

=head2 is_dsv_data

Is the data DSV (delimiter-separated-values)?

=cut
sub is_dsv_data ($) {
    my $text = shift;

    my ($line) = split(/\n/, $text);
    return $line =~ m{.+\|};
}

=head2 split_csv

Use Text::CSV to split the data into lines and columns.

=cut
sub split_csv ($$) {
    my @text_lines = split(/\n/, shift);
    my $delimiter = shift;

    eval q{use Text::CSV};
    croak($@) if $@;
    my $csv = Text::CSV->new({ 
            sep_char	=> $delimiter,
            binary		=> 1,
            allow_loose_quotes => 1,
        }) || croak ("could not create a Text::CSV object");

    my $l=0;
    my @data;
    foreach my $line (@text_lines)
    {
        $l++;
        if ($csv->parse($line))
        {
            push(@data, [ map { decode_utf8 $_ } $csv->fields() ]);
        }
        else
        {
            warn __PACKAGE__, sprintf('parse fail at line %d: %s', 
                    $l, $csv->error_input());
        }
    }

    return @data;
}

=head2 split_dsv

Split the data into lines and columns using delimiters.

=cut
sub split_dsv ($$) {
    my @text_lines = split(/\n/, shift);
    my $delimiter = shift;
    $delimiter="|" unless defined $delimiter;

    my @data;
    foreach my $line (@text_lines)
    {
        push @data, [ split(/\Q$delimiter\E/, $line, -1) ];
    }
    
    return @data;
}

=head2 genrow

Generate a row of the table.

=cut
sub genrow ($@) {
    my $self = shift;
    my %params=%{shift()};
    my $elt = shift;
    my @data = @_;

    my $page=$params{page};
    my $destpage=$params{destpage};

    my @ret;
    push @ret, "\t\t<tr>";
    for (my $x=0; $x < @data; $x++)
    {
        my $cell = $data[$x];
        ##my $cell=IkiWiki::htmlize($page, $destpage, $type,
        ##    IkiWiki::preprocess($page, $destpage, $data[$x]));

        # automatic colspan for empty cells
        my $colspan=1;
        while ($x+1 < @data && $data[$x+1] eq '') {
            $x++;
            $colspan++;
        }

        # check if the first column should be a header
        my $e=$elt;
        if ($x == 0 && lc($params{header}) eq "column") {
            $e="th";
        }

        if ($colspan > 1) {
            push @ret, "\t\t\t<$e colspan=\"$colspan\">$cell</$e>"
        }
        else {
            push @ret, "\t\t\t<$e>$cell</$e>"
        }
    }
    push @ret, "\t\t</tr>";

    return @ret;
}
1;
