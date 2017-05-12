package Test::Class::Filter::Tags;

use strict;
use warnings;

use Attribute::Method::Tags;
use Attribute::Method::Tags::Registry;
use MRO::Compat;
use Test::Class;

use base qw( Exporter );

our $VERSION = '0.11';

# import the 'Tags' attribute into the caller
our @EXPORT = qw( Tags );

my $filter = sub {
    my ( $test_class, $test_method ) = @_;

    # don't filter if our relevant env vars not set`
    return 1 unless defined $ENV{ TEST_TAGS }
      or defined $ENV{ TEST_TAGS_SKIP };

    my $suppressed = grep {
        Attribute::Method::Tags::Registry->method_has_tag(
            $test_class,
            $test_method,
            $_
        )
    } __expand_filter_vars( $ENV{ TEST_TAGS_SKIP } );

    return 0 if $suppressed;

    # don't filter on set tags, if there are no set tags
    return 1 unless defined $ENV{ TEST_TAGS };

    my $matched = grep { 
        Attribute::Method::Tags::Registry->method_has_tag(
            $test_class,
            $test_method,
            $_
        );
    } __expand_filter_vars( $ENV{ TEST_TAGS } );

    return 1 if $matched;
};

# as test_class permits changing of the TEST_METHOD definitions,
# support doing similar for our controlling ENV vars
sub __expand_filter_vars {
    my $val = shift;

    return if not defined $val;

    $val =~ s/^\s+//;
    $val =~ s/\s+$//;

    my @tags = split /[\s,]/, $val;

    return @tags;
}

# and finally, add our filter callback.
Test::Class->add_filter( $filter );

# supporting method, to determine if any instances of method have tag defined
# in current class, and all subclasses.
sub method_has_tag {
    my ( $self, $class, $method, $tag ) = @_;

    my $isa = mro::get_linear_isa( $class );
    foreach my $c ( @{ $isa } ) {
        return 1 if Attribute::Method::Tags::Registry->method_has_tag(
            $c, $method, $tag
        );
    }

    return 0;
}

1;

__END__

=head1 NAME

Test::Class::Filter::Tags - Selectively run only a subset of Test::Class tests that inclusde/exclude the specified tags.

=head1 SYNOPSIS

 # define a test baseclass, to avoid boilerplate

 package MyTests::Base;

 # load the filter class.  This will both add the filter to Test::Class, as
 # well as importing the 'Tags' attribute into the current namespace

 use Test::Class::Filter::Tags

 # and, of course, inherit from Test::Class;

 use base qw( MyTests::Base );

 1;


 package MyTests::Wibble;

 # using custom baseclass, don't have to worry about importing attribute
 # class for each test

 use Base qw( Test::Class );

 # can specify both Test and Tags attributes on test methods

 sub t_foo : Test( 1 ) Tags( quick fast ) {
 }

 sub t_bar : Test( 1 ) Tags( loose ) {
 }

 sub t_baz : Test( 1 ) Tags( fast ) {
 }

 1;


 #
 # in Test::Class driver script, or your Test::Class baseclass
 #

 # load the test classes, in whatever manner you normally use
 use MyTests::Wibble;

 $ENV{ TEST_TAGS } = 'quick,loose';

 Test::Class->runtests;

 # from the test above, only t_foo and t_bar methods would be run, the
 # first because it has the 'quick' tag, and the second becuase it has
 # 'loose' tag.  t_baz doesn't have either tag, so it's not run.

 # Alternatively, can specify TEST_TAGS_SKIP, in a similar fashion,
 # to *not* run tests with the specified tags

=head1 DESCRIPTION

When used in conjunction with L<Test::Class> tests, that also define
L<Attribute::Method::Tags> tags, this class allows filtering of the
tests that will be run.

If $ENV{ TEST_TAGS } is set, it will be treated as a list of tags,
seperated by any combination of whitespace or commas.  The tests that
will be run will only be the subset of tests that have at least of one
these tags specified.

Conversely, you may want to run all tests that *don't* have specific
tags.  This can be done by specifying the tags to exclude in
$ENV{ TEST_TAGS_SKIP }.

Note that, as per normal Test::Class behaviour, only normal tests will
be filtered.  Any fixture tests (startup, shutdown, setup and teardown)
will still be run, where appropriate, whether they have the given
attributes or not.

=head1 IMPORTS

By using this class, you'll get the 'Tags' attribute imported into your
namespace.  This is required to be able to add B<Tags> attribute to your
test methods.  This will also cause L<Attribute::Method::Tags> to be
pre-pended to the ISA of the using class.

=head1 METHODS

=over 4

=item method_has_tag( $class, $method, $tag )

Returns a true value if $tag is defined on $method in $class, or any
of $class'es super-classes.  This may sound of limited use, but one of the
use cases presented to me when developing this module was to have setup
fixtures conditionally run if the method that's being tested has a
specific tag.

=back

=head1 TAGS ADDITIVE OVER INHERITANCE

When inheriting from test classes, the subclasses will adopt any tags
that the superclass methods have, in addition to any that they specify.
(ie, tags are addative, when subclass and superclass have the same method
with different tags, the tags for the subclass method will be those from
both).

=head1 SEE ALSO

=over 4

=item Test::Class

This class is implemented via the Test::Class filtering mechanism.

=item Attributes::Method::Tag

This class supplies the 'Tags' attribute to consuming classes.  Note that this
will alsp be pre-pended to the @ISA for any consuming class.

=back

=head1 AUTHOR

Mark Morgan <makk384@gmail.com>

=head1 BUGS

Please send bugs or feature requests through to
bugs-Test-Class-Filter-Tags@rt.rt.cpan.org or through web interface
L<http://rt.cpan.org> .

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Mark Morgan, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

