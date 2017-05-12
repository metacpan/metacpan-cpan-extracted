# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Sub-Chain-Group
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Sub::Chain::Group;
# git description: v0.013-4-g6f84b56

our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: Group chains of subs by field name
$Sub::Chain::Group::VERSION = '0.014';
use Carp qw(croak carp);

# this seems a little dirty, but it's not appropriate to put it in Sub::Chain
use Sub::Chain;
{
  no warnings 'once';
push(@Sub::Chain::CARP_NOT, __PACKAGE__);
}

use Set::DynamicGroups ();
use Module::Load ();


sub new {
  my $class = shift;
  my %opts = ref $_[0] ? %{$_[0]} : @_;

  my $self = {
    chain_class => delete $opts{chain_class} || 'Sub::Chain',
    chain_args  => delete $opts{chain_args}  || {},
    fields => {},
    groups => Set::DynamicGroups->new(),
    queue  => [],
    hooks  => {},
    hook_as_hash  => delete $opts{hook_as_hash},
    warn_no_field => 'single',
  };

  foreach my $enum (
    [warn_no_field => qw(never single always)],
  ){
    my ($key, @vals) = @$enum;
    if( my $val = delete $opts{ $key } ){
      croak qq['$key' cannot be set to '$val'; must be one of: ] . join(', ', @vals)
        unless grep { $val eq $_ } @vals;
      $self->{ $key } = $val;
    }
  }

  Module::Load::load($self->{chain_class});

  # TODO: warn about remaining unused options?

  bless $self, $class;
}


sub append {
  my ($self, $sub) = (shift, shift);
  my %opts = ref $_[0] ? %{$_[0]} : @_;

  CORE::push(@{ $self->{queue} ||= [] },
    [$sub, $self->_normalize_spec(\%opts)]);

  return $self;
}


sub call {
  my ($self) = shift;

  $self->dequeue
    if $self->{queue};

  my $out;
  my $opts = {multi => 1};
  my $ref = ref $_[0];

  my ($before, $after) = @{ $self->{hooks} }{qw( before after )};

  if( $ref eq 'HASH' ){
    my $in = { %{ $_[0] } };
    $in = $before->call($in)  if $before;
    $out = {};
    while( my ($key, $value) = each %$in ){
      $out->{$key} = $self->_call_one($key, $value, $opts);
    }
    $out = $after->call($out) if $after;
  }
  elsif( $ref eq 'ARRAY' ){
    my $fields = [ @{ $_[0] } ];
    my $values = [ @{ $_[1] } ];
    $values = $self->_call_hook($before, $values, $fields) if $before;
    $out = [];
    foreach my $i ( 0 .. @$fields - 1 ){
      CORE::push(@$out,
        $self->_call_one($fields->[$i], $values->[$i], $opts));
    }
    $out = $self->_call_hook($after, $out, $fields) if $after;
  }
  else {
    my ($key, $val) = @_;
    $val = $self->_call_hook($before, $val, $key) if $before;
    $out = $self->_call_one($key, $val);
    $out = $self->_call_hook($after,  $out, $key) if $after;
  }

  return $out;
}

sub _call_hook {
  my ($self, $chain, $values, $fields) = @_;

  if( $self->{hook_as_hash} ){
    if( ref($fields) eq 'ARRAY' ){
      my $hash = {};
      @$hash{ @$fields } = @$values;
      $hash = $chain->call($hash);
      $values = [ @$hash{ @$fields } ];
    }
    else {
      my $hash = { $fields => $values };
      $hash = $chain->call($hash);
      $values = $hash->{ $fields };
    }
  }
  else {
    $values = $chain->call($values, $fields);
  }

  return $values;
}

sub _call_one {
  my ($self, $field, $value, $opts) = @_;
  return $value
    unless my $chain = $self->chain($field, $opts);
  return $chain->call($value);
}


sub chain {
  my ($self, $name, $opts) = @_;
  $opts ||= {};

  $self->dequeue
    if $self->{queue};

  if( my $chain = $self->{fields}{$name} ){
    return $chain;
  }

  carp("No subs chained for '$name'")
    if $self->{warn_no_field} eq 'always'
      || ($self->{warn_no_field} eq 'single' && !$opts->{multi});

  return;
}


sub dequeue {
  my ($self) = @_;

  return unless my $queue = $self->{queue};
  my $dequeued = ($self->{dequeued} ||= []);

  # shift items off the queue until they've all been processed
  while( my $item = shift @$queue ){
    # save this item in case we need to reprocess the whole queue later
    CORE::push(@$dequeued, $item);

    my ($sub, $opts) = @$item;
    my @chain_args = ($sub, @$opts{qw(args opts)});

    foreach my $hook ( @{ $opts->{hooks} || [] } ){
      ($self->{hooks}->{ $hook } ||= $self->new_sub_chain())
        ->append(@chain_args);
    }

    my $fields = $opts->{fields} || [];
    # keep fields unique
    my %seen = map { $_ => 1 } @$fields;
    # add unique fields from groups (if there are any)
    if( my $groups = $opts->{groups} ){
      CORE::push(@$fields, grep { !$seen{$_}++ }
        map { @$_ } values %{ $self->{groups}->groups(@$groups) }
      );
    }

    foreach my $field ( @$fields ){
      ($self->{fields}->{$field} ||= $self->new_sub_chain())
        ->append(@chain_args);
    }
  }
  # let 'queue' return false so we can do simple 'if queue' checks
  delete $self->{queue};

  # what would be a good return value?
  return;
}


sub fields {
  my ($self) = shift;
  $self->{groups}->add_items(@_);
  $self->reprocess_queue
    if $self->{dequeued};
  return $self;
}


sub group {
  my ($self) = shift;
  croak("group() takes argument pairs.  Did you mean groups()?")
    if !@_;

  $self->{groups}->add(@_);
  $self->reprocess_queue
    if $self->{dequeued};
  return $self;
}


sub groups {
  my ($self) = shift;
  croak("groups() takes no arguments.  Did you mean group()?")
    if @_;

  return $self->{groups};
}


sub new_sub_chain {
  my ($self) = @_;
  return $self->{chain_class}->new($self->{chain_args});
}

sub _normalize_spec {
  my ($self, $opts) = @_;

  # Don't alter \%opts.  Limit %norm to desired keys.
  my %norm;
  my %aliases = (
    arguments => 'args',
    options   => 'opts',
    field     => 'fields',
    group     => 'groups',
    hook      => 'hooks',
  );

  while( my ($alias, $name) = each %aliases ){
    # store the alias in the actual key
    # overwrite with actual key if specified
    foreach my $key ( $alias, $name ){
      $norm{$name} = $opts->{$key}
        if exists  $opts->{$key};
    }
  }

  # allow a single string and convert it to an arrayref
  foreach my $type ( qw(fields groups hooks) ){
    $norm{$type} = [$norm{$type}]
      if exists($norm{$type}) && !ref($norm{$type});
  }

  # simplify code later by initializing these to refs
  $norm{args} ||= [];
  $norm{opts} ||= {};

  return \%norm;
}


sub reprocess_queue {
  my ($self) = @_;
  return unless my $dequeued = delete $self->{dequeued};

  # reset the queue and the stacks so that it will all be rebuilt
  $self->{queue}  = [@$dequeued, @{ $self->{queue} || [] } ];
  $self->{fields} = {};
  $self->{hooks}  = {};
  # but don't actually rebuild it until necessary
}

1;

# NOTE: Synopsis tested in t/synopsis.t

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS TODO cpan testmatrix url annocpan anno
bugtracker rt cpants kwalitee diff irc mailto metadata placeholders
metacpan

=head1 NAME

Sub::Chain::Group - Group chains of subs by field name

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  my $chain = Sub::Chain::Group->new();
  $chain->append(\&trim, fields => [qw(name address)]);

  # append other subs to this or other fields as desired...
  my $trimmed = $chain->call(address => ' 123 Street Rd. ');


  # or, using a Sub::Chain subclass:

  my $named = Sub::Chain::Group->new(
    chain_class => 'Sub::Chain::Named',
    chain_args  => { subs => {
      uc => sub { uc $_[0] },
      reverse => sub { reverse $_[0] },
    }}
  );
  $named->group(fruits => [qw(apple orange banana)]);
  $named->append('uc', groups => 'fruits');
  $named->append('reverse', fields => 'orange');

  my $fruit = $named->call({apple => 'green', orange => 'dirty'});
  # returns a hashref: {apple => 'GREEN', orange => 'YTRID'}

=head1 DESCRIPTION

This module provides an interface for managing multiple
L<Sub::Chain> instances for a group of fields.
It is mostly useful for applying a chain of subs
to a set of data (like a hash or array (like a database record)).
In addition to calling different sub chains on specified fields
It uses L<Set::DynamicGroups> to allow you to build sub chains
for dynamic groups of fields.

=head1 METHODS

=head2 new

  my $chain = Sub::Chain::Group->new(%opts);

  my $chain = Sub::Chain::Group->new(
    chain_class => 'Sub::Chain::Named',
    chain_args  => {subs => {happy => sub { ":-P" } } },
  );

Constructor;  Takes a hash or hashref of options.

Possible options:

=over 4

=item *

C<chain_class>

The L<Sub::Chain> class that will be instantiated for each field;
You can set this to L<Sub::Chain::Named> or another subclass.

=item *

C<chain_args>

A hashref of arguments that will be sent to the
constructor of the C<chain_class> module.
Here you can set alternate default values (see L<Sub::Chain/OPTIONS>)
or, for example, include the C<subs> parameter
if you're using L<Sub::Chain::Named>.

=item *

C<hook_as_hash>

Normally hooks are called with the data structures
passed in (hash refs, array refs, or strings).
If this option is enabled (set to a true value)
hooks will be called with a hashref instead (derived from the input data)
to enable simpler more consistent hook functions.
See L</HOOKS> for more information.

=item *

C<warn_no_field>

Whether or not to emit a warning if asked to call a sub chain on a field
but no subs were specified for that field
(specifically when L</chain> is called and no chain exists).
Valid values are:

=over 4

=item *

C<never> - never warn

=item *

C<always> - always warn

=item *

C<single> - warn when called for a single field
(but not when L</call> is used with a hashref or arrayref).

=back

The default is C<single>.

=back

=head2 append

  $chain->append($sub, %options); # or \%options
  $chain->append(\&trim,  fields => [qw(fld1 fld2)]);
  $chain->append(\&trim,  field  => 'col3', opts => {on_undef => 'blank'});
  # or, if using Sub::Chain::Named
  $chain->append('match', groups => 'group1', args => ['pattern']);

Append a sub onto the chain
for the specified fields and/or groups.

Possible options:

=over 4

=item *

C<fields> (or C<field>)

Field name(s) (string or array ref)

=item *

C<groups> (or C<group>)

Group name(s) (string or array ref)

=item *

C<hooks> (or C<hook>)

Valid values: C<before>, C<after> (string or array ref)
See L</HOOKS> for explanation.

=item *

C<args> (or C<arguments>)

An arrayref of arguments to pass to the sub
(see L<Sub::Chain/append>)

=item *

C<opts> (or C<options>)

A hashref of options for the sub
(see L<Sub::Chain/OPTIONS>)

=back

=head2 call

  my $values = $chain->call({key => 'value', ...});
  my $values = $chain->call([qw(fields)], [qw(values)]);
  my $value  = $chain->call('address', '123 Street Road');

Call the sub chain appropriate for each field of the supplied data.

The input (and output) can be one of the following:

=over 4

=item *

hashref => hashref

If a sole hash ref is supplied
it will be looped over
and a hash ref of result data will be returned.
For example:

  # for use with DBI
  $sth->execute;
  while( my $hash = $sth->fetchrow_hashref() ){
    my $new_hash = $chain->call($hash);
  }

=item *

arrayref => arrayref

If two array refs are supplied,
the first should be a list of field names,
and the second the corresponding data.
For example:

  # for use with Text::CSV
  my $header = $csv->getline($io);
  while( my $array = $csv->getline($io) ){
    my $new_array = $chain->call($header, $array);
  }

=item *

string, scalar => scalar

If two arguments are given,
and the first is a string,
it should be the field name,
and the second argument the data.
The return value will be the data after it has been
passed through the chain.

  # simple data
  my $trimmed = $chain->call('spaced', '  lots of space   ');

=back

=head2 chain

  $chain->chain($field);

Return the sub chain for the given field name.

=head2 dequeue

Process the queue of group and field specifications.

Queuing allows you to specify subs
for a group before you specify what fields belong in that group.

This method is called when another method needs something
from the chain and there are still specifications in the queue
(like L</chain> and L</call>, for instance).

=head2 fields

  $chain->fields(@fields);

Add fields to the list of all known fields.
This tells the object which fields are available or expected
which can be useful for specifying groups based on exclusions.

For example:

  $chain->group(some => {not => [qw(primary secondary)]});
  $chain->fields(qw(primary secondary this that));
  # the 'some' group will now contain ['this', 'that']

  $chain->fields('another');
  # the 'some' group will now contain ['this', 'that', 'another']

This is a convenience method.
Arguments are passed to L<Set::DynamicGroups/add_items>.

=head2 group

  $chain->group(groupname => [qw(fields)]);

Add fields to the specified group name.

This is a convenience method.
Arguments are passed to L<Set::DynamicGroups/add>.

=head2 groups

  my $set_dg = $chain->groups();

Return the object's instance of L<Set::DynamicGroups>.

This can be useful if you need more advanced manipulation
of the groups than is available through the L</group> and L</fields> methods.

=head2 new_sub_chain

This method is used internally to instantiate a new L<Sub::Chain>
using the C<chain_class> and C<chain_args> options.

=head2 reprocess_queue

Force the queue of chain specifications
to be completely reprocessed.

This gets called automatically when groups are changed
after the queue was initially processed.

=head1 HOOKS

In addition to building sub chains for specific fields (or groups)
there are also hooks available to process the input as a whole
(the hash ref or array refs passed to L</call>).

Specify C<< hook => 'before' >> (or C<< hook => 'after' >>)
when calling L</append> (instead of specifying C<fields> or C<groups>)
and the provided sub will be appended to a chain that will be able to
modify the input record as a whole before (or after)
the sub chains are called for each field.

These can modify the input by updating (or even adding new) fields:

  sub debug_hash {
    my $h = shift;
    $h->{debug} = join ':', keys %$h;
    return $h;
  }

  $chain->append(\&debug_hash, hook => 'before');

The sub should return the (modified) data structure
for consistency with other chained subs.

When passing a hash ref to L</call>
the hash ref will be passed to the hook (as shown above).

If two array refs are passed to L</call>
the array ref of values will be passed to the hook as the first argument
and the array ref of keys will be passed as the second argument.
This is consistent with all other chained subs that receive their value
as the first argument.

  $chain->call([qw(a b c), [1, 2, 3]);
  # sub will receive: ([1, 2, 3], [qw(a b c)])
  # and should return an array ref of (possibly modified) values

You can also set C<< hook_as_hash => 1 >> in the constructor
which will use the two input arrays to build a hash ref,
pass the hash ref to any hook subs
(which should return a hash ref),
and in the end return an array ref of the fields of that hash ref
preserving the order of the original array ref.
This can be simpler to work with in the sub
(and enable using the same sub regardless of the input type).

  $chain->call([qw(a b c)], [1, 2, 3]);
  # sub will receive: ({a => 1, b => 2, c => 3})
  # and should return a (possibly modified) hash ref.

If a simple string key is passed to L</call>
the hooks will be called with the value as the first argument
and the field name as the second (similar to the way array refs are handled).
The C<hook_as_hash> option will also work here;
A hashref will be passed to the hooks
and ultimately return the single value.

B<Note>:
A shallow clone is performed on the ref(s) (but not a deep clone)
so it's up to you to determine if modifying the structures in the hooks
is acceptable or if you need to do a deep clone.

=head1 TODO

See L<Sub::Chain/TODO>.

=head1 SEE ALSO

=over 4

=item *

L<Sub::Chain>

=item *

L<Sub::Chain::Named>

=item *

L<Set::DynamicGroups>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Sub::Chain::Group

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Sub-Chain-Group>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-sub-chain-group at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Sub-Chain-Group>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Sub-Chain-Group>

  git clone https://github.com/rwstauner/Sub-Chain-Group.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
