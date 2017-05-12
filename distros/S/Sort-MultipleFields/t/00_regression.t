#!perl -w
# $Id: 00_regression.t,v 1.5 2008/07/25 13:25:47 drhyde Exp $

use strict;

use Test::More tests => 19;

use Sort::MultipleFields qw(mfsort mfsortmaker);

my $library = [
    { author => 'Hoyle',  title => 'Black Cloud, The' },
    { author => 'Clarke', title => 'Rendezvous with Rama' },
    { author => 'Clarke', title => 'Prelude to Space' },
    { author => 'Clarke', title => 'Islands In The Sky' },
    { author => 'Asimov', title => 'Pebble in the Sky' },
    { author => 'Asimov', title => 'Foundation' },
    { author => 'Asimov', title => 'David Starr, Space Ranger' }
];
my $numbers = [map { { value => $_ } } qw(100 10 1 11)];

# shortcut aliases
is_deeply(
    scalar(mfsort(sub { author => 'aSc' }, $library)),
    scalar(mfsort(sub { author => 'ascEnding' }, @{$library})),
    "asc == ascending (case-insensitively)"
);
is_deeply(
    scalar(mfsort(sub { author => 'desC' }, $library)),
    scalar(mfsort(sub { author => 'deScending' }, @{$library})),
    "desc == descending (case-insensitively)"
);
is_deeply(
    scalar(mfsort(sub { value => 'numasC' }, $numbers)),
    scalar(mfsort(sub { value => 'nuMascending' }, $numbers)),
    "numasc == numascending (case-insensitively)"
);
is_deeply(
    scalar(mfsort(sub { value => 'numdesC' }, $numbers)),
    scalar(mfsort(sub { value => 'nuMdescending' }, $numbers)),
    "numdesc == numdescending (case-insensitively)"
);

# list/scalar input/output
my @foo = mfsort sub { author => 'desc' }, $library;
ok(@foo == 7, "returns a list in list context");
ok(ref(scalar(mfsort(sub { author => 'desc' }, $library))),
    "returns a ref in scalar context");
is_deeply(
    scalar(mfsort(sub { author => 'asc' }, $library)),
    scalar(mfsort(sub { author => 'asc' }, @{$library})),
    "Records can be listref or list, makes no difference"
);

# shortcuts sort correctly
is_deeply(
    [map { $_->{author} } mfsort(sub { author => 'asc' }, $library)],
    [reverse qw(Hoyle Clarke Clarke Clarke Asimov Asimov Asimov)],
    'asc sorts text correctly'
);
is_deeply(
    [map { $_->{author} } mfsort(sub { author => 'desc' }, $library)],
    [qw(Hoyle Clarke Clarke Clarke Asimov Asimov Asimov)],
    'desc sorts text correctly'
);
is_deeply(
    [map { $_->{value} } mfsort(sub { value => 'asc' }, $numbers)],
    [qw(1 10 100 11)],
    "asc sorts numbers ASCIIbetically"
);
is_deeply(
    [map { $_->{value} } mfsort(sub { value => 'desc' }, $numbers)],
    [reverse qw(1 10 100 11)],
    "desc sorts numbers ASCIIbetically"
);

is_deeply(
    [map { $_->{value} } mfsort(sub { value => 'numasc' }, $numbers)],
    [qw(1 10 11 100)],
    "numasc sorts numerically"
);
is_deeply(
    [map { $_->{value} } mfsort(sub { value => 'numdesc' }, $numbers)],
    [reverse qw(1 10 11 100)],
    "numdesc sorts numerically"
);

# sort function instead of shortcut
is_deeply(
    [map { $_->{author} } mfsort(
        # this should sort C, then H, then A
        sub { author => sub {
            return -1 if($_[0] =~ '^C');
            return  1 if($_[1] =~ '^C');
            return  1 if($_[0] =~ '^A');
            return -1 if($_[1] =~ '^A');
            return  0;
        } },
        $library
    )],
    [qw(Clarke Clarke Clarke Hoyle Asimov Asimov Asimov)],
    'user-supplied sort function works'
);

is_deeply(
    [mfsort sub { author => 'asc', title => 'asc' }, $library],
    [
        { author => 'Asimov', title => 'David Starr, Space Ranger' },
        { author => 'Asimov', title => 'Foundation' },
        { author => 'Asimov', title => 'Pebble in the Sky' },
        { author => 'Clarke', title => 'Islands In The Sky' },
        { author => 'Clarke', title => 'Prelude to Space' },
        { author => 'Clarke', title => 'Rendezvous with Rama' },
        { author => 'Hoyle',  title => 'Black Cloud, The' },
    ],
    "two-field sort works"
);

is_deeply(
    # sort by author, title, and reverse publication date
    [mfsort sub { author => 'asc', title => 'asc', year => 'desc' }, [
        # unsort the input ...
        sort {
            rand() < 0.5 ? -1 : 1
        } map {
            { %{$_}, year => 2001 },
            { %{$_}, year => 2002 },
            { %{$_}, year => 2003 },
        } @{$library}
    ]],
    [
        map {
            { %{$_}, year => 2003 },
            { %{$_}, year => 2002 },
            { %{$_}, year => 2001 },
        } mfsort sub {
            author => 'asc', title => 'asc'
        },  $library
    ],
    "three-field sort works"
);

my $crazysort = sub {
    author => 'asc',
    title => 'asc',
    year => 'desc',
    colour => sub { 
        my @in = map {
            $_ eq 'red'    ? 0 :
            $_ eq 'orange' ? 1 :
            $_ eq 'yellow' ? 2 :
            $_ eq 'green'  ? 3 :
            $_ eq 'blue'   ? 4 :
            $_ eq 'indigo' ? 5 :
                             6
        } @_;
        $in[0] <=> $in[1];
    }
};
my $crazyinput = [
    sort {
        rand() < 0.5 ? -1 : 1
    } map {
        { %{$_}, year => 2001 },
        { %{$_}, year => 2002 },
        { %{$_}, year => 2003 },
    } map {
        my $in = $_;
        map { { %{$in}, colour => $_ } }
            qw(red orange yellow green blue indigo violet)
    } @{$library}
];
my $crazyoutput = [
    map {
        my $in = $_;
        map { { %{$in}, colour => $_ } }
            qw(red orange yellow green blue indigo violet)
    } map {
        { %{$_}, year => 2003 },
        { %{$_}, year => 2002 },
        { %{$_}, year => 2001 },
    } mfsort sub {
        author => 'asc', title => 'asc'
    }, $library
];
is_deeply(
    # sort by author, title, reverse publication date, and colour(!)
    [mfsort \&{$crazysort}, $crazyinput],
    $crazyoutput,
    "four-field sort works, including a Mad Sort"
);

# sort function instead of shortcut
my $usersupplied = mfsortmaker(sub {
    author => sub {
        return -1 if($_[0] =~ '^C');
        return  1 if($_[1] =~ '^C');
        return  1 if($_[0] =~ '^A');
        return -1 if($_[1] =~ '^A');
        return  0;
    }
});
is_deeply(
    [map { $_->{author} } sort $usersupplied @{$library}],
    [qw(Clarke Clarke Clarke Hoyle Asimov Asimov Asimov)],
    'mfsortmaker works'
);

$crazysort = mfsortmaker($crazysort);
is_deeply(
    # sort by author, title, reverse publication date, and colour(!)
    [sort $crazysort @{$crazyinput}],
    $crazyoutput,
    "mfsortmaker even works for a really crazy sort spec"
);
