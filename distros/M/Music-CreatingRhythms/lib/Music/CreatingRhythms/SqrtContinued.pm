package Music::CreatingRhythms::SqrtContinued;
$Music::CreatingRhythms::SqrtContinued::VERSION = '0.0700';
our $AUTHORITY = 'cpan:GENE';

use Moo;
use strictures 2;
use OEIS qw(oeis);
use namespace::clean;


has sqrt => (
    is       => 'ro',
    isa      => sub { die "$_[0] is not a positive integer" unless $_[0] =~ /^\d+$/ },
    required => 1,
);


has terms => (
    is       => 'ro',
    isa      => sub { die "$_[0] is not a positive integer" unless $_[0] =~ /^\d+$/ },
    required => 1,
);

# A010171 to A010175 have OFFSET=1, unlike the rest
# OFFSET=0, but still include them in the catalogue for now
my @oeis_anum = (
    undef,     # sqrt=0
    undef,     # sqrt=1
    'A040000', # sqrt=2
    'A040001', # sqrt=3
    undef,     # sqrt=4
    'A040002', # sqrt=5
    'A040003', # sqrt=6
    'A010121', # sqrt=7
    'A040005', # sqrt=8
    undef,     # sqrt=9

    'A040006', # sqrt=10
    'A040007', # sqrt=11
    'A040008', # sqrt=12
    'A010122', # sqrt=13
    'A010123', # sqrt=14
    'A040011', # sqrt=15
    undef,     # sqrt=16
    'A040012', # sqrt=17
    'A040013', # sqrt=18
    'A010124', # sqrt=19

    'A040015', # sqrt=20
    'A010125', # sqrt=21
    'A010126', # sqrt=22
    'A010127', # sqrt=23
    'A040019', # sqrt=24
    undef,     # sqrt=25
    'A040020', # sqrt=26
    'A040021', # sqrt=27
    'A040022', # sqrt=28
    'A010128', # sqrt=29

    'A040024', # sqrt=30
    'A010129', # sqrt=31
    'A010130', # sqrt=32
    'A010131', # sqrt=33
    'A010132', # sqrt=34
    'A040029', # sqrt=35
    undef,     # sqrt=36
    'A040030', # sqrt=37
    'A040031', # sqrt=38
    'A040032', # sqrt=39

    'A040033', # sqrt=40
    'A010133', # sqrt=41
    'A040035', # sqrt=42
    'A010134', # sqrt=43
    'A040037', # sqrt=44
    'A010135', # sqrt=45
    'A010136', # sqrt=46
    'A010137', # sqrt=47
    'A040041', # sqrt=48
    undef,     # sqrt=49

    'A040042', # sqrt=50
    'A040043', # sqrt=51
    'A010138', # sqrt=52
    'A010139', # sqrt=53
    'A010140', # sqrt=54
    'A010141', # sqrt=55
    'A040048', # sqrt=56
    'A010142', # sqrt=57
    'A010143', # sqrt=58
    'A010144', # sqrt=59

    'A040052', # sqrt=60
    'A010145', # sqrt=61
    'A010146', # sqrt=62
    'A040055', # sqrt=63
    undef,     # sqrt=64
    'A040056', # sqrt=65
    'A040057', # sqrt=66
    'A010147', # sqrt=67
    'A040059', # sqrt=68
    'A010148', # sqrt=69

    'A010149', # sqrt=70
    'A010150', # sqrt=71
    'A040063', # sqrt=72
    'A010151', # sqrt=73
    'A010152', # sqrt=74
    'A010153', # sqrt=75
    'A010154', # sqrt=76
    'A010155', # sqrt=77
    'A010156', # sqrt=78
    'A010157', # sqrt=79

    'A040071', # sqrt=80
    undef,     # sqrt=81
    'A040072', # sqrt=82
    'A040073', # sqrt=83
    'A040074', # sqrt=84
    'A010158', # sqrt=85
    'A010159', # sqrt=86
    'A040077', # sqrt=87
    'A010160', # sqrt=88
    'A010161', # sqrt=89

    'A040080', # sqrt=90
    'A010162', # sqrt=91
    'A010163', # sqrt=92
    'A010164', # sqrt=93
    'A010165', # sqrt=94
    'A010166', # sqrt=95
    'A010167', # sqrt=96
    'A010168', # sqrt=97
    'A010169', # sqrt=98
    'A010170', # sqrt=99

    undef,     # sqrt=100
    undef,     # sqrt=101, is 10, 20,20,rep
    undef,     # sqrt=102, is 10, 10,20,10,20,rep
    'A010171', # sqrt=103
    undef,     # sqrt=104, is 10, 5,20,5,20,rep
    undef,     # sqrt=105
    'A010172', # sqrt=106
    'A010173', # sqrt=107
    'A010174', # sqrt=108
    'A010175', # sqrt=109

    undef,     # sqrt=110
    'A010176', # sqrt=111
    'A010177', # sqrt=112
    'A010178', # sqrt=113
    'A010179', # sqrt=114
    'A010180', # sqrt=115
    'A010181', # sqrt=116
    'A010182', # sqrt=117
    'A010183', # sqrt=118
    'A010184', # sqrt=119

    undef,     # sqrt=120
    undef,     # sqrt=121
    undef,     # sqrt=122
    undef,     # sqrt=123
    'A010185', # sqrt=124
    'A010186', # sqrt=125
    'A010187', # sqrt=126
    'A010188', # sqrt=127
    'A010189', # sqrt=128
    'A010190', # sqrt=129

    undef,     # sqrt=130
    'A010191', # sqrt=131
    undef,     # sqrt=132
    'A010192', # sqrt=133
    'A010193', # sqrt=134
    'A010194', # sqrt=135
    'A010195', # sqrt=136
    'A010196', # sqrt=137
    'A010197', # sqrt=138
    'A010198', # sqrt=139

    'A010199', # sqrt=140
    'A010200', # sqrt=141
    'A010201', # sqrt=142
    undef,     # sqrt=143
    undef,     # sqrt=144
    undef,     # sqrt=145
    undef,     # sqrt=146
    undef,     # sqrt=147
    undef,     # sqrt=148
    'A010202', # sqrt=149

    undef,     # sqrt=150
    'A010203', # sqrt=151
    undef,     # sqrt=152
    'A010204', # sqrt=153
    'A010205', # sqrt=154
    undef,     # sqrt=155
    undef,     # sqrt=156
    'A010206', # sqrt=157
    'A010207', # sqrt=158
    'A010208', # sqrt=159

    'A010209', # sqrt=160
    'A010210', # sqrt=161
    'A010211', # sqrt=162
    'A010212', # sqrt=163
    undef,     # sqrt=164
    'A010213', # sqrt=165
    'A010214', # sqrt=166
    'A010215', # sqrt=167
    undef,     # sqrt=168
    undef,     # sqrt=169

    undef,     # sqrt=170
    undef,     # sqrt=171
    'A010216', # sqrt=172
    'A010217', # sqrt=173
    'A010218', # sqrt=174
    'A010219', # sqrt=175
    'A010220', # sqrt=176
    'A010221', # sqrt=177
    'A010222', # sqrt=178
    'A010223', # sqrt=179

    undef,     # sqrt=180
    'A010224', # sqrt=181
    undef,     # sqrt=182
    'A010225', # sqrt=183
    'A010226', # sqrt=184
    'A010227', # sqrt=185
    'A010228', # sqrt=186
    'A010229', # sqrt=187
    'A010230', # sqrt=188
    'A010231', # sqrt=189

    'A010232', # sqrt=190
    'A010233', # sqrt=191
    'A010234', # sqrt=192
    'A010235', # sqrt=193
    'A010236', # sqrt=194
    undef,     # sqrt=195
    undef,     # sqrt=196
    undef,     # sqrt=197
    undef,     # sqrt=198
    'A010237', # sqrt=199
);


sub get_seq {
    my ($self) = @_;
    my $anum = $oeis_anum[ $self->sqrt ];
    my @seq = oeis($anum, $self->terms);
    return \@seq;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::CreatingRhythms::SqrtContinued

=head1 VERSION

version 0.0700

=head1 DESCRIPTION

Replacement for L<Math::NumSeq::SqrtContinued>.

=head1 ATTRIBUTES

=head2 sqrt

The number to take the square-root of.

=head2 terms

The number of terms to return from the OEIS.

=head1 METHOD

=head2 get_seq

Return the OEIS sequence for the B<sqrt> and B<terms> attributes.

=head1 SEE ALSO

L<Moo>

L<OEIS>

L<http://oeis.org/index/Con#confC>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
