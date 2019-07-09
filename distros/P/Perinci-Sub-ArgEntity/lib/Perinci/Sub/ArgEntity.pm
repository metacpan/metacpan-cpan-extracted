package Perinci::Sub::ArgEntity;

our $DATE = '2019-06-24'; # DATE
our $VERSION = '0.020'; # VERSION

1;
# ABSTRACT: Convention for Perinci::Sub::ArgEntity::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::ArgEntity - Convention for Perinci::Sub::ArgEntity::* modules

=head1 VERSION

This document describes version 0.020 of Perinci::Sub::ArgEntity (from Perl distribution Perinci-Sub-ArgEntity), released on 2019-06-24.

=head1 SYNOPSIS

In your L<Rinci> function metadata:

 {
     v => 1.1,
     summary => 'Some function',
     args => {
         file => {
             # specification for 'file' argument
             schema  => 'str*',
             'x.schema.entity' => 'filename',
         },
         url => {
             # specification for 'url' argument
             schema  => ['array*', of => 'str*'],
             'x.schema.element_entity' => 'riap_url',
         },
     },
 }

Now in command-line application:

 % myprog --file <tab>

will use completion routine from function C<complete_arg_val> in module
L<Perinci::Sub::ArgEntity::filename>, while:

 % myprog --url <tab>

will use element completion routine from function C<complete_arg_val> in module
L<Perinci::Sub::ArgEntity::riap_url>.

=head1 DESCRIPTION

B<STATUS:> This module is now deprecated. It is now preferred to express the
"type" or "entity" of a schema in the schema name itself, e.g.
L<Sah::Schema::filename> instead of L<Perinci::Sub::ArgEntity::filename>,
reducing duplication. To specify completion rule in the L<Sah> schema instead of
in the L<Rinci> argument specification, you can use
L<Perinci::Sub::XCompletion>. So far, Perinci::Sub::ArgEntity *is* only used to
specify completion rule.

The namespace C<Perinci::Sub::ArgEntity::*> is used to put data and routine
related to certain types (entities) of function arguments.

=head2 Completion

The idea is: instead of having to put completion routine (coderef) directly in
argument specification, like:

 file => {
     # specification for 'file' argument
     schema  => 'str*',
     completion => \&Complete::File::complete_file,
 },

you just specify the argument as being of a certain entity using the attribute
C<x.schema.entity>:

 file => {
     # specification for 'file' argument
     schema  => 'str*',
     'x.schema.entity' => 'filename',
 },

and module like L<Perinci::Sub::Complete> will search the appropriate completion
routine (if any) for your argument. In this case, it will search for the module
named C<Perinci::Sub::ArgEntity::> + I<entity_name> and then look up the
function C<complete_arg_val>.

Note that aside from completion, there are other uses for the C<x.schema.entity>
attribute, e.g. in help message generation, etc. More things will be formally
specified in the future.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-ArgEntity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-ArgEntity>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-ArgEntity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Rinci>, L<Rinci::function>

L<Complete>, L<Perinci::Sub::Complete>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
