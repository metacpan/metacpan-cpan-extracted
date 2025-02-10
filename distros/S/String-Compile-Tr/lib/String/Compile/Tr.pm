use 5.010;
use strict;
use warnings;

package String::Compile::Tr;

=encoding UTF-8

=head1 NAME

String::Compile::Tr - compile tr/// expressions

=head1 VERSION

Version 0.05

=cut

our
$VERSION = '0.05';


=head1 SYNOPSIS

    use String::Compile::Tr;
    
    my $search = '/+=';
    my $replace = '-_';
    my $s = 'De/0xv5y3w8BpLF8ubOo+w==';
    trgen($search, $replace, 'd')->($s);
    # $s = 'De-0xv5y3w8BpLF8ubOo_w'

=head1 DESCRIPTION

The usual approach when operands of a C<tr///> operator shall be
variables is to apply C<eval> on a string to interpolate the operands.
The drawback of this approach are possible unwanted side effects induced
by the variables' content, e.g.

    $search = '//,warn-trapped,$@=~tr/';
    eval "tr/$search//d";

C<String::Compile::Tr> offers an alternative where the content of a
variable can be used as operand without C<eval>'ing it. 
Instead the operands of a C<tr///> operator are overloaded at runtime
inside an constant C<eval '...'>.

C<trgen(*SEARCH*, *REPLACE*, *OPT*)> compiles an anonymous sub that
performs almost the same operation as C<tr/*SEARCH*/*REPLACE*/*OPT*>,
but allows variable operands.

C<trgen> is imported by default by C<use String::Compile::Tr>.


=head1 FUNCTIONS

=head2 trgen

    trgen(search, replace, [options])

C<trgen> returns an anonymous subroutine that performs an almost identical 
operation as C<tr/search/replace/options>.
The C<tr> target may be given as an argument to the generated sub
or is the default input C<$_> otherwise.


=head1 ERRORS

C<trgen> will throw an exception if an invalid option is specified
or the C<tr> operation cannot be compiled.

=head1 EXAMPLES

Proposed usages of this module are:

    use String::Compile::Tr;

    my $search = 'abc';
    my $replace = '123';
    my $tr = trgen($search, $replace);
    my $s = 'fedcba';
    $tr->($s);
    # $s is 'fed321' now

    my @list = qw(axy bxy cxy);
    $tr->() for @list;
    # @list is now ('1xy', '2xy', '3xy');

    print trgen($search, $replace, 'r')->('fedcba'); # 'fed321'

=head1 RESTRICTIONS

Character ranges are not supported in the search and replace lists.
All characters are interpreted literally.
This is caused by the fact that C<tr> does not support these neither.
It's the compiler that expands character ranges in C<tr>'s operands
before handing them over.

Overloading constants in C<eval '...'> requires perl v5.10.

=head1 AUTHOR

Jörg Sommrey, C<< <git at sommrey.de> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Jörg Sommrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<perlop/"tr/*SEARCHLIST*/*REPLACEMENTLIST*/cdsr">

L<perlfunc/eval>

L<Exporter::Tiny::Manual::Importing>

L<Regexp::Tr> provides a similar functionality, though this C<eval>'s
its oprands.

=cut

use Carp;
use String::Compile::Tr::Overload;

use Exporter::Shiny our @EXPORT = qw(trgen);

*search = *String::Compile::Tr::Overload::search;
*replace = *String::Compile::Tr::Overload::replace;

sub trgen {
    local our ($search, $replace);
    my $options;
    ($search, $replace, $options) = @_;
    $replace = '' unless defined $replace;
    $options = '' unless defined $options;
    my ($opt) = $options =~ /^([cdsr]*)$/;
    $opt = '' unless defined $opt;
    croak "options invalid: $options" if $options && $options ne $opt;
    my $ret;
    my $template = <<'EOS';
    $ret = sub {
        local *_ = \$_[0] if @_;
        tr/:search:/:replace:/%s;
    }; 1
EOS
    my $code = sprintf $template, $opt;

    eval $code or croak $@;
    $ret;
}

1;
