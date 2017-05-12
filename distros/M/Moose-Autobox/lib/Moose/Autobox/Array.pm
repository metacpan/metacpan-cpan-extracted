package Moose::Autobox::Array;
# ABSTRACT: the Array role
use Moose::Role 'with';
use Moose::Autobox;
use List::MoreUtils 0.07 ();

use Syntax::Keyword::Junction::All ();
use Syntax::Keyword::Junction::Any ();
use Syntax::Keyword::Junction::None ();
use Syntax::Keyword::Junction::One ();
use namespace::autoclean;

our $VERSION = '0.16';

with 'Moose::Autobox::Ref',
     'Moose::Autobox::List',
     'Moose::Autobox::Indexed';

## Array Interface

sub pop {
    my ($array) = @_;
    CORE::pop @$array;
}

sub push {
    my ($array, @rest) = @_;
    CORE::push @$array, @rest;
    $array;
}

sub unshift {
    my ($array, @rest) = @_;
    CORE::unshift @$array, @rest;
    $array;
}

sub delete {
    my ($array, $index) = @_;
    CORE::delete $array->[$index];
}

sub shift {
    my ($array) = @_;
    CORE::shift @$array;
}

sub slice {
    my ($array, $indicies) = @_;
    [ @{$array}[ @{$indicies} ] ];
}

# NOTE:
# sprintf args need to be reversed,
# because the invocant is the array
sub sprintf { CORE::sprintf $_[1], @{$_[0]} }

## ::List interface implementation

sub head { $_[0]->[0] }
sub tail { [ @{$_[0]}[ 1 .. $#{$_[0]} ] ] }

sub length {
    my ($array) = @_;
    CORE::scalar @$array;
}

sub grep {
    my ($array, $sub) = @_;
    [ CORE::grep { $sub->($_) } @$array ];
}

sub map {
    my ($array, $sub) = @_;
    [ CORE::map { $sub->($_) } @$array ];
}

sub join {
    my ($array, $sep) = @_;
    $sep ||= '';
    CORE::join $sep, @$array;
}

sub reverse {
    my ($array) = @_;
    [ CORE::reverse @$array ];
}

sub sort {
    my ($array, $sub) = @_;
    $sub ||= sub { $a cmp $b };
    [ CORE::sort { $sub->($a, $b) } @$array ];
}

sub first {
    $_[0]->[0];
}

sub last {
    $_[0]->[$#{$_[0]}];
}

## ::Indexed implementation

sub at {
    my ($array, $index) = @_;
    $array->[$index];
}

sub put {
    my ($array, $index, $value) = @_;
    $array->[$index] = $value;
}

sub exists {
    my ($array, $index) = @_;
    CORE::exists $array->[$index];
}

sub keys {
    my ($array) = @_;
    [ 0 .. $#{$array} ];
}

sub values {
    my ($array) = @_;
    [ @$array ];
}

sub kv {
    my ($array) = @_;
    $array->keys->map(sub { [ $_, $array->[$_] ] });
}

sub each {
    my ($array, $sub) = @_;
    for my $i (0 .. $#$array) {
      $sub->($i, $array->[ $i ]);
    }
}

sub each_key {
    my ($array, $sub) = @_;
    $sub->($_) for (0 .. $#$array);
}

sub each_value {
    my ($array, $sub) = @_;
    $sub->($_) for @$array;
}

sub each_n_values {
    my ($array, $n, $sub) = @_;
    my $it = List::MoreUtils::natatime($n, @$array);

    while (my @vals = $it->()) {
        $sub->(@vals);
    }

    return;
}

# end indexed

sub flatten {
    @{$_[0]}
}

sub _flatten_deep {
    my @array = @_;
    my $depth = CORE::pop @array;
    --$depth if (defined($depth));

    CORE::map {
        (ref eq 'ARRAY')
            ? (defined($depth) && $depth == -1) ? $_ : _flatten_deep( @$_, $depth )
            : $_
    } @array;

}

sub flatten_deep {
    my ($array, $depth) = @_;
    [ _flatten_deep(@$array, $depth) ];
}

## Junctions

sub all {
    my ($array) = @_;
    return Syntax::Keyword::Junction::All->new(@$array);
}

sub any {
    my ($array) = @_;
    return Syntax::Keyword::Junction::Any->new(@$array);
}

sub none {
    my ($array) = @_;
    return Syntax::Keyword::Junction::None->new(@$array);
}

sub one {
    my ($array) = @_;
    return Syntax::Keyword::Junction::One->new(@$array);
}

## Print

sub print { CORE::print @{$_[0]} }
sub say   { CORE::print @{$_[0]}, "\n" }

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Autobox::Array - the Array role

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  use Moose::Autobox;

  [ 1..5 ]->isa('ARRAY'); # true
  [ a..z ]->does('Moose::Autobox::Array'); # true
  [ 0..2 ]->does('Moose::Autobox::List'); # true

  print "Squares: " . [ 1 .. 10 ]->map(sub { $_ * $_ })->join(', ');

  print [ 1, 'number' ]->sprintf('%d is the loneliest %s');

  print ([ 1 .. 5 ]->any == 3) ? 'true' : 'false'; # prints 'true'

=head1 DESCRIPTION

This is a role to describe operations on the Array type.

=head1 METHODS

=over 4

=item C<pop>

=item C<push ($value)>

=item C<shift>

=item C<unshift ($value)>

=item C<delete ($index)>

=item C<sprintf ($format_string)>

=item C<slice (@indices)>

=item C<flatten>

=item C<flatten_deep ($depth)>

=item C<first>

=item C<last>

=back

=head2 Indexed implementation

=over 4

=item C<at ($index)>

=item C<put ($index, $value)>

=item C<exists ($index)>

=item C<keys>

=item C<values>

=item C<kv>

=item C<each>

=item C<each_key>

=item C<each_value>

=item C<each_n_values ($n, $callback)>

=back

=head2 List implementation

=over 4

=item C<head>

=item C<tail>

=item C<join (?$seperator)>

=item C<length>

=item C<map (\&block)>

=item C<grep (\&block)>

Note that, in both the above, $_ is in scope within the code block, as well as
being passed as $_[0]. As per CORE::map and CORE::grep, $_ is an alias to
the list value, so can be used to modify the list, viz:

    use Moose::Autobox;

    my $foo = [1, 2, 3];
    $foo->map( sub {$_++} );
    print $foo->dump;

yields

   $VAR1 = [
             2,
             3,
             4
           ];

=item C<reverse>

=item C<sort (?\&block)>

=back

=head2 Junctions

=over 4

=item C<all>

=item C<any>

=item C<none>

=item C<one>

=back

=over 4

=item C<meta>

=item C<print>

=item C<say>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Moose-Autobox>
(or L<bug-Moose-Autobox@rt.cpan.org|mailto:bug-Moose-Autobox@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
