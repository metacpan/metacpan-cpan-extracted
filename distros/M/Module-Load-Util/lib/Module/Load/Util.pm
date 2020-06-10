package Module::Load::Util;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-09'; # DATE
our $DIST = 'Module-Load-Util'; # DIST
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';

use Exporter 'import';
our @EXPORT_OK = qw(
                       load_module_with_optional_args
                       instantiate_class_with_optional_args
               );

sub load_module_with_optional_args {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    my $module_with_optional_args = shift;

    my $caller = $opts->{caller} // caller(0);

    if (defined $opts->{ns_prefix}) {
        $module_with_optional_args =
            $opts->{ns_prefix} . ($opts->{ns_prefix} =~ /::\z/ ? '':'::') .
            $module_with_optional_args;
    }

    my ($module, $args) = @_;
    if ($module_with_optional_args =~ /(.+?)=(.*)/) {
        $module = $1;
        $args = [split /,/, $2];
    } else {
        $module = $module_with_optional_args;
        $args = [];
    }

    # XXX option load=0?
    (my $modulepm = "$module.pm") =~ s!::!/!g;
    require $modulepm;

    my $do_import = !defined($opts->{import}) || $opts->{import};
    if ($do_import) {
        eval "package $caller; $module->import(\@{\$args});";
        die if $@;
    }

    {module=>$module, args=>$args};
}

sub instantiate_class_with_optional_args {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    my $class_with_optional_args = shift;

    my $caller = $opts->{caller} // caller(0);

    my $res = load_module_with_optional_args(
        {%$opts, caller=>$caller, import=>0},
        $class_with_optional_args,
    );
    my $class = $res->{module};
    my $args  = $res->{args};

    my $constructor = $opts->{constructor} // 'new';

    my $obj = $class->$constructor(@$args);
    $obj;
}

1;
# ABSTRACT: Some utility routines related to module loading

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Load::Util - Some utility routines related to module loading

=head1 VERSION

This document describes version 0.001 of Module::Load::Util (from Perl distribution Module-Load-Util), released on 2020-06-09.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 load_module_with_optional_args

Usage:

 load_module_with_optional_args( [ \%opts , ] $module_with_optional_args );

Examples:

 load_module_with_optional_args("Color::RGB::Util");                # default imports, equivalent to runtime version of 'use Color::RGB::Util'
 load_module_with_optional_args({import=>0}, "Color::RGB::Util");   # do not import,   equivalent to runtime version of 'use Color::RGB::Util ()'
 load_module_with_optional_args("Color::RGB::Util=rgb2hsv");        # imports rgb2hsv. equivalent to runtime version of 'use Color::RGB::Util qw(rgb2hsv)'
 load_module_with_optional_args({ns_prefix=>"Color"}, "RGB::Util"); # equivalent to loading Color::RGB::Util

Known options:

=over

=item * import

Bool. Defaults to true.

= item * ns_prefix

=back

=head2 instantiate_class_with_optional_args

Usage:

 instantiate_class_with_optional_args( [ \%opts , ] $class_with_optional_args );

Examples:

 my $obj = instantiate_class_with_optional_args("WordList::Color::Any");                           # equivalent to: require WordList::Color::Any; WordList::Color::Any->new;
 my $obj = instantiate_class_with_optional_args("WordList::Color::Any=theme,Foo");                 # equivalent to: require WordList::Color::Any; WordList::Color::Any->new(theme=>"Foo");
 my $obj = instantiate_class_with_optional_args({ns_prefix=>"WordList"}, "Color::Any=theme,Foo");  # equivalent to: require WordList::Color::Any; WordList::Color::Any->new(theme=>"Foo");

This is like L</load_module_with_optional_args> but the arguments specified
after C<=> will be passed to the class constructor instead of used as import
arguments.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Load-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Load-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Load-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Load>

L<Class::Load>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
