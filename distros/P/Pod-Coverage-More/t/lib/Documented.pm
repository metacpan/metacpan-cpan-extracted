package Documented;

# One sub per case of the checks of Pod::Coverage::More.  t/Pod-Coverage-More.t states the failures of each.

use 5.036;
use warnings FATAL => q{all};

use Types::Standard qw{assert_Int assert_Num};

=head1 FUNCTIONS

=head2 good(count, label)

=over 4

=item count - Int - how many

=item label - Str - what to call them

=back

Returns Str.  Dies when the label is empty.

    my $text = Documented::good( 3, 'apples' );

=cut

sub good {
    my ( $count, $label ) = @_;
    assert_Int($count);
    die "label is empty\n" if $label eq q{};
    return "$label: $count";
}

=head2 narrower(count)

=over 4

=item count - Int - documented narrower than the Num that the code checks

=back

=cut

sub narrower {
    my ($count) = @_;
    assert_Num($count);
    return;
}

=head2 broader(count)

=over 4

=item count - Num - documented broader than the Int that the code checks

=back

=cut

sub broader {
    my ($count) = @_;
    assert_Int($count);
    return;
}

=head2 contradicted(list)

=over 4

=item list - HashRef - documented as a hash reference, used as an array reference

=back

Returns Int.

=cut

sub contradicted {
    my ($list) = @_;
    return scalar @$list;
}

=head2 undocumented_return

Says nothing about what it returns.

=cut

sub undocumented_return {
    return 1;
}

=head2 wrong_return

Returns HashRef.

=cut

sub wrong_return {
    return [];
}

=head2 maybe_return(flag)

=over 4

=item flag - Bool - whether to return the hash reference

=back

Returns HashRef or undef.

=cut

sub maybe_return {
    my ($flag) = @_;
    return $flag ? {} : undef;
}

=head2 says_nothing

Returns nothing.

=cut

sub says_nothing {
    return 1;
}

=head2 dies_quietly

Never mentions how it fails.

=cut

sub dies_quietly {
    die "always\n";
}

=head2 first_of(cat, catalog), second_of(dog)

=over 4

=item catalog - Str - an argument whose name starts with that of another

=item cat - Int - documented after the longer name

=item dog - number of cats, with no type

=back

=cut

sub first_of {
    my ( $cat, $catalog ) = @_;
    return;
}

sub second_of {
    my ($dog) = @_;
    return;
}

=method woven(size)

=over 4

=item size - Int - documented under a command of Pod::Weaver

=back

=head3 Caveats

A deeper heading stays part of the section.

Returns Int.

=cut

sub woven {
    my ($size) = @_;
    return $size;
}

=head2 overloaded_double(x)

=over 4

=item x - Any - a number, or an object of a class that overloads multiplication

=back

Returns a Money object.

=cut

sub overloaded_double {
    my ($x) = @_;
    return $x * 2;
}

=head2 weak_contradicted(x)

=over 4

=item x - Num - the number

=back

Returns HashRef.

=cut

sub weak_contradicted {
    my ($x) = @_;
    return $x + 1;
}

=head2 shouty(%ARGS)

The arguments in upper case, as POD often writes them.

=cut

sub shouty {
    my (%args) = @_;
    return;
}

=head2 flag(x)

=over 4

=item x - Any - anything

=back

Returns Bool.

=cut

sub flag {
    my ($x) = @_;
    return $x ? 1 : 0;
}

=head2 not_flag

Returns Bool.

=cut

sub not_flag {
    return 5;
}

=head2 field_reader(colour)

=over 4

=item colour - Str - a field of the object, which is no argument

=back

Returns the colour.

=cut

sub field_reader {
    my ($self) = @_;
    return $self->{colour};
}

=head2 stub(thing)

A default that a subclass overrides, which ignores its argument.

=cut

sub stub {
    return;
}

=head2 empty_signature(thing)

Its signature says that it takes nothing.

=cut

sub empty_signature () {
    return;
}

=head2 placeholder_method(snapshot)

=over 4

=item snapshot - HashRef - what it ignores, which its signature does not name

=back

    $object->placeholder_method( {} );

=cut

sub placeholder_method ( $self, $ ) {
    $self->{called} = 1;
    return;
}

=head2 placeholders(first, second)

=over 4

=item first - Str - ignored

=item second - Str - ignored too

=back

    Documented::placeholders( 'a', 'b' );

=cut

sub placeholders ( $, $ ) {
    return;
}

=head2 placeholder_sigils($snapshot)

    $object->placeholder_sigils( {} );

=cut

sub placeholder_sigils ( $self, $ ) {
    $self->{called} = 1;
    return;
}

=head2 placeholder_extra(snapshot, extra)

=over 4

=item snapshot - HashRef - ignored

=item extra - Str - which the sub does not take

=back

    $object->placeholder_extra( {}, 'x' );

=cut

sub placeholder_extra ( $self, $ ) {
    $self->{called} = 1;
    return;
}

=head2 relay_function(thing)

=over 4

=item thing - Str - what to pass on

=back

Returns nothing, as stub does.

    Documented::relay_function('a');

=cut

sub relay_function ($thing) {
    return stub($thing);
}

=head2 relay_method(thing)

=over 4

=item thing - Str - what to pass on

=back

Returns nothing, as the method stub does.

    $object->relay_method('a');

=cut

sub relay_method ( $self, $thing ) {
    return $self->stub($thing);
}

=head2 relay_or_variable(thing)

=over 4

=item thing - Str - what to pass on, or return

=back

Returns nothing.

    Documented::relay_or_variable('a');

=cut

sub relay_or_variable ($thing) {
    return stub($thing) if !defined $thing;
    return $thing;
}

=head2 list_elements(snapshot, paths)

=over 4

=item snapshot - HashRef - what to look in

=item @paths - Str - each path to look for

=back

    my @missing = Documented::list_elements( {}, 'a', 'b' );

Returns the paths that the snapshot does not have.

=cut

sub list_elements ( $snapshot, @paths ) {
    return grep { !$snapshot->{$_} } @paths;
}

=head2 scalar_as_list(path)

=over 4

=item @path - Str - which is one path, and no list

=back

    my $path = Documented::scalar_as_list('a');

Returns the path.

=cut

sub scalar_as_list ($path) {
    return $path;
}

=head2 records(names)

=over 4

=item names - ArrayRef[Str] - whose records to make

=back

Returns ArrayRef[HashRef], one record for each name.

    my $records = Documented::records( ['a'] );

=cut

sub records ($names) {
    return [ map { { name => $_ } } @$names ];
}

=head2 records_as_hash(names)

=over 4

=item names - ArrayRef[Str] - whose records to make

=back

Returns HashRef[HashRef], which is no array.

    my $records = Documented::records_as_hash( ['a'] );

=cut

sub records_as_hash ($names) {
    return [ map { { name => $_ } } @$names ];
}

=head2 anonymous_slurpy(wait, seconds)

=over 4

=item wait - Int - ignored, as the signature takes it in a slurpy with no name

=item seconds - Int - ignored too

=back

    $object->anonymous_slurpy( 1, 2 );

=cut

sub anonymous_slurpy ( $self, @ ) {
    $self->{called} = 1;
    return;
}

=head2 named_before_anonymous_slurpy(count, colour, size)

=over 4

=item count - Int - how many

=item colour - Str - ignored, as the signature takes it in a slurpy with no name

=item size - Int - ignored too

=back

    $object->named_before_anonymous_slurpy( 1, colour => 'red', size => 2 );

=cut

sub named_before_anonymous_slurpy ( $self, $count, % ) {
    $self->{count} = $count;
    return;
}

=head2 anonymous_slurpy_misnamed(total, options)

=over 4

=item total - Int - which is no parameter

=item options - HashRef - ignored

=back

    $object->anonymous_slurpy_misnamed( 1, {} );

=cut

sub anonymous_slurpy_misnamed ( $self, $count, @ ) {
    $self->{count} = $count;
    return;
}

=head2 undef_placeholder(elem, doc)

=over 4

=item elem - Str - what it returns

=item doc - HashRef - ignored, as the list assignment puts it in undef

=back

Returns Str, the element.

    my $elem = $object->undef_placeholder( 'a', {} );

=cut

sub undef_placeholder {
    my ( $self, $elem, undef ) = @_;
    return "$elem";
}

my sub unanswered ( $class, $what ) {
    die "$class does not answer $what\n";
}

=head2 $class->abstract_merge(@sources)

The interface that subclasses implement.

=over 4

=item @sources - HashRef - each source

=back

Returns a list of HashRef.

    my @merged = $class->abstract_merge( {} );

=cut

sub abstract_merge {
    my ($class) = @_;
    return unanswered( $class, 'abstract_merge' );
}

=head2 $class->abstract_ports(%opts)

The interface that subclasses implement.

=over 4

=item %opts - Int - each option

=back

Returns a list of Int.  Dies in this class, which does not answer it.

    my @ports = $class->abstract_ports( tls_port => 443 );

=cut

sub abstract_ports {
    my ($self) = @_;
    die ref($self) || $self, " does not answer abstract_ports\n";
}

=head2 $object->invocant_only(%opts)

=over 4

=item %opts - Str - which it does not take

=back

Returns Str.

    my $colour = $object->invocant_only( shade => 'dark' );

=cut

sub invocant_only {
    my ($self) = @_;
    return "$self->{colour}";
}

=head2 $class->abstract_shifted(@questions)

The interface that subclasses implement.

=over 4

=item @questions - Str - each question

=back

Returns a list of Str.

    my @answers = $class->abstract_shifted('why');

=cut

sub abstract_shifted {
    return unanswered( shift, 'abstract_shifted' );
}

=head2 $sum = Documented->assigned_heading($x, $y)

Returns Int.

    my $sum = Documented->assigned_heading( 1, 2 );

=cut

sub assigned_heading {
    my ( $class, $x, $y ) = @_;
    return int( $x + $y );
}

=head2 @pairs = Documented->assigned_heading_alone(%opts)

Returns nothing.

=cut

sub assigned_heading_alone {
    my ( $class, %opts ) = @_;
    $opts{seen} = 1;
    return;
}

=head2 Documented->called_heading($x)

Returns Int.

    my $int = Documented->called_heading(2.5);

=cut

sub called_heading {
    my ( $class, $x ) = @_;
    return int($x);
}

=head2 $object->named_in_heading($domain, leave_down => $bool)

Returns Bool.

    my $kept = $object->named_in_heading( 'web.test.test', leave_down => 1 );

=cut

sub named_in_heading {
    my ( $self, $domain, %opts ) = @_;
    $self->{domain} = $domain;
    return $opts{leave_down} ? 1 : 0;
}

=head2 $object->wrongly_named_in_heading($domain, stay_down => $bool)

Returns Bool.

    my $kept = $object->wrongly_named_in_heading( 'web.test.test', stay_down => 1 );

=cut

sub wrongly_named_in_heading {
    my ( $self, $domain, %opts ) = @_;
    $self->{domain} = $domain;
    return $opts{leave_down} ? 1 : 0;
}

1;
