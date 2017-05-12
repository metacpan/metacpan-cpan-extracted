package Module::AnyEvent::Helper::PPI::Transform;

use strict;
use warnings;

# ABSTRACT: PPI::Transform subclass for AnyEvent-ize helper
our $VERSION = 'v0.0.5'; # VERSION


BEGIN {
    require Exporter;
    our (@ISA) = qw(Exporter);
    our (@EXPORT_OK) = qw(
        function_name is_function_declaration delete_function_declaration
        copy_children
        emit_cv emit_cv_into_function
        replace_as_async
    );
}

use parent qw(PPI::Transform);

use Carp;
use Scalar::Util qw(blessed);

########################################################################
# Functions
#     can be called as class methods

sub function_name
{
    shift unless blessed($_[0]);
    my $word = shift;
    croak "function_name: MUST be called with an argument of PPI::Element object" unless blessed($word) && $word->isa('PPI::Element');
    my $st = $word->statement;
    return if ! $st;
    return function_name($st->parent) if $st->class ne 'PPI::Statement::Sub';
    return $st->schild(1);
}

sub is_function_declaration
{
    shift unless blessed($_[0]);
    my $word = shift;
    croak "is_function_declaration: MUST be called with an argument of PPI::Token::Word object" unless blessed($word) && $word->isa('PPI::Token::Word');
    return defined $word->parent && $word->parent->class eq 'PPI::Statement::Sub';
}

sub delete_function_declaration
{
    shift unless blessed($_[0]);
    my $word = shift;
    croak "delete_function_declaration: MUST be called with an argument of PPI::Token::Word object" unless blessed($word) && $word->isa('PPI::Token::Word');
    return $word->parent->delete;
}

sub copy_children
{
    shift unless !defined($_[0]) || $_[0] eq '' || blessed($_[0]);
    my ($prev, $next, $target) = @_;

    croak 'copy_children: Both of prev and next are not PPI::Element objects' unless blessed($prev) && $prev->isa('PPI::Element') || blessed($next) && $next->isa('PPI::Element');
    croak 'copy_children: target is not a PPI::Element object' unless blessed($target) && $target->isa('PPI::Element');

    for my $elem ($target->children) {
        my $new_elem = $elem->clone or confess 'Cloning element failed';
        if($prev) {
            $prev->insert_after($new_elem) or confess 'Insertion failed';
        } else {
            $next->insert_before($new_elem) or confess 'Insertion failed';
        }
        $prev = $new_elem;
    }
}

my $cv_decl = PPI::Document->new(\'my $___cv___ = AE::cv;')->first_element->remove;
my $cv_ret = PPI::Document->new(\'return $___cv___;'); #->first_element->remove;

sub emit_cv
{
    shift unless blessed($_[0]);
    my $block = shift;
    croak 'emit_cv: target is not a PPI::Structure::Block object' unless blessed($block) && $block->isa('PPI::Structure::Block');
    copy_children($block->first_element, undef, $cv_decl);
    copy_children($block->schild($block->schildren-1), undef, $cv_ret);
}

sub emit_cv_into_function
{
    shift unless blessed($_[0]);
    my $word = shift;
    croak 'emit_cv_into_function: the first argument is not a PPI::Token::Word object' unless blessed($word) && $word->isa('PPI::Token::Word');
    my $block = $word->parent->find_first('PPI::Structure::Block');
    emit_cv($block);
}

my $shift_recv = PPI::Document->new(\'shift->recv()')->first_element->remove;

sub _find_one_call
{
    shift unless blessed($_[0]);
    my ($word) = @_;
    croak '_find_one_call: the first argument is not a PPI::Element object' unless blessed($word) && $word->isa('PPI::Element');
    my ($pre) = [];
    my $sprev_orig = $word->sprevious_sibling;
    my ($prev, $sprev) = ($word->previous_sibling, $word->sprevious_sibling);
    my $state = 'INIT';

# TODO: Probably, this is wrong
    while(1) {
#print STDERR "$state : $sprev\n";
        last unless $sprev;
        if(($state eq 'INIT' || $state eq 'LIST' || $state eq 'TERM' || $state eq 'SUBTERM') && $sprev->isa('PPI::Token::Operator') && $sprev->content eq '->') {
            $state = 'OP';
        } elsif($state eq 'OP' && $sprev->isa('PPI::Structure::List')) {
            $state = 'LIST';
        } elsif(($state eq 'OP' || $state eq 'LIST') && ($sprev->isa('PPI::Token::Word') || $sprev->isa('PPI::Token::Symbol'))) {
            $state = 'TERM';
        } elsif(($state eq 'OP' || $state eq 'SUBTERM') && 
                ($sprev->isa('PPI::Structure::Constructor') || $sprev->isa('PPI::Structure::List') || $sprev->isa('PPI::Structure::Subscript'))) {
            $state = 'SUBTERM';
        } elsif(($state eq 'OP' || $state eq 'SUBTERM') && 
                ($sprev->isa('PPI::Token::Word') || $sprev->isa('PPI::Token::Symbol'))) {
            $state = 'TERM';
        } elsif(($state eq 'OP' || $state eq 'TERM') && $sprev->isa('PPI::Structure::Block')) {
            $state = 'BLOCK';
        } elsif($state eq 'BLOCK' && $sprev->isa('PPI::Token::Cast')) {
            $state = 'TERM';
        } elsif($state eq 'INIT' || $state eq 'TERM' || $state eq 'SUBTERM') {
            last; 
        } else {
            $state = 'ERROR'; last;
        }
        $prev = $sprev->previous_sibling;
        $sprev = $sprev->sprevious_sibling;
    }
    confess "Unexpected token sequence" unless $state eq 'INIT' || $state eq 'TERM' || $state eq 'SUBTERM';
    if($state ne 'INIT') {
        while($sprev ne $sprev_orig) {
            my $sprev_ = $sprev_orig->sprevious_sibling;
            unshift @$pre , $sprev_orig->remove;
            $sprev_orig = $sprev_;
        }
    }
    return [$prev, $pre];
}

sub _replace_as_shift_recv
{
    shift unless blessed($_[0]);
    my ($word) = @_;
    croak '_replace_as_shift_recv: the first argument is not a PPI::Element object' unless blessed($word) && $word->isa('PPI::Element');

    my $args;
    my $next = $word->snext_sibling;

    my ($prev, $pre) = @{_find_one_call($word)};

    if($next && $next->isa('PPI::Structure::List')) {
        my $next_ = $next->next_sibling;
        $args = $next->remove;
        $next = $next_;
    }
    $word->delete;
    copy_children($prev, $next, $shift_recv);
    return [$pre, $args];
}

my $bind_scalar = PPI::Document->new(\('Module::AnyEvent::Helper::bind_scalar($___cv___, MARK(), sub {'."\n});"))->first_element->remove;
my $bind_array = PPI::Document->new(\('Module::AnyEvent::Helper::bind_array($___cv___, MARK(), sub {'."\n});"))->first_element->remove;

sub replace_as_async
{
    shift unless blessed($_[0]);
    my ($word, $name, $is_array) = @_;
    croak 'replace_as_async: the first argument is not a PPI::Element object' unless blessed($word) && $word->isa('PPI::Element');

    my $st = $word->statement;
    my $prev = $word->previous_sibling;
    my $next = $word->next_sibling;

    my ($pre, $args) = @{_replace_as_shift_recv($word)}; # word and prefixes are removed

    # Setup binder
    my $bind_ = $is_array ? $bind_array->clone : $bind_scalar->clone;
    my $mark = $bind_->find_first(sub { $_[1]->class eq 'PPI::Token::Word' && $_[1]->content eq 'MARK'});
    if(defined $args) {
        $mark->next_sibling->delete;
        $mark->insert_after($args);
    }
    $mark->set_content($name);
    while(@$pre) {
        my $entry = pop @$pre;
        $mark->insert_before($entry);
        $mark = $entry;
    }

    # Insert
    $st->insert_before($bind_);

    # Move statements into bound closure
    my $block = $bind_->find_first('PPI::Structure::Block');
    do { # Move statements into bound closure
        $next = $st->next_sibling;
        $block->add_element($st->remove);
        $st = $next;
    } while($st);
}

my $use = PPI::Document->new(\"use AnyEvent;use Module::AnyEvent::Helper;");

sub _emit_use
{
    shift unless blessed($_[0]);
    my ($doc) = @_;
    croak '_emit_use: the first argument is not a PPI::Element object' unless blessed($doc) && $doc->isa('PPI::Element');
    my $first = $doc->first_element;
    $first = $first->snext_sibling if ! $first->significant;
    copy_children(undef, $first, $use);
}

my $strip_tmpl = 'Module::AnyEvent::Helper::strip_async_all(-exclude => [qw(%s)]);1;';

sub _emit_strip
{
    shift unless blessed($_[0]);
    my ($doc, @exclude) = @_;
    croak '_emit_strip: the first argument is not a PPI::Element object' unless blessed($doc) && $doc->isa('PPI::Element');
    my $strip_ = sprintf($strip_tmpl, join ' ', @exclude);
    my $strip = PPI::Document->new(\$strip_);
    my $pkgs = $doc->find('PPI::Statement::Package');
    shift @{$pkgs};
    for my $pkg (@$pkgs) {
        copy_children(undef, $pkg, $strip);
    }
    my $last = $doc->last_element;
    $last = $last->sprevious_sibling if ! $last->significant;
    copy_children($last, undef, $strip);
}

########################################################################
# Methods

sub new
{
    my $self = shift;
    my $class = ref($self) || $self;
    my %arg = @_;
    $self = bless {
    }, $class;
    $self->{_PFUNC} = { map { $_, 1 } @{$arg{-replace_func}} } if exists $arg{-replace_func};
    $self->{_RFUNC} = { map { $_, 1 } @{$arg{-remove_func}} } if exists $arg{-remove_func};
    $self->{_DFUNC} = { map { $_, 1 } @{$arg{-delete_func}} } if exists $arg{-delete_func};
    $self->{_TFUNC} = { map { my $func = $_; $func =~ s/^@//; $func, 1 } @{$arg{-translate_func}} } if exists $arg{-translate_func};
    $self->{_AFUNC} = {
        map { my $func = $_; $func =~ s/^@//; $func, 1 }
        exists $arg{-translate_func} ? grep { /^@/ } @{$arg{-translate_func}} : (),
    };
    $self->{_XFUNC} = { map { $_, 1 } @{$arg{-exclude_func}} } if exists $arg{-exclude_func};
    return $self;
}

sub _is_translate_func
{
    my ($self, $name) = @_;
    return exists $self->{_TFUNC}{$name};
}

sub _is_remove_func
{
    my ($self, $name) = @_;
    return exists $self->{_RFUNC}{$name};
}

sub _is_replace_func
{
    my ($self, $name) = @_;
    return exists $self->{_PFUNC}{$name};
}

sub _is_delete_func
{
    my ($self, $name) = @_;
    return exists $self->{_DFUNC}{$name};
}

sub _is_replace_target
{
    my ($self, $name) = @_;
    return $self->_is_translate_func($name) || $self->_is_remove_func($name) || $self->_is_replace_func($name);
}

sub _is_array_func
{
    my ($self, $name) = @_;
    return exists $self->{_AFUNC}{$name};
}

sub _is_calling
{
    my ($self, $word) = @_;
    return 0 if ! $word->snext_sibling && ! $word->sprevious_sibling &&
                $word->parent && $word->parent->isa('PPI::Statement::Expression') &&
                $word->parent->parent && $word->parent->parent->isa('PPI::Structure::Subscript');
    return 0 if $word->snext_sibling && $word->snext_sibling->isa('PPI::Token::Operator') && $word->snext_sibling->content eq '=>';
    return 1;
}

sub document
{
    my ($self, $doc) = @_;
    $doc->prune('PPI::Token::Comment');

    _emit_use($doc);
    _emit_strip($doc, exists $self->{_XFUNC} ? keys %{$self->{_XFUNC}} : ());

    my @decl;
    my $words = $doc->find('PPI::Token::Word');
    for my $word (@$words) {
        next if !defined($word);
        if(is_function_declaration($word)) { # declaration
            if($self->_is_remove_func($word->content) || $self->_is_delete_func($word->content)) {
                delete_function_declaration($word);
            } elsif($self->_is_translate_func($word->content)) {
                push @decl, $word; # postpone declaration transform because other parts depend on this name
            }
        } else {
            next if ! defined $word->document; # Detached element
            next if ! defined function_name($word); # Not inside functions / methods
            next if ! $self->_is_translate_func(function_name($word)); # Not inside target functions / methods
            next if ! $self->_is_calling($word); # Not calling
            my $name = $word->content;
            if($self->_is_replace_target($name)) {
                replace_as_async($word, $name . '_async', $self->_is_array_func(function_name($word)));
            }
        }
    }
    foreach my $decl (@decl) {
        $decl->set_content($decl->content . '_async');
        emit_cv_into_function($decl);
    }
    return 1;
}

1;

__END__

=pod

=head1 NAME

Module::AnyEvent::Helper::PPI::Transform - PPI::Transform subclass for AnyEvent-ize helper

=head1 VERSION

version v0.0.5

=head1 SYNOPSIS

Typically, this module is not used directly but used via L<Module::AnyEvent::Helper::Filter>.
Of course, however, you can use this module directly. 

  my $trans = Module::AnyEvent::Helper::PPI::Transform->new(
      -remove_func => [qw()],
      -translate_func => [qw()]
  );
  $trans->file('Input.pm' => 'Output.pm');

NOTE that this module itself does not touch package name.

There are some helper functions can be exported.

  use Module::AnyEvent::Helper::PPI::Transform qw(function_name);
  function_name($element); # returns function name whose definition includes the element
  
  # or you can call them as class methods
  Module::AnyEvent::Helper::PPI::Transform->function_name($element);

=head1 DESCRIPTION

To make some modules AnyEvent-frinedly, it might be necessary to write boiler-plate codes.
This module applys the following transformations.

=over 4

=item *

Emit C<use AnyEvent;use Module::AnyEvent::Helper;> at the beginning of the document.

=item *

Translate (ordinary) methods to _async methods.

=over 4

=item *

Emit C<my $___cv___ = AE::cv;> at the beginning of the methods.

=item *

Emit C<return $___cv___;> at the end of the methods.

=item *

Replace method calls with pairs of C<Module::AnyEvent::Helper::bind_scalar> and C<shift-E<gt>recv>.

=back

=item *

Delete methods you need to implement by yourself.

=item *

Create blocking wait methods from _async methods to emit C<Module::AnyEvent::Helper::strip_async_all();1;> at the end of the packages.

=back

Additionally, this module inherits all of L<PPI::Transform> methods.

Furthermore, there are some helper functions. It might be helpful for implementing additional transformer of L<Module::AnyEvent::Helper::Filter>.

=head1 OPTIONS

=head2 C<-remove_func>

Specify array reference of removing methods.
If you want to implement async version of the methods, you specify them in this option.

=head2 C<-translate_func>

Specify array reference of translating methods.
You don't need to implement async version of these methods.
This module translates implementation.

=head2 C<-replace_func>

Specify array reference of replacing methods.
It is expected that async version is implemented elsewhere.

=head2 C<-delete_func>

Specify array reference of deleting methods.
If you want to implement not async version of the methods, you specify them in this option.

=head1 METHODS

This module inherits all of L<PPI::Transform> methods.

=head1 FUNCTIONS

All functions described here can be exported and can be called as class methods.

  # The followings are identical
  Module::AnyEvent::Helper::PPI::Transform::function_name($word);
  Module::AnyEvent::Helper::PPI::Transform->function_name($word);

=head2 C<function_name($element)>

C<$element> MUST be L<PPI::Element> object.
If C<$element> is included in a function definition, its function name is returned.
Otherwise, C<undef> is returned.

=head2 C<is_function_declaration($word)>

C<$word> MUST be L<PPI::Token::Word> object.
If C<$word> points a function name of a function declaration, true is returned.
Otherwise, false is returned.

=head2 C<delete_function_declaration($word)>

C<$word> MUST be L<PPI::Token::Word> object and SHOULD be is_function_declaration is true.
Delete the function declaration from the document.

=head2 C<copy_children($prev, $next, $target)>

C<$prev> specifies the where elements are inserted after.
C<$next> specifies the where elements are inserted before.
One of the two MUST be valied L<PPI::Element> object.
If both are valid, the first paramter is used and the second parameter is ignored.

C<$target> specifies L<PPI::Element> holding elements inserted at the place specified by C<$prev> or C<$next>.

=head2 C<emit_cv($block)>

C<$block> is L<PPI::Structure::Block> object.

  my $___cv___ = AE::cv;

is inserted at the beginning of the block, and

  return $___cv___;

is inserted at the end of the block.

=head2 C<emit_cv_into_function($word)>

C<$word> is L<PPI::Token::Word> object and SHOULD be is_function_declaration is true.
C<emit_cv> is called for the block of the function declaration.

=head2 C<replace_as_async($element, $name, $is_array)>

C<$element> is a L<PPI::Element> object and SHOULD point the name of the function call.
C<$name> is the function name that will be set as the contents of C<$element>.
C<$is_array> is a boolean flag spcifying whether returning context is list context or not.

If the first argument points at C<call> in the following code:

  my $var = 42 + $some->[$idx]{$key}->call($arg1, $arg2) * func();
  # codes follows ...

after the call of this function with C<replace_as_async($elem, 'call_async', 0)>, converted into as follows:

  Module::AnyEvent::Helper::bind_scalar($___cv___, call_async($arg1, $arg2), sub {
  my $var = 42 + shift->recv() * func();
  # codes follows ...
  });

For the case of C<replace_as_async($elem, 'call_async', 1)>, converted into as follows:

  Module::AnyEvent::Helper::bind_array($___cv___, call_async($arg1, $arg2), sub {
  my $var = 42 + shift->recv() * func();
  # codes follows ...
  });

See also L<Module::AnyEvent::Helper>.

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
