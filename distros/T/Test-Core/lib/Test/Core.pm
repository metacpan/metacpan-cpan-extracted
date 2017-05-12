package Test::Core;
$Test::Core::VERSION = '0.0200';
use Data::Dump                  ();
use Import::Into;
use Module::Load                ();
use Test::Modern                ();
use Test::MockModule            ();
use Test::MockObject            ();
use Test::MockObject::Extends   ();

sub import {
    my $caller = scalar caller();
    Test::Modern->import::into($caller, qw(-default -deeper !TD));
    Data::Dump->import::into($caller);

    no strict 'refs';
    *{$caller . '::MM'}  = \&mock_module;
    *{$caller . '::MO'}  = \&mock_object;
}

sub mock_module {
    my ($class, %mocks) = @_;
    my $mock_module = Test::MockModule->new($class);
    while (my ($method, $override) = each(%mocks)) {
        $mock_module->mock(
            $method,
            ('CODE' eq ref $override ? $override : sub { $override })
        );
    }
    return $mock_module;
}

sub mock_object {
    my (%mocks) = @_;
    my $isa         = delete $mocks{isa};
    my $mock_object = $isa
        ? Test::MockObject::Extends->new($isa)
        : Test::MockObject->new;
    while (my ($method, $override) = each(%mocks)) {
        $mock_object->mock(
            $method,
            ('CODE' eq ref $override ? $override : sub { $override })
        );
    }
    return $mock_object;
}

1;

# ABSTRACT: Modern Perl testing with a single import

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Core - Modern Perl testing with a single import

=head1 VERSION

version 0.0200

=head1 SYNOPSIS

    use Test::Core;

    # Your tests here

    done_testing

=head1 DESCRIPTION

Test::Core provides the best testing harness of Modern Perl in a single, user-friendly import. It builds off of L<Test::Modern> while also providing clean interfaces to dumping and mocking facilities from other libraries.

Test::Core also automatically imposes L<strict> and L<warnings> on your script, and loads L<IO::File>. Although Test::Modern is a modern testing framework, it should run fine on pre-modern versions of Perl.

=head1 FUNCTIONS

=head2 Test::More

Test::Core exports the following from L<Test::More>:

=over 4

=item C<< ok($truth, $description) >>

=item C<< is($got, $expected, $description) >>

=item C<< isnt($got, $unexpected, $description) >>

=item C<< like($got, $regexp, $description) >>

=item C<< unlike($got, $regexp, $description) >>

=item C<< is_deeply($got, $expected, $description) >>

=item C<< cmp_ok($got, $operator, $expected, $description) >>

=item C<< new_ok($class, \@args, $name) >>

=item C<< isa_ok($object|$subclass, $class, $name) >>

=item C<< can_ok($object|$class, @methods) >>

=item C<< pass($description) >>

=item C<< fail($description) >>

=item C<< subtest($description, sub { ... }) >>

=item C<< diag(@messages) >>

=item C<< note(@messages) >>

=item C<< explain(@messages) >>

=item C<< skip($why, $count) if $reason >>

=item C<< todo_skip($why, $count) if $reason >>

=item C<< $TODO >>

=item C<< plan(%plan) >>

=item C<< done_testing >>

=item C<< BAIL_OUT($reason) >>

=back

=head2 Test::Fatal

Test::Core exports the following from L<Test::Fatal>:

=over 4

=item C<< exception { BLOCK } >>

=back

=head2 Test::Warnings

Test::Core exports the following from L<Test::Warnings>:

=over 4

=item C<< warning { BLOCK } >>

=item C<< warnings { BLOCK } >>

=back

=head2 Test::API

Test::Core exports the following from L<Test::API>:

=over 4

=item C<< public_ok($package, @functions) >>

=item C<< import_ok($package, export => \@functions, export_ok => \@functions) >>

=item C<< class_api_ok($class, @methods) >>

=back

=head2 Test::LongString

Test::Core exports the following from L<Test::LongString>:

=over

=item C<< is_string($got, $expected, $description) >>

=item C<< is_string_nows($got, $expected, $description) >>

=item C<< like_string($got, $regexp, $description) >>

=item C<< unlike_string($got, $regexp, $description) >>

=item C<< contains_string($haystack, $needle, $description) >>

=item C<< lacks_string($haystack, $needle, $description) >>

=back

=head2 Test::Deep

Test::Core exports the following from L<Test::Deep>:

=over 4

=item C<< cmp_deeply($got, $expected, $description) >>

=item C<< ignore() >>

=item C<< methods(%hash) >>

=item C<< listmethods(%hash) >>

=item C<< shallow($thing) >>

=item C<< noclass($thing) >>

=item C<< useclass($thing) >>

=item C<< re($regexp, $capture_data, $flags) >>

=item C<< superhashof(\%hash) >>

=item C<< subhashof(\%hash) >>

=item C<< bag(@elements) >>

=item C<< set(@elements) >>

=item C<< superbagof(@elements) >>

=item C<< subbagof(@elements) >>

=item C<< supersetof(@elements) >>

=item C<< subsetof(@elements) >>

=item C<< all(@expecteds) >>

=item C<< any(@expecteds) >>

=item C<< obj_isa($class) >>

=item C<< array_each($thing) >>

=item C<< str($string) >>

=item C<< num($number, $tolerance) >>

=item C<< bool($value) >>

=item C<< code(\&subref) >>

=back

=head2 Test::Modern

Test::Core exports the following from L<Test::Modern>:

=over 4

=item C<< does_ok($object|$subclass, $class, $name) >>

=item C<< namespaces_clean(@namespaces) >>

=item C<< is_fastest($implementation, $times, \%implementations, $desc) >>

=item C<< object_ok($object, $name, %tests) >>

=back

=head2 Data::Dump

Test::Core exports the following from L<Data::Dump>:

=over 4

=item C<< dd(@objects) >>

=item C<< ddx(@objects) >>

=back

=head2 Test::Core

Test::Core implements the following mocking functions using L<Test::MockModule>, L<Test::MockObject>, and L<Test::MockObject::Extends>:

=over 4

=item C<< MM($class, %mocks) >>

    # This module is mocked as long as $mock is in scope
    my $mock = MM('DateTime', year => 1776);

=item C<< MO(%mocks) >>

    # Takes an optional "isa" for extending existing objects
    my $mock = MO(
        isa => 'DateTime',
        now => sub { DateTime->now->add(days => 3) },
    );

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/aanari/Test-Core/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ali Anari.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
