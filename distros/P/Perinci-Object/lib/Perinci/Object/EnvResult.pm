package Perinci::Object::EnvResult;

our $DATE = '2021-01-02'; # DATE
our $VERSION = '0.311'; # VERSION

use 5.010;
use strict;
use warnings;

sub new {
    my ($class, $res) = @_;
    $res //= [0, "", undef];
    my $obj = \$res;
    bless $obj, $class;
}

sub new_ok {
    my $class = shift;
    my $res = [200, "OK"];
    if (@_) {
        push @$res, $_[0];
    }
    $class->new($res);
}

sub status {
    my ($self, $new) = @_;
    if (defined $new) {
        die "Status must be an integer between 100 and 555" unless
            int($new) eq $new && $new >= 100 && $new <= 555;
        my $old = ${$self}->[0];
        ${$self}->[0] = $new;
        return $old;
    }
    ${$self}->[0];
}

sub message {
    my ($self, $new) = @_;
    if (defined $new) {
        die "Extra must be a string" if ref($new);
        my $old = ${$self}->[1];
        ${$self}->[1] = $new;
        return $old;
    }
    ${$self}->[1];
}

# avoid 'result' as this is ambiguous (the enveloped one? the naked one?). even
# avoid 'enveloped' (the payload being enveloped? the enveloped result
# (envelope+result inside)?)

sub payload {
    my ($self, $new) = @_;
    if (defined $new) {
        my $old = ${$self}->[2];
        ${$self}->[2] = $new;
        return $old;
    }
    ${$self}->[2];
}

sub meta {
    my ($self, $new) = @_;
    if (defined $new) {
        die "Extra must be a hashref" unless ref($new) eq 'HASH';
        my $old = ${$self}->[3];
        ${$self}->[3] = $new;
        return $old;
    }
    ${$self}->[3];
}

sub is_success {
    my ($self) = @_;
    my $status = ${$self}->[0];
    $status >= 200 && $status <= 299;
}

sub as_struct {
    my ($self) = @_;
    ${$self};
}

1;
# ABSTRACT: Represent enveloped result

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Object::EnvResult - Represent enveloped result

=head1 VERSION

This document describes version 0.311 of Perinci::Object::EnvResult (from Perl distribution Perinci-Object), released on 2020-01-02.

=head1 SYNOPSIS

 use Perinci::Object::EnvResult;
 use Data::Dump; # for dd()

 my $envres = Perinci::Object::EnvResult->new([200, "OK", [1, 2, 3]]);
 dd $envres->is_success, # 1
    $envres->status,     # 200
    $envres->message,    # "OK"
    $envres->payload,    # [1, 2, 3]
    $envres->meta,       # undef
    $envres->as_struct;  # [200, "OK", [1, 2, 3]]

 # setting status, message, result, extra
 $envres->status(404);
 $envres->message('Not found');
 $envres->payload(undef);
 $envres->meta({errno=>-100});

 # shortcut: create a new OK result ([200, "OK"] or [200, "OK", $payload])
 $envres = Perinci::Object::EnvResult->new_ok();
 $envres = Perinci::Object::EnvResult->new_ok(42);

=head1 DESCRIPTION

This class provides an object-oriented interface for enveloped result (see
L<Rinci::function> for more details).

=head1 METHODS

=head2 new($res) => OBJECT

Create a new object from $res enveloped result array.

=head2 new_ok([ $actual_res ]) => OBJECT

Shortcut for C<< new([200,"OK",$actual_res]) >>, or just C<< new([200,"OK"]) >>
if C<$actual_res> is not specified.

=head2 $envres->status

Get or set status (the 1st element).

=head2 $envres->message

Get or set message (the 2nd element).

=head2 $envres->payload

Get or set the actual payload (the 3rd element).

=head2 $envres->meta

Get or set result metadata (the 4th element).

=head2 $envres->as_struct

Return the represented data structure.

=head2 $envres->is_success

True if status is between 200-299.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Perinci-Object/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Object>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
