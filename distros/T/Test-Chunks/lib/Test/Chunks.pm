package Test::Chunks;
use Spiffy 0.24 -Base;
use Spiffy ':XXX';
my @test_more_exports;
BEGIN {
    @test_more_exports = qw(
        ok isnt like unlike is_deeply cmp_ok
        skip todo_skip pass fail
        eq_array eq_hash eq_set
        plan can_ok isa_ok diag
        $TODO
    );
}
use Test::More import => \@test_more_exports;
use Carp;

our @EXPORT = (@test_more_exports, qw(
    is

    chunks next_chunk
    delimiters spec_file spec_string 
    filters filters_delay filter_arguments
    run run_is run_is_deeply run_like run_unlike 
    WWW XXX YYY ZZZ
    tie_output

    find_my_self default_object

    croak carp cluck confess
));

our $VERSION = '0.39';

field '_spec_file';
field '_spec_string';
field _filters => [qw(norm trim)];
field _filters_map => {};
field spec =>
      -init => '$self->_spec_init';
field chunk_list =>
      -init => '$self->_chunk_list_init';
field _next_list => [];
field chunk_delim =>
      -init => '$self->chunk_delim_default';
field data_delim =>
      -init => '$self->data_delim_default';
field _filters_delay => 0;

field chunk_delim_default => '===';
field data_delim_default => '---';

my $default_class;
my $default_object;
my $reserved_section_names = {};

sub default_object { 
    $default_object ||= $default_class->new;
    return $default_object;
}

sub import() {
    my $class = (grep /^-base$/i, @_) 
    ? scalar(caller)
    : $_[0];
    if (not defined $default_class) {
        $default_class = $class;
    }
    else {
        croak "Can't use $class after using $default_class"
          unless $default_class->isa($class);
    }

    if (@_ > 1 and not grep /^-base$/i, @_) {
        my @args = @_;
        shift @args;
        Test::More->import(import => \@test_more_exports, @args);
    }
    
    _strict_warnings();
    goto &Spiffy::import;
}

sub chunk_class  { $self->find_class('Chunk') }
sub filter_class { $self->find_class('Filter') }

sub find_class {
    my $suffix = shift;
    my $class = ref($self) . "::$suffix";
    return $class if $class->can('new');
    $class = __PACKAGE__ . "::$suffix";
    return $class if $class->can('new');
    die "Can't find a class for $suffix";
}

sub check_late {
    if ($self->{chunk_list}) {
        my $caller = (caller(1))[3];
        $caller =~ s/.*:://;
        croak "Too late to call $caller()"
    }
}

sub find_my_self() {
    my $self = ref($_[0]) eq $default_class
    ? splice(@_, 0, 1)
    : default_object();
    return $self, @_;
}

sub chunks() {
    (my ($self), @_) = find_my_self(@_);

    croak "Invalid arguments passed to 'chunks'"
      if @_ > 1;
    croak sprintf("'%s' is invalid argument to chunks()", shift(@_))
      if @_ && $_[0] !~ /^[a-zA-Z]\w*$/;

    my $chunks = $self->chunk_list;
    
    my $section_name = shift || '';
    my @chunks = $section_name
    ? (grep { exists $_->{$section_name} } @$chunks)
    : (@$chunks);

    return scalar(@chunks) unless wantarray;
    
    return (@chunks) if $self->_filters_delay;

    for my $chunk (@chunks) {
        $chunk->run_filters
          unless $chunk->is_filtered;
    }

    return (@chunks);
}

sub next_chunk() {
    (my ($self), @_) = find_my_self(@_);
    my $list = $self->_next_list;
    if (@$list == 0) {
        $list = [@{$self->chunk_list}, undef];
        $self->_next_list($list);
    }
    my $chunk = shift @$list;
    if (defined $chunk and not $chunk->is_filtered) {
        $chunk->run_filters;
    }
    return $chunk;
}

sub filters_delay() {
    (my ($self), @_) = find_my_self(@_);
    $self->_filters_delay(defined $_[0] ? shift : 1);
}

sub delimiters() {
    (my ($self), @_) = find_my_self(@_);
    $self->check_late;
    my ($chunk_delimiter, $data_delimiter) = @_;
    $chunk_delimiter ||= $self->chunk_delim_default;
    $data_delimiter ||= $self->data_delim_default;
    $self->chunk_delim($chunk_delimiter);
    $self->data_delim($data_delimiter);
    return $self;
}

sub spec_file() {
    (my ($self), @_) = find_my_self(@_);
    $self->check_late;
    $self->_spec_file(shift);
    return $self;
}

sub spec_string() {
    (my ($self), @_) = find_my_self(@_);
    $self->check_late;
    $self->_spec_string(shift);
    return $self;
}

sub filters() {
    (my ($self), @_) = find_my_self(@_);
    if (ref($_[0]) eq 'HASH') {
        $self->_filters_map(shift);
    }
    else {    
        my $filters = $self->_filters;
        push @$filters, @_;
    }
    return $self;
}

sub filter_arguments() {
    $Test::Chunks::Filter::arguments;
}

sub have_text_diff {
    eval { require Text::Diff; 1 };
}

sub is($$;$) {
    (my ($self), @_) = find_my_self(@_);
    my ($actual, $expected, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ($ENV{TEST_SHOW_NO_DIFFS} or
         $actual eq $expected or 
         not($self->have_text_diff) or 
         $expected !~ /\n./s
    ) {
        Test::More::is($actual, $expected, $name);
    }
    else {
        $name = '' unless defined $name;
        ok $actual eq $expected,
           $name . "\n" . Text::Diff::diff(\$actual, \$expected);
    }
}

sub run(&) {
    (my ($self), @_) = find_my_self(@_);
    my $callback = shift;
    for my $chunk (@{$self->chunk_list}) {
        $chunk->run_filters unless $chunk->is_filtered;
        &{$callback}($chunk);
    }
}

sub run_is() {
    (my ($self), @_) = find_my_self(@_);
    my ($x, $y) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    for my $chunk (@{$self->chunk_list}) {
        next unless exists($chunk->{$x}) and exists($chunk->{$y});
        $chunk->run_filters unless $chunk->is_filtered;
        is($chunk->$x, $chunk->$y, 
           $chunk->name ? $chunk->name : ()
          );
    }
}

sub run_is_deeply() {
    (my ($self), @_) = find_my_self(@_);
    my ($x, $y) = @_;
    for my $chunk (@{$self->chunk_list}) {
        next unless exists($chunk->{$x}) and exists($chunk->{$y});
        $chunk->run_filters unless $chunk->is_filtered;
        is_deeply($chunk->$x, $chunk->$y, 
           $chunk->name ? $chunk->name : ()
          );
    }
}

sub run_like() {
    (my ($self), @_) = find_my_self(@_);
    my ($x, $y) = @_;
    for my $chunk (@{$self->chunk_list}) {
        next unless exists($chunk->{$x}) and defined($y);
        $chunk->run_filters unless $chunk->is_filtered;
        my $regexp = ref $y ? $y : $chunk->$y;
        like($chunk->$x, $regexp,
             $chunk->name ? $chunk->name : ()
            );
    }
}

sub run_unlike() {
    (my ($self), @_) = find_my_self(@_);
    my ($x, $y) = @_;
    for my $chunk (@{$self->chunk_list}) {
        next unless exists($chunk->{$x}) and defined($y);
        $chunk->run_filters unless $chunk->is_filtered;
        my $regexp = ref $y ? $y : $chunk->$y;
        unlike($chunk->$x, $regexp,
               $chunk->name ? $chunk->name : ()
              );
    }
}

sub _pre_eval {
    my $spec = shift;
    return $spec unless $spec =~
      s/\A\s*<<<(.*?)>>>\s*$//sm;
    my $eval_code = $1;
    eval "package main; $eval_code";
    croak $@ if $@;
    return $spec;
}

sub _chunk_list_init {
    my $spec = $self->spec;
    $spec = $self->_pre_eval($spec);
    my $cd = $self->chunk_delim;
    my @hunks = ($spec =~ /^(\Q${cd}\E.*?(?=^\Q${cd}\E|\z))/msg);
    my $chunks = $self->_choose_chunks(@hunks);
    $self->chunk_list($chunks); # Need to set early for possible filter use
    my $seq = 1;
    for my $chunk (@$chunks) {
        $chunk->chunks_object($self);
        $chunk->seq_num($seq++);
    }
    return $chunks;
}

sub _choose_chunks {
    my $chunks = [];
    for my $hunk (@_) {
        my $chunk = $self->_make_chunk($hunk);
        if (exists $chunk->{ONLY}) {
            return [$chunk];
        }
        next if exists $chunk->{SKIP};
        push @$chunks, $chunk;
        if (exists $chunk->{LAST}) {
            return $chunks;
        }
    }
    return $chunks;
}

sub _check_reserved {
    my $id = shift;
    croak "'$id' is a reserved name. Use something else.\n"
      if $reserved_section_names->{$id} or
         $id =~ /^_/;
}

sub _make_chunk {
    my $hunk = shift;
    my $cd = $self->chunk_delim;
    my $dd = $self->data_delim;
    my $chunk = $self->chunk_class->new;
    $hunk =~ s/\A\Q${cd}\E[ \t]*(.*)\s+// or die;
    my $name = $1;
    my @parts = split /^\Q${dd}\E +(\w+) *(.*)?\n/m, $hunk;
    my $description = shift @parts;
    $description ||= '';
    unless ($description =~ /\S/) {
        $description = $name;
    }
    $description =~ s/\s*\z//;
    $chunk->set_value(description => $description);
    
    my $section_map = {};
    my $section_order = [];
    while (@parts) {
        my ($type, $filters, $value) = splice(@parts, 0, 3);
        $self->_check_reserved($type);
        $value = '' unless defined $value;
        $section_map->{$type} = {
            filters => $filters,
        };
        push @$section_order, $type;
        $chunk->set_value($type, $value);
    }
    $chunk->set_value(name => $name);
    $chunk->set_value(_section_map => $section_map);
    $chunk->set_value(_section_order => $section_order);
    return $chunk;
}

sub _spec_init {
    return $self->_spec_string
      if $self->_spec_string;
    local $/;
    my $spec;
    if (my $spec_file = $self->_spec_file) {
        open FILE, $spec_file or die $!;
        $spec = <FILE>;
        close FILE;
    }
    else {    
        $spec = do { 
            package main; 
            no warnings 'once';
            <DATA>;
        };
    }
    return $spec;
}

# XXX Copied from Spiffy. Refactor at some point.
sub _strict_warnings() {
    require Filter::Util::Call;
    my $done = 0;
    Filter::Util::Call::filter_add(
        sub {
            return 0 if $done;
            my ($data, $end) = ('', '');
            while (my $status = Filter::Util::Call::filter_read()) {
                return $status if $status < 0;
                if (/^__(?:END|DATA)__\r?$/) {
                    $end = $_;
                    last;
                }
                $data .= $_;
                $_ = '';
            }
            $_ = "use strict;use warnings;$data$end";
            $done = 1;
        }
    );
}

sub tie_output() {
    my $handle = shift;
    die "No buffer to tie" unless @_;
    tie $handle, 'Test::Chunks::Handle', $_[0];
}

package Test::Chunks::Handle;

sub TIEHANDLE() {
    my $class = shift;
    bless \ $_[0], $class;
}

sub PRINT {
    $$self .= $_ for @_;
}

#===============================================================================
# Test::Chunks::Chunk
#
# This is the default class for accessing a Test::Chunks chunk object.
#===============================================================================
package Test::Chunks::Chunk;
our @ISA = qw(Spiffy);

our @EXPORT = qw(chunk_accessor);

sub chunk_accessor() {
    my $accessor = shift;
    no strict 'refs';
    return if defined &$accessor;
    *$accessor = sub {
        my $self = shift;
        if (@_) {
            Carp::croak "Not allowed to set values for '$accessor'";
        }
        my @list = @{$self->{$accessor} || []};
        return wantarray
        ? (@list)
        : $list[0];
    };
}

chunk_accessor 'name';
chunk_accessor 'description';
Spiffy::field 'seq_num';
Spiffy::field 'is_filtered';
Spiffy::field 'chunks_object';
Spiffy::field 'original_values' => {};

sub set_value {
    no strict 'refs';
    my $accessor = shift;
    chunk_accessor $accessor
      unless defined &$accessor;
    $self->{$accessor} = [@_];
}

sub run_filters {
    my $map = $self->_section_map;
    my $order = $self->_section_order;
    Carp::croak "Attempt to filter a chunk twice"
      if $self->is_filtered;
    for my $type (@$order) {
        my $filters = $map->{$type}{filters};
        my @value = $self->$type;
        $self->original_values->{$type} = $value[0];
        for my $filter ($self->_get_filters($type, $filters)) {
            $Test::Chunks::Filter::arguments =
              $filter =~ s/=(.*)$// ? $1 : undef;
            my $function = "main::$filter";
            no strict 'refs';
            if (defined &$function) {
                $_ = join '', @value;
                @value = &$function(@value);
                if (not(@value) or 
                    @value == 1 and $value[0] =~ /\A(\d+|)\z/
                ) {
                    @value = ($_);
                }
            }
            else {
                my $filter_object = $self->chunks_object->filter_class->new;
                die "Can't find a function or method for '$filter' filter\n"
                  unless $filter_object->can($filter);
                $filter_object->chunk($self);
                @value = $filter_object->$filter(@value);
            }
            # Set the value after each filter since other filters may be
            # introspecting.
            $self->set_value($type, @value);
        }
    }
    $self->is_filtered(1);
}

sub _get_filters {
    my $type = shift;
    my $string = shift || '';
    $string =~ s/\s*(.*?)\s*/$1/;
    my @filters = ();
    my $map_filters = $self->chunks_object->_filters_map->{$type} || [];
    $map_filters = [ $map_filters ] unless ref $map_filters;
    my @append = ();
    for (
        @{$self->chunks_object->_filters}, 
        @$map_filters,
        split(/\s+/, $string),
    ) {
        my $filter = $_;
        last unless length $filter;
        if ($filter =~ s/^-//) {
            @filters = grep { $_ ne $filter } @filters;
        }
        elsif ($filter =~ s/^\+//) {
            push @append, $filter;
        }
        else {
            @filters = grep { $_ ne $filter } @filters;
            push @filters, $filter;
        }
    }
    return @filters, @append;
}

{
    %$reserved_section_names = map {
        ($_, 1);
    } keys(%Test::Chunks::Chunk::), qw( new DESTROY );
}

#===============================================================================
# Test::Chunks::Filter
#
# This is the default class for handling Test::Chunks data filtering.
#===============================================================================
package Test::Chunks::Filter;
use Spiffy -base;

field 'chunk';

our $arguments;
sub arguments {
    return undef unless defined $arguments;
    my $args = $arguments;
    $args =~ s/(\\[a-z])/'"' . $1 . '"'/gee;
    return $args;
}

sub assert_scalar {
    return if @_ == 1;
    require Carp;
    my $filter = (caller(1))[3];
    $filter =~ s/.*:://;
    Carp::croak "Input to the '$filter' filter must be a scalar, not a list";
}

sub norm {
    $self->assert_scalar(@_);
    my $text = shift || '';
    $text =~ s/\015\012/\n/g;
    $text =~ s/\r/\n/g;
    return $text;
}

sub chomp {
    map { CORE::chomp; $_ } @_;
}

sub unchomp {
    map { $_ . "\n" } @_;
}

sub chop {
    map { CORE::chop; $_ } @_;
}

sub append {
    my $suffix = $self->arguments;
    map { $_ . $suffix } @_;
}

sub trim {
    map {
        s/\A([ \t]*\n)+//;
        s/(?<=\n)\s*\z//g;
        $_;
    } @_;
}

sub base64_decode {
    $self->assert_scalar(@_);
    require MIME::Base64;
    MIME::Base64::decode_base64(shift);
}

sub base64_encode {
    $self->assert_scalar(@_);
    require MIME::Base64;
    MIME::Base64::encode_base64(shift);
}

sub escape {
    $self->assert_scalar(@_);
    my $text = shift;
    $text =~ s/(\\.)/eval "qq{$1}"/ge;
    return $text;
}

sub eval {
    $self->assert_scalar(@_);
    my @return = CORE::eval(shift);
    return $@ if $@;
    return @return;
}

sub eval_stdout {
    $self->assert_scalar(@_);
    my $output = '';
    Test::Chunks::tie_output(*STDOUT, $output);
    CORE::eval(shift);
    no warnings;
    untie *STDOUT;
    return $output;
}

sub eval_stderr {
    $self->assert_scalar(@_);
    my $output = '';
    Test::Chunks::tie_output(*STDERR, $output);
    CORE::eval(shift);
    no warnings;
    untie *STDERR;
    return $output;
}

sub eval_all {
    $self->assert_scalar(@_);
    my $out = '';
    my $err = '';
    Test::Chunks::tie_output(*STDOUT, $out);
    Test::Chunks::tie_output(*STDERR, $err);
    my $return = CORE::eval(shift);
    no warnings;
    untie *STDOUT;
    untie *STDERR;
    return $return, $@, $out, $err;
}

sub exec_perl_stdout {
    my $tmpfile = "/tmp/test-chunks-$$";
    $self->_write_to($tmpfile, @_);
    open my $execution, "$^X $tmpfile 2>&1 |"
      or die "Couldn't open subprocess: $!\n";
    local $/;
    my $output = <$execution>;
    close $execution;
    unlink($tmpfile)
      or die "Couldn't unlink $tmpfile: $!\n";
    return $output;
}

sub _write_to {
    my $filename = shift;
    open my $script, ">$filename"
      or die "Couldn't open $filename: $!\n";
    print $script @_;
    close $script
      or die "Couldn't close $filename: $!\n";
}

sub yaml {
    $self->assert_scalar(@_);
    require YAML;
    return YAML::Load(shift);
}

sub lines {
    $self->assert_scalar(@_);
    my $text = shift;
    return () unless length $text;
    my @lines = ($text =~ /^(.*\n?)/gm);
    return @lines;
}

sub array {
    [@_];
}

sub join {
    my $string = $self->arguments;
    $string = '' unless defined $string;
    CORE::join $string, @_;
}

sub dumper {
    no warnings 'once';
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    Data::Dumper::Dumper(@_);
}

sub strict {
    $self->assert_scalar(@_);
    <<'...' . shift;
use strict;
use warnings;
...
}

sub regexp {
    $self->assert_scalar(@_);
    my $text = shift;
    my $flags = $self->arguments;
    if ($text =~ /\n.*?\n/s) {
        $flags = 'xism'
          unless defined $flags;
    }
    else {
        CORE::chomp($text);
    }
    $flags ||= '';
    my $regexp = eval "qr{$text}$flags";
    die $@ if $@;
    return $regexp;
}

sub get_url {
    $self->assert_scalar(@_);
    my $url = shift;
    CORE::chomp($url);
    require LWP::Simple;
    LWP::Simple::get($url);
}
    
__DATA__

=head1 NAME

Test::Chunks - A Data Driven Testing Framework

=head1 DEPRECATED

NOTE - This module has been deprecated and replaced by Test::Base. This
is basically just a renaming of the module. Test::Chunks was not the
best name for this module. Please discontinue using Test::Chunks and
switch to Test::Base. 

Helpful Hint: change all occurences of C<chunk> to C<block> in your test
code, and everything should work exactly the same.

=head1 SYNOPSIS

    use Test::Chunks;
    use Pod::Simple;

    delimiters qw(=== +++);
    plan tests => 1 * chunks;
    
    for my $chunk (chunks) {
        # Note that this code is conceptual only. Pod::Simple is not so
        # simple as to provide a simple pod_to_html function.
        is(
            Pod::Simple::pod_to_html($chunk->pod),
            $chunk->text,
            $chunk->name, 
        );
    }

    __END__

    === Header 1 Test
    
    This is an optional description
    of this particular test.

    +++ pod
    =head1 The Main Event
    +++ html
    <h1>The Main Event</h1>


    === List Test
    +++ pod
    =over
    =item * one
    =item * two
    =back

    +++ html
    <ul>
    <li>one</li>
    <li>two</li>
    </ul>

=head1 DESCRIPTION

There are many testing situations where you have a set of inputs and a
set of expected outputs and you want to make sure your process turns
each input chunk into the corresponding output chunk. Test::Chunks
allows you do this with a minimal amount of code.

=head1 EXPORTED FUNCTIONS

Test::Chunks extends Test::More and exports all of its functions. So you
can basically write your tests the same as Test::More. Test::Chunks
exports a few more functions though:

=head2 chunks( [data-section-name] )

The most important function is C<chunks>. In list context it returns a
list of C<Test::Chunks::Chunk> objects that are generated from the test
specification in the C<DATA> section of your test file. In scalar
context it returns the number of objects. This is useful to calculate
your Test::More plan.

Each Test::Chunks::Chunk object has methods that correspond to the names
of that object's data sections. There is also a C<name> and a
C<description> method for accessing those parts of the chunk if they
were specified.

C<chunks> can take an optional single argument, that indicates to only
return the chunks that contain a particular named data section.
Otherwise C<chunks> returns all chunks.

    my @all_of_my_chunks = chunks;

    my @just_the_foo_chunks = chunks('foo');

=head2 next_chunk()

You can use the next_chunk function to iterate over all the chunks.

    while (my $chunk = next_chunk) {
        ...
    }

It returns undef after all chunks have been iterated over. It can then
be called again to reiterate.

=head2 run(&subroutine)

There are many ways to write your tests. You can reference each chunk
individually or you can loop over all the chunks and perform a common
operation. The C<run> function does the looping for you, so all you need
to do is pass it a code block to execute for each chunk.

The C<run> function takes a subroutine as an argument, and calls the sub
one time for each chunk in the specification. It passes the current
chunk object to the subroutine.

    run {
        my $chunk = shift;
        is(process($chunk->foo), $chunk->bar, $chunk->name);
    };

=head2 run_is(data_name1, data_name2)

Many times you simply want to see if two data sections are equivalent in
every chunk, probably after having been run through one or more filters.
With the C<run_is> function, you can just pass the names of any two data
sections that exist in every chunk, and it will loop over every chunk
comparing the two sections.

    run_is 'foo', 'bar';

NOTE: Test::Chunks will silently ignore any chunks that don't contain both
sections.

=head2 run_is_deeply(data_name1, data_name2)

Like C<run_is> but uses C<is_deeply> for complex data structure comparison.

=head2 run_like(data_name, regexp | data_name);

The C<run_like> function is similar to C<run_is> except the second
argument is a regular expression. The regexp can either be a C<qr{}>
object or a data section that has been filtered into a regular
expression.

    run_like 'foo', qr{<html.*};
    run_like 'foo', 'match';

=head2 run_unlike(data_name, regexp | data_name);

The C<run_unlike> function is similar to C<run_like>, except the opposite.

    run_unlike 'foo', qr{<html.*};
    run_unlike 'foo', 'no_match';

=head2 delimiters($chunk_delimiter, $data_delimiter)

Override the default delimiters of C<===> and C<--->.

=head2 spec_file($file_name)

By default, Test::Chunks reads its input from the DATA section. This
function tells it to get the spec from a file instead.

=head2 spec_string($test_data)

By default, Test::Chunks reads its input from the DATA section. This
function tells it to get the spec from a string that has been
prepared somehow.

=head2 filters( @filters_list or $filters_hashref )

Specify a list of additional filters to be applied to all chunks. See
C<FILTERS> below.

You can also specify a hash ref that maps data section names to an array
ref of filters for that data type.

    filters {
        xxx => [qw(chomp lines)],
        yyy => ['yaml'],
        zzz => 'eval',
    };

If a filters list has only one element, the array ref is optional.

=head2 filters_delay( [1 | 0] );

By default Test::Chunks::Chunk objects are have all their filters run
ahead of time. There are testing situations in which it is advantageous
to delay the filtering. Calling this function with no arguments or a
true value, causes the filtering to be delayed.

    use Test::Chunks;
    filters_delay;
    plan tests => 1 * chunks;
    for my $chunk (@chunks) {
        ...
        $chunk->run_filters;
        ok($chunk->is_filtered);
        ...
    }

In the code above, the filters are called manually, using the
C<run_filters> method of Test::Chunks::Chunk. In functions like
C<run_is>, where the tests are run automatically, filtering is delayed
until right before the test.

=head2 filter_arguments()

Return the arguments after the equals sign on a filter.

    sub my_filter {
        my $args = filter_arguments;
        # is($args, 'whazzup');
        ...
    }

    __DATA__
    === A test
    --- data my_filter=whazzup

=head2 tie_output()

You can capture STDOUT and STDERR for operations with this function:

    my $out = '';
    tie_output(*STDOUT, $buffer);
    print "Hey!\n";
    print "Che!\n";
    untie *STDOUT;
    is($out, "Hey!\nChe!\n");

=head2 default_object()

Returns the default Test::Chunks object. This is useful if you feel
the need to do an OO operation in otherwise functional test code. See
L<OO> below.

=head2 WWW() XXX() YYY() ZZZ()

These debugging functions are exported from the Spiffy.pm module. See
L<Spiffy> for more info.

=head1 TEST SPECIFICATION

Test::Chunks allows you to specify your test data in an external file,
the DATA section of your program or from a scalar variable containing
all the text input.

A I<test specification> is a series of text lines. Each test (or chunk)
is separated by a line containing the chunk delimiter and an optional
test C<name>. Each chunk is further subdivided into named sections with
a line containing the data delimiter and the data section name. A
C<description> of the test can go on lines after the chunk delimiter but
before the first data section.

Here is the basic layout of a specification:

    === <chunk name 1>
    <optional chunk description lines>
    --- <data section name 1> <filter-1> <filter-2> <filter-n>
    <test data lines>
    --- <data section name 2> <filter-1> <filter-2> <filter-n>
    <test data lines>
    --- <data section name n> <filter-1> <filter-2> <filter-n>
    <test data lines>

    === <chunk name 2>
    <optional chunk description lines>
    --- <data section name 1> <filter-1> <filter-2> <filter-n>
    <test data lines>
    --- <data section name 2> <filter-1> <filter-2> <filter-n>
    <test data lines>
    --- <data section name n> <filter-1> <filter-2> <filter-n>
    <test data lines>

Here is a code example:

    use Test::Chunks;
    
    delimiters qw(### :::);

    # test code here

    __END__
    
    ### Test One
    We want to see if foo and bar
    are really the same... 
    ::: foo
    a foo line
    another foo line

    ::: bar
    a bar line
    another bar line

    ### Test Two
    
    ::: foo
    some foo line
    some other foo line
    
    ::: bar
    some bar line
    some other bar line

    ::: baz
    some baz line
    some other baz line

This example specifies two chunks. They both have foo and bar data
sections. The second chunk has a baz component. The chunk delimiter is
C<###> and the data delimiter is C<:::>.

The default chunk delimiter is C<===> and the default data delimiter
is C<--->.

There are some special data section names used for control purposes:

    --- SKIP
    --- ONLY
    --- LAST

A chunk with a SKIP section causes that test to be ignored. This is
useful to disable a test temporarily.

A chunk with an ONLY section causes only that chunk to be used. This is
useful when you are concentrating on getting a single test to pass. If
there is more than one chunk with ONLY, the first one will be chosen.

A chunk with a LAST section makes that chunk the last one in the
specification. All following chunks will be ignored.

=head1 FILTERS

The real power in writing tests with Test::Chunks comes from its
filtering capabilities. Test::Chunks comes with an ever growing set
of useful generic filters than you can sequence and apply to various
test chunks. That means you can specify the chunk serialization in
the most readable format you can find, and let the filters translate
it into what you really need for a test. It is easy to write your own
filters as well.

Test::Chunks allows you to specify a list of filters. The default
filters are C<norm> and C<trim>. These filters will be applied (in
order) to the data after it has been parsed from the specification and
before it is set into its Test::Chunks::Chunk object.

You can add to the the default filter list with the C<filters> function.
You can specify additional filters to a specific chunk by listing them
after the section name on a data section delimiter line.

Example:

    use Test::Chunks;

    filters qw(foo bar);
    filters { perl => 'strict' };

    sub upper { uc(shift) }

    __END__

    === Test one
    --- foo trim chomp upper
    ...

    --- bar -norm
    ...

    --- perl eval dumper
    my @foo = map {
        - $_;
    } 1..10;
    \ @foo;

Putting a C<-> before a filter on a delimiter line, disables that
filter.

=head2 Scalar vs List

Each filter can take either a scalar or a list as input, and will return
either a scalar or a list. Since filters are chained together, it is
important to learn which filters expect which kind of input and return
which kind of output.

For example, consider the following filter list:

    norm trim lines chomp array dumper eval

The data always starts out as a single scalar string. C<norm> takes a
scalar and returns a scalar. C<trim> takes a list and returns a list,
but a scalar is a valid list. C<lines> takes a scalar and returns a
list. C<chomp> takes a list and returns a list. C<array> takes a list
and returns a scalar (an anonymous array reference containing the list
elements). C<dumper> takes a list and returns a scalar. C<eval> takes a
scalar and creates a list.

A list of exactly one element works fine as input to a filter requiring
a scalar, but any other list will cause an exception. A scalar in list
context is considered a list of one element.

Data accessor methods for chunks will return a list of values when used
in list context, and the first element of the list in scalar context.
This usually does the right thing, but be aware.

=head2 norm

scalar => scalar

Normalize the data. Change non-Unix line endings to Unix line endings.

=head2 trim

list => list

Remove extra blank lines from the beginning and end of the data. This
allows you to visually separate your test data with blank lines.

=head2 chomp

list => list

Remove the final newline from each string value in a list.

=head2 unchomp

list => list

Add a newline to each string value in a list.

=head2 chop

list => list

Remove the final char from each string value in a list.

=head2 append

list => list

Append a string to each element of a list.

    --- numbers lines chomp append=-#\n join
    one
    two
    three

=head2 lines

scalar => list

Break the data into an anonymous array of lines. Each line (except
possibly the last one if the C<chomp> filter came first) will have a
newline at the end.

=head2 array

list => scalar

Turn a list of values into an anonymous array reference.

=head2 join

list => scalar

Join a list of strings into a scalar.

=head2 eval

scalar => list

Run Perl's C<eval> command against the data and use the returned value
as the data.

=head2 eval_stdout

scalar => scalar

Run Perl's C<eval> command against the data and return the
captured STDOUT.

=head2 eval_stderr

scalar => scalar

Run Perl's C<eval> command against the data and return the
captured STDERR.

=head2 eval_all

scalar => list

Run Perl's C<eval> command against the data and return a list of 4
values:

    1) The return value
    2) The error in $@
    3) Captured STDOUT
    4) Captured STDERR

=head2 regexp[=xism]

scalar => scalar

The C<regexp> filter will turn your data section into a regular
expression object. You can pass in extra flags after an equals sign.

If the text contains more than one line and no flags are specified, then
the 'xism' flags are assumed.

=head2 get_url

scalar => scalar

The text is chomped and considered to be a url. Then LWP::Simple::get is
used to fetch the contents of the url.

=head2 exec_perl_stdout

list => scalar

Input Perl code is written to a temp file and run. STDOUT is captured and
returned.

=head2 yaml

scalar => list

Apply the YAML::Load function to the data chunk and use the resultant
structure. Requires YAML.pm.

=head2 dumper

scalar => list

Take a data structure (presumably from another filter like eval) and use
Data::Dumper to dump it in a canonical fashion.

=head2 strict

scalar => scalar

Prepend the string:

    use strict; 
    use warnings;

to the chunk's text.

=head2 base64_decode

scalar => scalar

Decode base64 data. Useful for binary tests.

=head2 base64_encode

scalar => scalar

Encode base64 data. Useful for binary tests.

=head2 escape

scalar => scalar

Unescape all backslash escaped chars.

=head2 Rolling Your Own Filters

Creating filter extensions is very simple. You can either write a
I<function> in the C<main> namespace, or a I<method> in the
C<Test::Chunks::Filter> namespace. In either case the text and any
extra arguments are passed in and you return whatever you want the new
value to be.

Here is a self explanatory example:

    use Test::Chunks;

    filters 'foo', 'bar=xyz';

    sub foo {
        transform(shift);
    }
        
    sub Test::Chunks::Filter::bar {
        my $self = shift;
        my $data = shift;
        my $args = $self->arguments;
        my $current_chunk_object = $self->chunk;
        # transform $data in a barish manner
        return $data;
    }

If you use the method interface for a filter, you can access the chunk
internals by calling the C<chunk> method on the filter object.

Normally you'll probably just use the functional interface, although all
the builtin filters are methods.

=head1 OO

Test::Chunks has a nice functional interface for simple usage. Under the
hood everything is object oriented. A default Test::Chunks object is
created and all the functions are really just method calls on it.

This means if you need to get fancy, you can use all the object
oriented stuff too. Just create new Test::Chunks objects and use the
functions as methods.

    use Test::Chunks;
    my $chunks1 = Test::Chunks->new;
    my $chunks2 = Test::Chunks->new;

    $chunks1->delimiters(qw(!!! @@@))->spec_file('test1.txt');
    $chunks2->delimiters(qw(### $$$))->spec_string($test_data);

    plan tests => $chunks1->chunks + $chunks2->chunks;

    # ... etc

=head1 THE C<Test::Chunks::Chunk> CLASS

In Test::Chunks, chunks are exposed as Test::Chunks::Chunk objects. This
section lists the methods that can be called on a Test::Chunks::Chunk
object. Of course, each data section name is also available as a method.

=head2 name()

This is the optional short description of a chunk, that is specified on the
chunk separator line.

=head2 description()

This is an optional long description of the chunk. It is the text taken from
between the chunk separator and the first data section.

=head2 seq_num()

Returns a sequence number for this chunk. Sequence numbers begin with 1. 

=head2 chunks_object()

Returns the Test::Chunks object that owns this chunk.

=head2 run_filters()

Run the filters on the data sections of the chunks. You don't need to
use this method unless you also used the C<filters_delay> function.

=head2 is_filtered()

Returns true if filters have already been run for this chunk.

=head2 original_values()

Returns a hash of the original, unfiltered values of each data section.

=head1 SUBCLASSING

One of the nicest things about Test::Chunks is that it is easy to
subclass. This is very important, because in your personal project, you
will likely want to extend Test::Chunks with your own filters and other
reusable pieces of your test framework.

Here is an example of a subclass:

    package MyTestStuff;
    use Test::Chunks -Base;

    our @EXPORT = qw(some_func);

    # const chunk_class => 'MyTestStuff::Chunk';
    # const filter_class => 'MyTestStuff::Filter';

    sub some_func {
        (my ($self), @_) = find_my_self(@_);
        ...
    }

    package MyTestStuff::Chunk;
    use base 'Test::Chunks::Chunk';

    sub desc {
        $self->description(@_);
    }

    package MyTestStuff::Filter;
    use base 'Test::Chunks::Filter';

    sub upper {
        $self->assert_scalar(@_);
        uc(shift);
    }

Note that you don't have to re-Export all the functions from
Test::Chunks. That happens automatically, due to the powers of Spiffy.

You can set the C<chunk_class> and C<filter_class> to anything but they
will nicely default as above.

The first line in C<some_func> allows it to be called as either a
function or a method in the test code.

=head1 OTHER COOL FEATURES

Test::Chunks automatically adds

    use strict;
    use warnings;

to all of your test scripts. A Spiffy feature indeed.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
