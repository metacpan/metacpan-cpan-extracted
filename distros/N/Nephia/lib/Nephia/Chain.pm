package Nephia::Chain;
use strict;
use warnings;
use Carp;
use Scalar::Util ();

sub new {
    my ($class, %opts) = @_;
    $opts{namespace}      = $class.'::Item' unless defined $opts{namespace};
    $opts{name_normalize} = 1 unless defined $opts{name_normalize};
    bless {chain => [], from => {}, %opts}, $class;
}

sub append {
    my $self    = shift;
    my $from    = caller;
    my @actions = $self->_inject('Tail', 1, @_);
    $self->{from}{$_} = $from for map {ref($_)} @actions;
}

sub prepend {
    my $self    = shift;
    my $from    = caller;
    my @actions = $self->_inject('Head', 0, @_);
    $self->{from}{$_} = $from for map {ref($_)} @actions;
}

sub before {
    my ($self, $search, @opts) = @_;
    my $from    = caller;
    my @actions = $self->_inject($search, 0, @opts);
    $self->{from}{$_} = $from for map {ref($_)} @actions;
}

sub after {
    my ($self, $search, @opts) = @_;
    my $from    = caller;
    my @actions = $self->_inject($search, 1, @opts);
    $self->{from}{$_} = $from for map {ref($_)} @actions;
}

sub delete {
    my ($self, $search) = @_;
    splice( @{$self->{chain}}, $self->index($search), 1);
    delete $self->{from}{$self->_normalize_name($search)};
}

sub size {
    my $self = shift;
    return scalar( @{$self->{chain}} );
}

sub from {
    my ($self, $name) = @_;
    return $self->{from}{$self->_normalize_name($name)};
}

sub index {
    my ($self, $name) = @_;
    return 0 if $name eq 'Head';
    return $self->size - 1 if $name eq 'Tail';
    my $normalized_name = $self->_normalize_name($name);
    for my $i (0 .. $self->size -1) {
        return $i if $self->{chain}[$i]->isa($normalized_name);
    }
}

sub as_array {
    my $self = shift;
    return @{$self->{chain}};
}

sub fetch {
    my ($self, $plugin) = @_;
    for my $obj (@{$self->{chain}}) {
        return $obj if ref($obj) eq $plugin;
    }
    return undef;
}

sub _inject {
    local $Carp::CarpLevel = $Carp::CarpLevel + 2;
    my ($self, $search, $after, @opts) = @_;
    my $index  = $self->index($search);
    $index += $after;
    my @actions = $self->_bless_actions(@opts);
    splice @{$self->{chain}}, $index, 0, @actions;
    return @actions;
}

sub _validate_action_opts {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my ($self, $name, $code) = @_;
    croak "name is undefined" unless $name;
    croak "code for $name is undefined" unless $code;
    croak "illegal name $name" if ref($name);
    return ( $self->_normalize_name($name), $code );
}

sub _check_duplicates {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my ($self, @action) = @_;
    for my $name ( map {ref($_)} @action ) {
        croak "name $name is already stored" if $self->index($name);
        croak "duplicate name $name" if scalar( grep {ref($_) eq $name} @action ) > 1;
    }
}

sub _normalize_name {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my ($self, $name) = @_;
    return $name unless $self->{name_normalize};
    my $namespace = $self->{namespace};
    return $name =~ /^$namespace\:\:/ ? $name : $namespace.'::'.$name;
}

sub _bless_actions {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my ($self, @opts) = @_;
    my @rtn;
    while (@opts) {
        push @rtn, $self->_shift_as_action(\@opts);
    }
    $self->_check_duplicates(@rtn);
    return wantarray ? @rtn : $rtn[0];
}

sub _shift_as_action {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my ($self, $opts) = @_;
    return shift(@$opts) if Scalar::Util::blessed($opts->[0]);
    my $name = shift(@$opts);
    my $code = shift(@$opts);
    ($name, $code) = $self->_validate_action_opts($name, $code);
    return bless($code, $name);
}

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Chain - Abstract code chain for hook mechanism of Nephia

=head1 DESCRIPTION

Nephia::Chain is an abstract code chain class for hook mechanism of Nephia.

=head1 SYNOPSIS

    my $chain = Nephia::Chain->new(namespace => 'Foobar::Chain::Item');
    $chain->append(incr => sub { $_[0] + 1 }, double => sub { $_[0] * 2 }); ### y = ((x + 1) * 2)
    $chain->prepend(power => sub { $_[0] ** 2 });                           ### y = (((x ** 2) + 1) * 2)
    $chain->before('Head', plus3 => sub { $_[0] + 3 });                     ### y = ((((x + 3) ** 2) + 1) * 2)
    $chain->after('plus3', half => sub { $_[0] / 2 });                      ### y = (((((x + 3) / 2) ** 2) + 1) * 2)
    
    my $x = 3;
    for my $item ( $chain->as_array ) {
        $x = $item->($x);
    }
    my $y = $x;
    printf "y = %s\n", $y; ### 20

=head1 ATTRIBUTES

=head2 namespace

Prefix of name for coderef-entries

=head2 name_normalize

Enable or Disable name normalization when add and/or search entry.

=head1 METHODS

=head2 append

    $chain->append( entryname => sub { ... } );

Add a new coderef to tail of chain.

=head2 prepend

    $chain->prepend( entryname => sub { ... } );

Add a new coderef to head of chain.

=head2 before

    $chain->before( 'target', entryname => sub { ... } );

Add a new coderef before target entry.

=head2 after

    $chain->after( 'target', entryname => sub { ... } );

Add a new coderef after target entry.

=head2 delete 

    $chain->delete( 'target' );

Delete specified entry.

=head2 from

    my $come_from = $chain->from( 'target' );

Returns a class name of origin of specified entry.

=head2 size

    my $size = $chain->size;

Returns a number of entries.

=head2 index

    my $position = $chain->index( 'target' );

Returns a position number of specified entry.

=head2 as_array

    my @coderef_list = $chain->as_array;

Returns each coderef.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

