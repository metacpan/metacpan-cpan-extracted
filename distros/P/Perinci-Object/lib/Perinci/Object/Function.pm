package Perinci::Object::Function;

our $DATE = '2017-02-03'; # DATE
our $VERSION = '0.30'; # VERSION

use 5.010;
use strict;
use warnings;

use parent qw(Perinci::Object::Metadata);

sub type { "function" }

# convenience for accessing features property
sub feature {
    my $self = shift;
    my $name = shift;
    if (@_) {
        die "1.0 can't set feature" if $self->v eq 1.0;
        my $value = shift;
        ${$self}->{features} //= {};
        my $old = ${$self}->{features}{$name};
        ${$self}->{features}{$name} = $value;
        return $old;
    } else {
        ${$self}->{features}{$name};
    }
}

sub features {
    my $self = shift;
    ${$self}->{features} // {};
}

# transaction can be used to emulate dry run, by calling with -tx_action =>
# 'check_state' only
sub can_dry_run {
    my $self = shift;
    my $ff = ${$self}->{features} // {};
    $ff->{dry_run} // $ff->{tx} && $ff->{tx}{v} == 2;
}

sub default_dry_run {
    my $self = shift;
    my $ff = ${$self}->{features} // {};
    ref($ff->{dry_run}) eq 'HASH' && $ff->{dry_run}{default};
}

# convenience for accessing args property
sub arg {
    my $self = shift;
    my $name = shift;
    if (@_) {
        die "1.0 can't set arg" if $self->v eq 1.0;
        my $value = shift;
        ${$self}->{args} //= {};
        my $old = ${$self}->{args}{$name};
        ${$self}->{args}{$name} = $value;
        return $old;
    } else {
        ${$self}->{args}{$name};
    }
}

1;
# ABSTRACT: Represent function metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Object::Function - Represent function metadata

=head1 VERSION

This document describes version 0.30 of Perinci::Object::Function (from Perl distribution Perinci-Object), released on 2017-02-03.

=head1 SYNOPSIS

 use Perinci::Object;

 $SPEC{foo} = {
     v        => 1.1,
     args     => { b => {schema=>'int', req=>0} },
     features => {idempotent=>1},
 };
 my $risub = risub $SPEC{foo};
 print $risub->feature('idempotent'), # 1
       $risub->arg('b')->{req},       # 0
       $risub->arg('a');              # undef

=head1 DESCRIPTION

This class provides an object-oriented interface for function metadata.

=head1 METHODS

=head2 new($meta) => OBJECT

Create a new object from $meta. If $meta is undef, creates an empty metadata.

=head2 $risub->type => str

Will return C<function>.

=head2 $risub->features => HASH

Return the C<features> property.

=head2 $risub->feature(NAME[, VALUE])

Get or set named feature (B<features> property in metadata). If a feature
doesn't exist, undef will be returned.

=head2 $risub->can_dry_run => BOOL

Check whether function can do dry run, either from the C<dry_run> feature, or
from the C<tx> feature. (Transaction can be used to emulate dry run, by calling
the function with C<< -tx_action => 'check_state' >> only.)

=head2 $risub->default_dry_run => BOOL

Starting from Rinci 1.1.83, the C<dry_run> feature property can be a hash
instead of a bool, and can contain this pair C<< default=>1 >> to specify that
dry-run mode should be the default operation (e.g. for safety).

=head2 $risub->arg(NAME[, VALUE])

Get or set argument (B<args> property in metadata). If an argument doesn't
exist, undef will be returned.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Object>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Object>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
