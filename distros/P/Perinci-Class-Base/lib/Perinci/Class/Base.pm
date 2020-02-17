package Perinci::Class::Base;

use strict 'subs', 'vars';

use MRO::Compat;

our %SPEC;

$SPEC{get_rinci_meta_for} = {
    v => 1.1,
    is_meth => 1,
    is_class_meth => 1,
    args_as => 'array',
    args => {
        name => {schema=>'str*', req=>1, pos=>0},
    },
    result_naked => 1,
};
sub get_rinci_meta_for {
    my ($package, $name) = @_;
    $package = ref $package if ref $package;

    my $linear_isa = mro::get_linear_isa($package);
    for my $pkg_or_parent (@$linear_isa) {
        print "D:$pkg_or_parent\n";
        if (defined ${"$pkg_or_parent\::SPEC"}{$name}) {
            return ${"$pkg_or_parent\::SPEC"}{$name};
        }
    }
    return undef;
}

$SPEC{modify_rinci_meta_for} = {
    v => 1.1,
    is_meth => 1,
    is_class_meth => 1,
    args_as => 'array',
    args => {
        name  => {schema=>'str*' , req=>1, pos=>0},
        value => {schema=>'hash*', req=>1, pos=>1},
    },
    result_naked => 1,
};
sub modify_rinci_meta_for {
    my ($package, $name, $value) = @_;
    $package = ref $package if ref $package;

    my $meta = $package->get_rinci_meta_for($name)
        or die "Can't modify Rinci metadata for '$name' in class '$package': ".
        "doesn't exist";
    ${"$package\::SPEC"}{$name}
        and warn "Trying to modify Rinci metadata for '$name' in ".
        "package '$package': already exists";

    require Data::ModeMerge;
    my $merge_res = Data::ModeMerge->new->merge($meta, $value);
    die "Can't modify Rinci metadata for '$name': ".
        "Can't merge: $merge_res->{error}" if $merge_res->{error};

    ${"$package\::SPEC"}{$name} = $merge_res->{result};
}

1;
# ABSTRACT: Base class for your Rinci-metadata-containing classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Class::Base - Base class for your Rinci-metadata-containing classes

=head1 VERSION

This document describes version 0.002 of Perinci::Class::Base (from Perl distribution Perinci-Class-Base), released on 2020-02-16.

=head1 SYNOPSIS

In F<My/Animal.pm>:

 package My::Animal;
 use parent 'Perinci::Class::Base';
 
 our %SPEC;
 
 $SPEC{speak} = {
     v => 1.1,
     is_meth => 1,
 };
 sub speak {
     die "Please override me!";
 }
 
 sub new {
     my ($package, %args) = @_;
     bless \%args, $package;
 }
 
 1;

In F<My/Dog.pm>:

 package My::Dog;
 use parent 'My::Animal';
 
 our %SPEC;
 
 # speak's metadata will "inherit" (use metadata from the base class), since we
 # don't have additionl/modified/removed arguments, etc.
 
 sub speak {
     print "woof\n";
     [200];
 }
 
 $SPEC{play_dead} = {
     v => 1.1,
     is_meth => 1,
     args => {
         seconds => {schema=>'uint*', default=>5},
     },
 };
 sub play_dead {
     my ($self, %args) = @_;
     sleep $;
     [200];
 }
 
 1;

in F<My/Parrot.pm>:

 package My::Parrot;
 use parent 'My::Animal';
 
 our %SPEC;
 
 # we are modifying 'speak' metadata as we add an argument.
 $SPEC{speak} = {
     v => 1.,
     is_meth => 1,
     args => {
         word => {schema=>'str*'},
     },
 };
 sub speak {
     my ($self, $word) = @_;
     print "squawk! $word!\n";
     [200];
 }
 
 1;

To get Rinci metadata for a method:

 use My::Dog;
 my $meta = My::Dog->get_rinci_meta_for('speak');

A more convenient syntax to define modified method metadata in F<My/Dog.pm> (the
second argument will be merged using L<Data::ModeMerge>):

 package My::Parrot2;
 use parent 'My::Animal';
 
 our %SPEC;
 
 # we are modifying 'speak' metadata as we add an argument.
 __PACKAGE__->modify_rinci_meta_for(speak => {
     args => {
         word => {schema=>'str*'},
     },
 });
 sub speak {
     my ($self, $word) = @_;
     print "squawk! $word!\n";
     [200];
 }
 
 1;

Another example of modifying method metadata:

 package My::Human;
 use parent 'My::Animal';
 
 our %SPEC;
 
 # we are modifying 'speak' metadata as we remove an argument ('word') and add
 # another ('words').
 __PACKAGE__->modify_rinci_meta_for(speak => {
     args => {
         '!word' => undef,
         words => {schema=>'str*'},
     },
 });
 sub speak {
     my ($self, $words) = @_;
     print "$words!\n";
     [200];
 }
 
 1;

=head1 DESCRIPTION

EXPERIMENTAL, WORK IN PROGRESS.

Perinci::Class::Base is a base class that provides some L<Rinci>-related utility
routines, mainly to get/modify Rinci metadata in a class settings.

=head1 FUNCTIONS


=head2 get_rinci_meta_for

Usage:

 get_rinci_meta_for($name) -> any

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$name>* => I<str>


=back

Return value:  (any)



=head2 modify_rinci_meta_for

Usage:

 modify_rinci_meta_for($name, $value) -> any

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$name>* => I<str>

=item * B<$value>* => I<hash>


=back

Return value:  (any)

=head1 METHODS

=head2 get_sub_meta_for

=head2 modify_sub_meta_for

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Class-Base>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Class-Base>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Class-Base>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Rinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
