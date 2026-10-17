package Test::Consumer::Contract;

=head1 NAME

Test::Consumer::Contract - check a reader against the keys its producer promises

=head1 SYNOPSIS

A distribution declares what its value object promises, who produces it, who
reads it, and why each exception is safe:

    use Test::Consumer::Contract qw(run_consumer_contract);

    run_consumer_contract(
        source        => 'Widget::Maker',
        value_object  => {
            class   => 'Widget',
            from    => { latitude => 1, longitude => 2 },
            derives => { x => 1, y => 2 },
        },
        guaranteed  => [qw(x y)],
        conditional => { colour => 'only the painted path sets it' },
        producers   => { 'lib/Widget/Maker.pm' => [qw(x y colour)] },
        consumers   => {
            'Widget-User/lib/Widget/User.pm' => {
                may_rely_on => {
                    render => { colour => 'defaults to undef on purpose' },
                },
            },
        },
        ignored     => [['Widget-List/', 'reads its own normalised output']],
        accessors   => [qw(x y)],   # documented accessors a consumer may read
        not_accessors => {          # documented, but not a slot of one result
            new             => 'the constructor',
            ACCURACY_LEVELS => 'a class constant',
        },
        inspection  => [qw(can isa DOES)],
    );

    done_testing();

Then it runs these checks:

=over 4

=item 1. the producers still set the keys the contract claims

Each file named in C<producers> (and C<workspace_producers>) is read and each key
it is responsible for must still be assigned there, so a producer that quietly
stops stamping a key fails.

=item 2. registered consumers read only what every producer sets

Each file named in C<consumers> is scanned for reads of a result.  A read of a
key in C<guaranteed> is fine; a read of anything else is reported with its file,
line, sub and the reason the key is a problem, unless the read is registered
under C<may_rely_on> keyed by the name of the enclosing sub.  An entry that is no
longer read is reported as stale, so the registry keeps describing the code.

=item 3. every discovered consumer is registered

Files in sibling distributions that receive a result but are named in neither
C<consumers> nor C<ignored> fail the check, so a new consumer cannot slip past
check 2 unnoticed.

=item 4. the accessor lists match the value object, in both directions

The value object's documented accessors are the C<=head2> (and deeper) headings
of its source and the public subs it defines.  Each one the declaration names in
C<accessors> or C<not_accessors> must be an accessor the value object really has,
and - the direction that matters when a value object grows - each one the value
object documents must be accounted for in C<accessors>, C<not_accessors> or
C<conditional>.  C<conditional> is where a documented accessor belongs when only
some results carry it.  So a value object that gains a documented accessor
cannot leave the declaration behind: the check fails, naming the accessor and the
three places to put it.

=back

Checks 2 and 3 need the sibling distributions that share a workspace; on a
CPAN-style install they skip with a diagnostic and only check 1 runs.  Check 4
needs the value object's own file, which C<include> puts in reach.  This is a
static, lexical check: it reads source, it does not run the producer.

=head1 REQUIREMENTS

The caller must load a test module (L<Test::Most> is what this module uses) and
call C<done_testing()> after C<run_consumer_contract()>; this module adds
subtests but does not end the plan.

=cut

use strict;
use warnings;

use Test::Most;

use Carp qw(croak);
use Cwd qw(abs_path);
use Exporter 'import';
use File::Basename qw(basename dirname);
use File::Find ();
use File::Spec;

our @EXPORT_OK = qw(run_consumer_contract);

our $VERSION = '0.01';

# ---------------------------------------------------------------------------
# The contract
# ---------------------------------------------------------------------------

my @OPTIONS = qw(
	dist_root workspace include source value_object guaranteed conditional
	producers workspace_producers consumers ignored accessors not_accessors
	inspection methods require_workspace
);

=head2 B<new>

Takes the declaration above as a list.  C<source> and C<guaranteed> are
required; every other option has a default:

=over 4

=item C<dist_root>

The distribution being checked.  Defaults to the parent of the directory
holding the running test file, falling back to the current directory when that
is not a distribution root.

=item C<workspace>

The directory holding the sibling distributions.  Defaults to the parent of
C<dist_root>.

Every path in a declaration - in C<include>, C<producers>,
C<workspace_producers>, C<consumers> and C<ignored> - is written with C</>
between the directories, whatever separator the platform itself uses, and the
paths in C<consumers> and C<ignored> are relative to the workspace.  The checks
name files the same way, so a path can be copied from a failure message into the
declaration unchanged.

=item C<include>

Workspace-relative lib directories to put at the front of C<@INC>, so a value
object is read from the checkout in the workspace rather than from an installed
copy.

=item C<conditional>

Key => why it is not guaranteed, used in the failure messages.

=item C<workspace_producers>

Like C<producers>, but paths are relative to the workspace: producers in a
sibling distribution that this distribution's value object comes from.

=item C<not_accessors>

Documented accessors of the value object that are not a slot of one result - the
constructor, a class constant - as name => why, so that the accessor check can be
satisfied by saying what a name is instead of listing it as something a consumer
may read.  A name here that the value object does not document fails, as an entry
in C<accessors> would.

=item C<methods>

The calls that hand a result to the caller; C<geocode> and C<reverse_geocode> by
default.  A variable bound from one of these is followed, as is a variable passed
to a sub as its first parameter.

=item C<require_workspace>

Sibling distribution names that must exist for checks 2 and 3 to run.  Pass the
ones your consumers live in, or those checks cannot tell a missing checkout from
a passing one.

=back

Unknown options are an error rather than being silently ignored.

=cut

sub new
{
	my ($class, %spec) = @_;

	my %known = map { $_ => 1 } @OPTIONS;
	my @unknown = grep { !$known{$_} } sort keys %spec;
	croak(__PACKAGE__ . "::new() does not know the option(s): @unknown") if(@unknown);

	for my $required (qw(source guaranteed)) {
		croak(__PACKAGE__ . "::new() needs a '$required'") unless defined($spec{$required});
	}

	my $dist_root = $spec{'dist_root'} // _default_dist_root();

	my $self = bless {
		dist_root           => $dist_root,
		workspace           => $spec{'workspace'} // dirname($dist_root),
		include             => $spec{'include'} || [],
		source              => $spec{'source'},
		value_object        => $spec{'value_object'},
		guaranteed          => $spec{'guaranteed'} || [],
		conditional         => $spec{'conditional'} || {},
		producers           => $spec{'producers'} || {},
		workspace_producers => $spec{'workspace_producers'} || {},
		consumers           => $spec{'consumers'} || {},
		ignored             => $spec{'ignored'} || [],
		accessors           => $spec{'accessors'} || [],
		not_accessors       => $spec{'not_accessors'} || {},
		inspection          => $spec{'inspection'} || [],
		methods             => $spec{'methods'} || [qw(geocode reverse_geocode)],
		require_workspace   => $spec{'require_workspace'} || [],
	}, $class;

	$self->{'dist_name'} = basename($dist_root);

	# The value object belongs to the workspace, not to an installed copy of the
	# distribution being checked.
	foreach my $dir (@{$self->{'include'}}) {
		my $path = File::Spec->catdir($self->{'workspace'}, split(m{/}, $dir));
		unshift @INC, $path if(-d $path);
	}

	return $self;
}

sub _default_dist_root
{
	my $root = dirname(dirname(abs_path($0)));

	return abs_path(File::Spec->curdir())
		unless -d File::Spec->catdir($root, 'lib');

	return $root;
}

=head2 B<run>

Runs the three checks as subtests.  Called for you by
C<run_consumer_contract()>.

=cut

sub run
{
	my $self = shift;

	$self->_check_producers();
	$self->_check_derivation() if($self->{'value_object'});
	$self->_check_consumers();
	$self->_check_accessors() if($self->{'value_object'});
	$self->_check_discovery();

	return $self;
}

=head2 B<run_consumer_contract>

    my $contract = run_consumer_contract(%declaration);

Builds the contract and runs it, returning the object.

=cut

sub run_consumer_contract
{
	my $contract = __PACKAGE__->new(@_);

	return $contract->run();
}

=head2 B<workspace_present>

True when every distribution named in C<require_workspace> is in the workspace.

=cut

sub workspace_present
{
	my $self = shift;

	return @{$self->{'missing_siblings'}} == 0;
}

sub _missing_siblings
{
	my $self = shift;

	return @{$self->{'missing_siblings'}} if(exists($self->{'missing_siblings'}));

	return @{$self->{'missing_siblings'}} = grep {
		!-d File::Spec->catdir($self->{'workspace'}, $_);
	} @{$self->{'require_workspace'}};
}

# ---------------------------------------------------------------------------
# CHECK 1 - the producers still set what the contract says they set
# ---------------------------------------------------------------------------

sub _slurp
{
	my (undef, $file) = @_;

	open(my $fh, '<', $file) or return;
	local $/;
	my $content = <$fh>;
	close($fh);

	return $content;
}

=head2 B<sets_key>

    $contract->sets_key($source_text, 'database')

True when the text assigns the key, in any of the spellings a producer might
use: C<< key => value >>, C<< 'key' => value >>, C<< $obj->{'key'} = value >>.

=cut

sub sets_key
{
	my (undef, $text, $key) = @_;

	my $k = quotemeta($key);

	# 'key' => value  /  key => value
	return 1 if $text =~ /['"]$k['"]\s*=>/;
	return 1 if $text =~ /(?:^|[\s(,{])$k\s*=>/m;
	# $obj->{'key'} = value  /  $obj->{'key'} //= value
	return 1 if $text =~ /->\s*\{\s*['"]?$k['"]?\s*\}\s*(?:=[^=]|\|\|=|\/\/=)/;

	return 0;
}

# Every producer the declaration names, as path => keys, with the paths
# resolved.  Reported in a stable order, and with the absolute paths of sibling
# producers shown workspace-relative so the messages stay readable.
sub _producer_evidence
{
	my $self = shift;

	my %evidence;
	my %label;

	for my $file (sort keys %{$self->{'producers'}}) {
		my $path = File::Spec->file_name_is_absolute($file)
			? $file
			: File::Spec->catfile($self->{'dist_root'}, split(m{/}, $file));
		$evidence{$path} = $self->{'producers'}{$file};
		$label{$path} = $file;
	}

	for my $file (sort keys %{$self->{'workspace_producers'}}) {
		my $path = File::Spec->catfile($self->{'workspace'}, split(m{/}, $file));
		$evidence{$path} = $self->{'workspace_producers'}{$file};
		$label{$path} = $file;
	}

	return wantarray ? (\%evidence, \%label) : \%evidence;
}

sub _check_producers
{
	my $self = shift;

	my ($evidence, $label) = $self->_producer_evidence();

	return if(!%{$evidence});

	subtest 'the producers still set the keys the contract claims' => sub {
		for my $path (sort keys %{$evidence}) {
			my $file = $label->{$path};
			my $text = $self->_slurp($path);
			ok(defined($text), "$file is readable") or next;

			for my $key (@{$evidence->{$path}}) {
				ok($self->sets_key($text, $key), "$file sets '$key'");
			}
		}
	};
}

# ---------------------------------------------------------------------------
# The value object: the keys it derives itself
# ---------------------------------------------------------------------------

sub _require_class
{
	my (undef, $class) = @_;

	(my $file = $class) =~ s{::}{/}g;

	# The class named in the contract is not known until run time, so its file has
	# to be resolved from a string rather than written as a bareword.
	return eval { require "$file.pm"; 1 } ? 1 : 0;	## no critic (Modules::RequireBarewordIncludes)
}

sub _list
{
	my @items = @_;

	return '' unless @items;
	return $items[0] if(@items == 1);

	return join(', ', @items[0 .. $#items - 1]) . ' and ' . $items[-1];
}

sub _check_derivation
{
	my $self = shift;
	my $spec = $self->{'value_object'};
	my $class = $spec->{'class'};
	my $from = $spec->{'from'} || {};
	my $derives = $spec->{'derives'} || {};

	return if(!%{$derives});

	my $short = lc($class);
	$short =~ s/.*:://;

	subtest "$class derives " . _list(sort keys %{$derives}) => sub {
		plan skip_all => "$class is not available in this checkout"
			unless $self->_require_class($class);

		my $object = $class->new(%{$from});
		ok($object, "a $short can still be made from " . join('/', sort keys %{$from}));

		for my $key (sort keys %{$derives}) {
			is($object->$key(), $derives->{$key}, "$key is derived");
		}
	};
}

# ---------------------------------------------------------------------------
# Reading a consumer
# ---------------------------------------------------------------------------

# Strip POD and comments so that prose about a key is not mistaken for a use of
# it.  Both replacements preserve the line structure, so the line numbers
# reported below point at the real file.
=head2 B<strip>

Returns the source with POD and comments replaced by blank space, preserving
line numbers.

=cut

sub strip
{
	my (undef, $text) = @_;

	$text =~ s{^=[a-zA-Z].*?^=cut[^\n]*$}{ my $m = $&; $m =~ s/[^\n]//g; $m }gems;
	$text =~ s{^[ \t]*\#[^\n]*}{}gm;

	return $text;
}

sub _line_number
{
	my ($text, $pos) = @_;

	# Count on a copy: a /g match here would clobber the caller's position.
	my $prefix = substr($text, 0, $pos);

	return 1 + ($prefix =~ tr/\n//);
}

# The calls that hand a result to a variable, longest name first so that
# 'reverse_geocode' is not matched as 'geocode'.
sub _methods_re
{
	my $self = shift;

	return $self->{'methods_re'} //= do {
		my @methods = sort { length($b) <=> length($a) } @{$self->{'methods'}};
		qr/(?:@{[ join('|', map { quotemeta($_) } @methods) ]})/;
	};
}

sub _sub_ranges
{
	my (undef, $text) = @_;

	my @ranges;
	while($text =~ /^sub\s+(\w+).*?\n.*?^\}/msg) {
		my $name = $1;
		my $start = $-[0];
		my $end = $+[0];
		my $body = substr($text, $start, $end - $start);
		my $param;
		$param = $1 if($body =~ /^\s*my\s+\(?\s*(\$[A-Za-z_]\w*)/m);
		push @ranges, { name => $name, start => $start, end => $end, param => $param };
	}

	return @ranges;
}

sub _enclosing_sub
{
	my ($ranges, $pos) = @_;

	for my $range (@{$ranges}) {
		return $range->{'name'} if($pos >= $range->{'start'} && $pos < $range->{'end'});
	}

	return '(file scope)';
}

=head2 B<reads_of_results>

    my @reads = $contract->reads_of_results($stripped_text);

Every C<< ->{key} >> and C<< ->method() >> read of a variable that holds a
result, as C<[key, line, kind, sub]>.  A variable holds one if it is bound from a
C<geocode()> or C<reverse_geocode()> call, or if it is the first parameter of a
sub that this file calls with such a variable - so a helper that takes the result
still counts, whatever it names it.  One level of that is followed, which is
enough for an adapter; a deeper chain is a sign the read belongs in the
consumer's registry entry.

=cut

sub reads_of_results
{
	my $self = shift;
	my $text = shift;

	my $geocode = $self->_methods_re();

	my %bound;
	while($text =~ /(?:my|our|local)?\s*(\$[A-Za-z_]\w*)\s*=\s*[^;{}]*?->$geocode\s*\(/g) {
		$bound{$1} = 1;
	}

	my @ranges = $self->_sub_ranges($text);
	my %parameter = map { $_->{'name'} => $_->{'param'} }
		grep { defined($_->{'param'}) } @ranges;

	my $found = 1;
	while($found) {
		$found = 0;
		for my $name (sort keys %parameter) {
			my $param = $parameter{$name};
			next if($bound{$param});
			my $n = quotemeta($name);
			next unless grep { $bound{$_} } keys %bound;
			for my $caller_var (sort keys %bound) {
				my $v = quotemeta($caller_var);
				if($text =~ /\b$n\s*\(\s*$v\b/ || $text =~ /\b$n\s*\(\s*\{\s*\w+\s*=>\s*$v\b/) {
					$bound{$param} = 1;
					$found = 1;
					last;
				}
			}
		}
	}

	my @reads;
	for my $var (sort keys %bound) {
		my $v = quotemeta($var);
		while($text =~ /$v\s*->\s*\{\s*['"]?(\w+)['"]?\s*\}/g) {
			my $at = pos($text);
			push @reads, [$1, _line_number($text, $at), 'key', _enclosing_sub(\@ranges, $at)];
		}
		while($text =~ /$v\s*->\s*(\w+)\s*\(/g) {
			my $at = pos($text);
			push @reads, [$1, _line_number($text, $at), 'accessor', _enclosing_sub(\@ranges, $at)];
		}
	}

	return @reads;
}

sub _why
{
	my ($self, $key) = @_;

	return $self->{'conditional'}{$key} if(exists($self->{'conditional'}{$key}));

	return 'no producer in this workspace ever sets it';
}

# ---------------------------------------------------------------------------
# CHECK 2 - registered consumers read only guaranteed keys
# ---------------------------------------------------------------------------

sub _skip_reason
{
	my $self = shift;

	my @missing = $self->_missing_siblings();

	return unless @missing;

	return 'sibling checkouts are not present (' . join(', ', sort @missing) . ')';
}

sub _check_consumers
{
	my $self = shift;

	my %consumers = %{$self->{'consumers'}};
	return if(!%consumers);

	subtest 'registered consumers read only what every backend sets' => sub {
		my $skip = $self->_skip_reason();
		plan skip_all => $skip if($skip);

		for my $rel (sort keys %consumers) {
			my $path = File::Spec->catfile($self->{'workspace'}, split(m{/}, $rel));
			my $raw = $self->_slurp($path);

			ok(defined($raw), "$rel is readable") or next;

			my $may_rely_on = $consumers{$rel}{'may_rely_on'} || {};
			my @reads = $self->reads_of_results($self->strip($raw));
			my %used = map { $_->[3] . '|' . $_->[0] => 1 } @reads;

			my @offenders;
			for my $read (@reads) {
				my ($key, $line, $kind, $sub) = @{$read};

				next if(grep { $_ eq $key } @{$self->{'guaranteed'}});
				next if($may_rely_on->{$sub} && exists($may_rely_on->{$sub}{$key}));
				next if(($kind eq 'accessor')
					&& grep { $_ eq $key } (@{$self->{'accessors'}}, @{$self->{'inspection'}}));

				push @offenders, "$rel line $line in $sub() reads '$key' ($kind) - "
					. $self->_why($key);
			}

			is_deeply(\@offenders, [], "$rel reads only keys every backend sets")
				or diag("\n\t" . join("\n\t", @offenders) . "\n");

			my @stale;
			for my $sub (sort keys %{$may_rely_on}) {
				for my $key (sort keys %{$may_rely_on->{$sub}}) {
					push @stale, "$sub() reads '$key' - " . $may_rely_on->{$sub}{$key}
						unless $used{"$sub|$key"};
				}
			}
			is_deeply(\@stale, [], "$rel still reads the keys it is allowed to rely on")
				or diag("\n\t" . join("\n\t", @stale)
					. "\n\tRemove the stale entry, so the registry keeps describing the code.\n");
		}
	};
}

# ---------------------------------------------------------------------------
# CHECK 3 - no unregistered consumer
# ---------------------------------------------------------------------------

sub _children
{
	my $dir = shift;

	opendir(my $dh, $dir) or return;
	my @entries = grep { $_ ne '.' && $_ ne '..' && !/^\./ } readdir($dh);
	closedir($dh);

	return @entries;
}

sub _workspace_sources
{
	my $self = shift;

	my @files;

	# Assigned before sorting: 'sort _children(...)' would be parsed as a sort
	# with _children for its comparator, and list nothing.
	my @dists = _children($self->{'workspace'});

	for my $dist (sort @dists) {
		next if($dist eq $self->{'dist_name'});

		my $dir = File::Spec->catdir($self->{'workspace'}, $dist);
		next unless -d $dir;

		for my $sub (qw(lib bin t xt)) {
			my $root = File::Spec->catdir($dir, $sub);
			next unless -d $root;

			File::Find::find({
				no_chdir => 1,
				wanted   => sub {
					my $path = $File::Find::name;
					$File::Find::prune = 1 if(-d $path && $self->_skipped_dir($path));
					return unless -f $path;
					return unless $path =~ /\.(?:pm|t|pl|PL|pm6)$/;
					push @files, $self->_ported(File::Spec->abs2rel($path, $self->{'workspace'}));
				},
			}, $root);
		}
	}

	return @files;
}

# A path spelled the way the contract spells paths: relative to the workspace,
# with '/' between the directories whatever the platform uses itself.  Every
# registry key, ignored rule and failure message is written that way, while
# File::Spec->abs2rel() answers with '\' on Windows - passed through unchanged it
# matches none of them, and every consumer is then reported as unregistered.
sub _ported
{
	my (undef, $path) = @_;

	$path =~ s{\\}{/}g;

	return $path;
}

# Directories holding something other than this checkout's source - a build
# product, a bundled copy of a dependency, another version control tree - are not
# descended into.  The name is matched at a separator boundary of either
# spelling, because File::Find names files the platform's way and a '/' never
# appears in a Windows path: matched as only '/', this pruned nothing there and
# the files scanned were the platform's choice rather than the contract's.
sub _skipped_dir
{
	my (undef, $path) = @_;

	return $path =~ m{[/\\](?:blib|xt|inc|local|node_modules|\.git|\.build)$} ? 1 : 0;
}

sub _ignored
{
	my ($self, $rel) = @_;

	for my $rule (@{$self->{'ignored'}}) {
		next unless ref($rule) eq 'ARRAY';
		return $rule->[1] // 1 if(index($rel, $rule->[0]) == 0);
	}

	return;
}

=head2 B<documented_accessors>

    my @names = $contract->documented_accessors($source);

Every name the value object's source documents as part of its interface: its
C<=head2> (and deeper) headings and the public subs it defines.  C<=head1>
headings are left out - they are NAME, VERSION, SEE ALSO and the rest of the
boilerplate, which document no accessor - and so are the private subs, whose
leading underscore keeps them out of the interface.  A method the value object
documents but implements through C<AUTOLOAD> is found by its heading, which is
what makes this the list of what is documented rather than of what is compiled.

=cut

sub documented_accessors
{
	my (undef, $text) = @_;

	my %found;

	while($text =~ /^=head[2-9]\s+(?:B<)?(\w+)/gm) {
		$found{$1} = 1;
	}

	while($text =~ /^sub\s+([A-Za-z]\w*)/gm) {
		$found{$1} = 1;
	}

	return sort keys %found;
}

sub _check_accessors
{
	my $self = shift;
	my @accessors = @{$self->{'accessors'}};
	my %not_accessors = %{$self->{'not_accessors'}};

	return if(!@accessors && !%not_accessors);

	my $spec = $self->{'value_object'};
	my $class = $spec->{'class'};

	subtest 'the accessor list matches the value object' => sub {
		plan skip_all => "$class is not available in this checkout"
			unless $self->_require_class($class);

		(my $inc = $class) =~ s{::}{/}g;
		my $pod = defined($INC{"$inc.pm"}) ? $self->_slurp($INC{"$inc.pm"}) : undef;
		plan skip_all => "$class could not be read" unless defined($pod);

		# What the declaration names is what the value object has: an accessor
		# that has gone, or has been renamed, fails rather than being described.
		for my $accessor (@accessors, sort keys %not_accessors) {
			ok($class->can($accessor) || $pod =~ /^=head2\s+$accessor\b/m
				|| $pod =~ /sub\s+$accessor\b/,
				"$accessor is a documented accessor of $class");
		}

		# And what the value object documents is what the declaration names.
		# Without this direction a value object that gains an accessor leaves the
		# declaration behind, and the next consumer to read the new accessor is
		# covered by a contract that never mentioned it: a read that can be undef
		# on another result would pass check 2 for a key the lists do not know.
		my %accounted = map { $_ => 1 }
			(@accessors, sort keys %not_accessors, sort keys %{$self->{'conditional'}});

		my @unlisted = grep { !$accounted{$_} } $self->documented_accessors($pod);

		is_deeply(\@unlisted, [],
			"$class documents no accessor the contract accounts for nowhere")
			or diag("\n\t$class documents " . _list(map { "'$_'" } @unlisted)
				. ", which this contract does not mention.\n"
				. "\tThe value object and the reader contract have drifted apart.  For each\n"
				. "\tname above: list it in 'accessors' if a consumer may read it off a\n"
				. "\tresult, in 'conditional' with the reason only some results carry it,\n"
				. "\tor in 'not_accessors' with the reason it is not a slot of one result.\n");
	};
}

sub _check_discovery
{
	my $self = shift;
	my $source = $self->{'source'};

	subtest 'every discovered consumer is registered' => sub {
		my $skip = $self->_skip_reason();
		plan skip_all => $skip if($skip);

		my @unregistered;
		my @discovered;
		my $checked = 0;
		for my $rel ($self->_workspace_sources()) {
			my $raw = $self->_slurp(
				File::Spec->catfile($self->{'workspace'}, split(m{/}, $rel)));
			next unless defined($raw);
			next unless $raw =~ /\Q$source\E/;

			$checked++;
			my $text = $self->strip($raw);
			next unless grep { $_->[2] } $self->reads_of_results($text);

			push @discovered, $rel;

			next if(exists($self->{'consumers'}{$rel}));
			next if($self->_ignored($rel));

			push @unregistered, $rel;
		}

		cmp_ok($checked, '>', 0, "found sources mentioning $source ($checked checked)");
		# Without this the whole subtest could pass by finding nothing at all.
		ok(scalar(grep { exists($self->{'consumers'}{$_}) } @discovered),
			'the scanner found the registered consumer (' . scalar(@discovered) . ' read a result)');
		is_deeply(\@unregistered, [], "no unregistered consumer reads a $source result")
			or diag("\n\tunregistered consumers of $source results:\n\t"
				. join("\n\t", @unregistered)
				. "\n\tRegister each in 'consumers' (with its justification) or in"
				. " 'ignored'\n\t(with the reason it cannot receive one).\n");
	};
}

1;
__END__

=head1 LIMITATIONS

=over 4

=item * The scanner is static and lexical.  It follows reads on variables bound
from a producing call plus one level of call into a helper; a result that is
stored in a hash, returned, or passed through two helpers is not followed.

=item * Discovery requires the file to name the source distribution.  A consumer
that is handed results without naming the distribution is not picked up; add it
to C<consumers> by hand.

=item * Files in the C<dist_root> distribution are not scanned for consumption -
its own sources are treated as the producer.  A consumer that lives in the
producing distribution is not discovered.

=item * The producer evidence is static: a producer that sets a key by a route
the three recognised spellings do not cover is reported as not setting it.

=item * C<require_workspace> is what tells a missing checkout apart from a
passing one.  With nothing to require, a distribution checked on its own has no
sibling consumers to find and the discovery check will fail on finding none.

=item * The accessor check reads the value object's own file, so an accessor it
inherits, or documents in another file, is not seen.  A heading or sub that names
something which is not an accessor of a result - a constructor, a constant - has
to be listed in C<not_accessors>, which is what that option is for; the check
then holds the entry to the value object, so a renamed or removed name fails
rather than sitting in the list unread.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
