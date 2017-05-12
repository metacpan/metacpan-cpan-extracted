package Perinci::Object::EnvResultTable;

our $DATE = '2017-02-03'; # DATE
our $VERSION = '0.30'; # VERSION

use 5.010;
use strict;
use warnings;

use parent qw(Perinci::Object::EnvResult);

sub add_field {
    my ($self, $name, %attrs) = @_;
    ${$self}->[3]{'table.fields'} //= [];
    push @{ ${$self}->[3]{'table.fields'} }, $name;
}

1;
# ABSTRACT: Represent enveloped result (table)

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Object::EnvResultTable - Represent enveloped result (table)

=head1 VERSION

This document describes version 0.30 of Perinci::Object::EnvResultTable (from Perl distribution Perinci-Object), released on 2017-02-03.

=head1 SYNOPSIS

 use Perinci::Object::EnvResultTable;

 sub myfunc {
     ...

     my $envres = Perinci::Object::EnvResultTable->new;

     # add fields
     $envres->add_field('foo');
     $envres->add_field('foo');

     # finally, return the result
     return $envres->as_struct;
 }

=head1 DESCRIPTION

This class is a subclass of L<Perinci::Object::EnvResult> and provides
convenience methods when you want to return table data.

=head1 METHODS

=head2 new($res) => OBJECT

Create a new object from C<$res> enveloped result array.

=head2 $envres->add_field($name, %attrs)

Add a table field. This will create/push an entry to the C<table.fields> result
metadata array.

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

L<Perinci::Object::EnvResult>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
