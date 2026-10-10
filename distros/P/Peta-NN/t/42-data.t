use v5.36;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use Peta::NN::Data;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Records with named fields: what models are trained on and measured by.

my $dir = tempdir(CLEANUP => 1);
open my $out, '>:encoding(UTF-8)', "$dir/nouns.tsv" or die $!;
print $out "# singular\tgender\tplural\tlisted\n";
print $out join("\t", @$_), "\n" for [qw(apfel masculine äpfel äpfel)], [qw(haus neuter häuser häuser)], [qw(frau feminine frauen)],
                                    map { [ "wort$_", 'neuter', "wort${_}e" ] } 1 .. 400;
close $out;

my $nouns = Peta::NN::Data->read("$dir/nouns.tsv", fields => [qw(singular gender plural listed)]);
is($nouns->count, 403, 'read: one record a line, the comment line not among them');
is_deeply([ $nouns->fields ], [qw(singular gender plural listed)], 'read: the fields as named');
is_deeply(($nouns->records)[0], { singular => 'apfel', gender => 'masculine', plural => 'äpfel', listed => 'äpfel' }, 'read: a record is a table of its fields');
is(($nouns->records)[2]{listed}, '', 'read: a missing last field is empty');
is_deeply([ ($nouns->values_of('gender'))[ 0 .. 2 ] ], [qw(masculine neuter feminine)], 'values_of: one field of every record');
ok(!eval { $nouns->values_of('genus'); 1 }, 'a field that is not there is refused');
like($@, qr/no field 'genus' \(there are: singular gender plural listed\)/, '... naming those that are');
ok(!eval { Peta::NN::Data->read("$dir/nouns.tsv", fields => [qw(singular gender)]); 1 }, 'read: more columns than names is refused');
ok(!eval { Peta::NN::Data->read("$dir/nowhere.tsv", fields => ['a']); 1 }, 'read: a file that is not there is refused');

# --- new fields, and views ------------------------------------------------------
is($nouns->derive(letters => sub ($noun) { length $noun->{singular} }), $nouns, 'derive returns the data');
is(($nouns->records)[1]{letters}, 4, 'derive: a field worked out from each record');
is_deeply([ $nouns->fields ], [qw(singular gender plural listed letters)], 'derive: and it is a field now');
my $short = $nouns->where(sub ($noun) { $noun->{letters} < 5 });
is_deeply([ $short->values_of('singular') ], [qw(haus frau)], 'where: a view of the records a sub accepts');
is($nouns->count, 403, 'where: the data it was taken from is as it was');
is($nouns->sample(10)->count, 10, 'sample: as many as asked for');
is_deeply([ $nouns->sample(10)->values_of('singular') ], [ $nouns->sample(10)->values_of('singular') ], 'sample: the same ones every time');
is($nouns->sample(1000)->count, 403, 'sample: no more than there are');

# --- held out ----------------------------------------------------------------------
is($nouns->hold_out(0.1), $nouns, 'hold_out returns the data');
my ($held, $shown) = ($nouns->held->count, $nouns->shown->count);
is($held + $shown, 403, 'every record is either held out or shown');
cmp_ok($held, '>=', 20, "about a tenth is held out ($held of 403)");
cmp_ok($held, '<=', 65, '... and no more');
my %side = map { $_->{singular} => $nouns->is_held($_) } $nouns->records;
my $again = Peta::NN::Data->read("$dir/nouns.tsv", fields => [qw(singular gender plural listed)])->hold_out(0.1);
is_deeply({ map { $_->{singular} => $again->is_held($_) } $again->records }, \%side, 'the same records are held out when the data is read again');
is($short->held->count + $short->shown->count, 2, 'a view knows which of its records are held out');
$nouns->hold_out(0.5, by => 'gender');
my %by_gender;
$by_gender{ $_->{gender} }{ $nouns->is_held($_) } = 1 for $nouns->records;
ok(!grep({ keys %$_ > 1 } values %by_gender), 'held out by a field: records that share its value are on one side');
$nouns->hold_out(0.3, by => sub ($noun) { substr $noun->{singular}, 0, 4 });
my %wort = map { $nouns->is_held($_) => 1 } grep { $_->{singular} =~ /\Awort/ } $nouns->records;
is(scalar keys %wort, 1, 'held out by what a sub gives: all the wort... on one side');
ok(!eval { $nouns->hold_out(1.5); 1 }, 'a share that is no share is refused');
ok(!eval { $nouns->hold_out(0.1, by => 'genus'); 1 }, 'holding out by a field that is not there is refused');

# --- marked ---------------------------------------------------------------------------
is($nouns->mark(core => sub ($noun) { length $noun->{listed} }, long => sub ($noun) { $noun->{letters} > 5 }), $nouns, 'mark returns the data');
is_deeply([ $nouns->marks ], [qw(core long)], 'the names of the groups');
is_deeply([ $nouns->marked('core')->values_of('singular') ], [qw(apfel haus)], 'marked: a view of a group');
ok($nouns->is_marked(core => ($nouns->records)[0]) && !$nouns->is_marked(core => ($nouns->records)[2]), 'is_marked: for one record');
is($short->marked('core')->count, 1, 'a view knows which of its records are marked');
ok(!eval { $nouns->marked('heads'); 1 }, 'a group that was never marked is refused');
$nouns->hold_out(0.5, never => 'long');
is($nouns->marked('long')->held->count, 0, 'hold_out, never => a mark: none of its records is held out');
cmp_ok($nouns->held->count, '>', 0, '... and of the others some are');
ok(!eval { $nouns->hold_out(0.5, never => 'heads'); 1 }, '... a mark that is not there is refused');
$nouns->hold_out_if(sub ($noun) { $noun->{gender} eq 'feminine' });
is_deeply([ $nouns->held->values_of('singular') ], ['frau'], 'hold_out_if: the records a sub accepts, and no others');

# --- pairs -------------------------------------------------------------------------------
is_deeply($nouns->where(sub ($noun) { $noun->{singular} !~ /\Awort/ })->pairs(from => 'singular', to => 'plural', given => ['gender']),
          [ [qw(apfel äpfel masculine)], [qw(haus häuser neuter)], [qw(frau frauen feminine)] ], 'pairs: what a model reads, what it answers, what it is given');
is_deeply($short->pairs(from => 'plural', to => 'singular'), [ [qw(häuser haus)], [qw(frauen frau)] ], 'pairs: without anything given, and the other way round');
ok(!eval { $nouns->pairs(from => 'singular'); 1 }, 'pairs: without `to` refused');
ok(!eval { $nouns->pairs(from => 'singular', to => 'plural', given => ['case']); 1 }, 'pairs: given a field that is not there refused');

# --- made from records ---------------------------------------------------------------------
my $made = Peta::NN::Data->new(records => [ { word => 'a', language => 'ces' }, { word => 'the', language => 'eng' } ]);
is_deeply([ $made->fields ], [qw(language word)], 'new: from records, the fields are theirs');
is_deeply($made->pairs(from => 'word', to => 'language'), [ [qw(a ces)], [qw(the eng)] ], 'new: and pairs come from them');

done_testing;
