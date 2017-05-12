package Sub::Inspector;
use 5.008_001;
use strict;
use warnings;
use B ();
use Carp ();
our @CARP_NOT;
use attributes;
use Data::Dumper ();
use Data::Dump::Streamer ();

our $VERSION = '0.05';

sub new {
    my ($class, $code) = @_;
    _throw($code) unless ref($code) eq 'CODE';
    bless +{ code => $code }, $class;
}

sub file { B::svref_2object(_code(@_))->GV->FILE }
sub line { B::svref_2object(_code(@_))->GV->LINE }
sub name { B::svref_2object(_code(@_))->GV->NAME }

sub proto     { B::svref_2object(_code(@_))->PV }
sub prototype { proto(@_) }

sub attrs      { attributes::get(_code(@_)) }
sub attributes { attrs(@_) }

sub dump      { Data::Dump::Streamer::Dumper(_code(@_)) }
sub as_string { Sub::Inspector::dump(@_) }

sub _throw {
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse  = 1;
    local @CARP_NOT = (__PACKAGE__);
    Carp::croak "argument isn't a subroutine reference: " . Data::Dumper::Dumper($_[0]);
}

sub _code {
    my ($stuff, $arg) = @_;
    # instance method
    if (ref($stuff) eq __PACKAGE__) {
        return $stuff->{code};
    # calss method
    } elsif (defined($stuff) && $stuff eq __PACKAGE__) {
        return $arg if (ref($arg) eq 'CODE');
        _throw($arg);
    }
}

1;
__END__

=head1 NAME

Sub::Inspector - get infomation (prototype, attributes, name, etc) from a subroutine reference

=head1 SYNOPSIS

    use Sub::Inspector;
    use File::Spec;

    my $code = File::Spec->can('canonpath');

    print Sub::Inspector->file($code); #=> '/Users/Cside/perl5/ ...'
    print Sub::Inspector->line($code); #=> 71
    print Sub::Inspector->name($code); #=> 'canonpath'
    print Sub::Inspector->dump($code); #=> 'sub { my ($self, $path) = @_; ...'

    sub has_proto (&;@) {}
    sub has_attrs :method :lvalue {}

    print Sub::Inspector->proto(\&has_proto); #=> '&;@'
    print Sub::Inspector->attrs(\&has_attrs); #=> ('method', 'lvalue')


    # OO-Style

    my $inspector = Sub::Inspector->new($code);

    print $inspector->file; #=> '/Users/Cside/perl5/ ...'
    print $inspector->line; #=> 71
    print $inspector->name; #=> 'canonpath'

=head1 DESCRIPTION

This module enable to get metadata (prototype, attributes, method name, etc) from a coderef.
We can get them by the buit-in module, B.pm. However, it is a bit difficult to memorize how to use it.

=head1 Functions

NOTE: You can call each method whether as instance method or as class method.

=over

=item $inspector->file

=item $inspector->line

=item $inspector->name

=item $inspector->proto

alias: prototype

=item $inspector->attrs

alias: attributes

=item $inspector->dump

alias: as_string

=back

=head1 SEE ALSO

=over

=item L<B>

=item L<B::Deparser>

=back

=head1 AUTHOR

Hiroki Honda (Cside) E<lt>cside.story [at] gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
