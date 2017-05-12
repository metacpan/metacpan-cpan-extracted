package Test::A8N::Fixture;
use warnings;
use strict;

use Moose;

BEGIN {
    # This ensures the constructor from Moose::Object is
    # preferred over the FITesque one... this is IMPORTANT!
    extends(qw(Moose::Object Test::FITesque::Fixture));
}

use Test::More;
use YAML::Syck;
our @EXCLUDE_METHODS = qw(
    config
    selenium
    testcase
    ctxt
    verbose
    parse_method_string
    disallowed_phrases
    parse_arguments
);

sub BUILD {
    my $self = shift;
    my ($params) = @_;
    if (!$self->verbose || $params->{QUIET} || $ENV{QUIET_FIXTURES}) {
        Test::Builder->new->no_diag(1);
    }
    diag sprintf(q{Using fixture class "%s"}, blessed($self))
        if ($self->verbose > 1);
    diag sprintf('START: "%s": %s', $self->testcase->filename, $self->testcase->id)
        if ($self->verbose);
}

sub DEMOLISH {
    my $self = shift;
    # fixture actions can clean up after themselves
    while (my $coderef = shift @{ $self->_demolish_actions() }){
        $self->$coderef();
        $coderef = undef;
    }
    diag sprintf('FINISH: "%s": %s', $self->testcase->filename, $self->testcase->id)
        if ($self->verbose);
}

has '_demolish_actions' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {[]},
);

sub _add_demolish_actions {
    my ($self, @actions) = @_;
    push @{ $self->_demolish_actions() }, @actions;
}

has 'config' => (
    is => 'rw',
    required => 1,
    isa => 'HashRef',
    default => sub { shift->testcase->config },
    lazy => 1,
);

has 'testcase' => (
    is => 'rw',
    isa => 'Object'
);

has 'ctxt' => (
    is => 'rw',
    required => 1,
    isa => 'HashRef',
    default => sub { {} },
    lazy => 1,
);

has verbose => (
    required => 1,
    lazy     => 1,
    is       => q{ro},
    isa      => q{Int},
    default  => sub { return shift->config->{verbose} },
);

# NB: this is a FITesque method, please do not edit.
sub parse_method_string {
  my ($self, $method_string) = @_;
  (my $method_name = $method_string) =~ s/\s+/_/g;

  # don't allow test cases to call private methods
  if($method_name =~ m{^_}){
    warn "Cannot call '$method_name' from test cases";
    return undef;
  }

  if (ref($self) and $self->verbose > 1) {
      diag "Fixture method $method_name";
  }

  # Don't allow testcases to talk about implementaion details
  if(grep { $method_name =~ m{$_} } $self->disallowed_phrases()){

    #
    # Test cases should be completely oblivious to how things are done
    # internally since they should be written from the perspective of the
    # user. This is just a catchall to make sure that the developer really
    # means "do something like the user would" instead of "hoke around the
    # internals"
    #
    warn "'$method_name' refers to implementation details";
    return undef;
  }

  my $coderef = $self->can($method_name);
  return $coderef;
}

sub disallowed_phrases {
  my ($self) = @_;
  return qw();
}

sub _get_metavar {
    my $self = shift;
    my ($name) = @_;
    my $config_ref = $self->config;

    my @path = split(/\./, $name);
    foreach my $sub_name (@path) {
        $config_ref = $config_ref->{$sub_name} or last;
    }
    warn qq{Config reference "$name" does not point to a value}
        if (ref($config_ref));
    return $config_ref;
}

sub _parse_metavars {
    my $self = shift;
    my ($str) = @_;
    $str ||= '';

    my @keys = $str =~ /\$\(([^\)]+)\)/g;
    foreach (@keys) {
        my $value = $self->_get_metavar($_);
        $str =~ s/\$\($_\)/$value/g;
    }

    return $str;
}
sub _recurse_parse_arguments {
    my $self = shift;
    my $arg = shift;
    if (ref($arg) eq 'HASH') {
        foreach my $key (keys %$arg) {
            if (ref($arg->{$key})) {
                $arg->{$key} = $self->_recurse_parse_arguments($arg->{$key});
            } else {
                $arg->{$key} = $self->_parse_metavars($arg->{$key});
            }
        }
    } elsif (ref($arg) eq 'ARRAY') {
        foreach my $idx (0 .. scalar(@$arg) - 1) {
            if (ref($arg->[$idx])) {
                $arg->[$idx] = $self->_recurse_parse_arguments($arg->[$idx]);
            } else {
                $arg->[$idx] = $self->_parse_metavars($arg->[$idx]);
            }
        }
    } else {
        $arg = $self->_parse_metavars($arg);
    }
    return $arg;
}

# NB: This is a FITesque required function
sub parse_arguments {
    my $self = shift;
    return @_ if !ref($self);

    my @args = ();
    my $recurse;

    foreach my $arg (@_) {
        push @args, $self->_recurse_parse_arguments($arg);
    }
    return @args;
}

sub _squish_array {
    my $self = shift;
    my ($arg) = @_;
    my $array;
    if (ref($arg) eq 'ARRAY') {
        $array = $arg;
    } elsif (defined($arg)) {
        $array = [$arg];
    } else {
        $array = [];
    }
    return wantarray ? @{ $array } : $array;
}

sub _lowercase_args {
    my $self = shift;
    my ($args) = @_;
    foreach my $field (keys %$args) {
        $args->{lc($field)} = delete $args->{$field};
    }
}

=head1 FIXTURE ACTIONS

=cut

=head2 todo fail

  todo fail: [ message ]

Marks a place in the test case where you would like it to fail, flagging it as a TODO item.

=cut

sub todo_fail {
    my $self = shift;
    my ($arg) = @_;
    TODO: {
        local $TODO = "Marked as a failing TODO: $arg";
        fail($arg);
    }
}

1;
__END__

=head1 SEE ALSO

L<Test::A8N>, L<Test::FITesque::Fixture>

=cut

