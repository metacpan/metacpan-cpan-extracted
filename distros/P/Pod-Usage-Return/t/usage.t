
$0 = __FILE__;
use Test::More;
use Capture::Tiny qw( capture );
use Pod::Usage::Return qw( pod2usage );

diag "-- VERSIONS --";
diag "Pod::Usage - $Pod::Usage::VERSION";

subtest 'pod2usage( EXITVAL )' => sub {
    my ( $out, $err, $exit ) = capture { pod2usage(0) };
    ok !$err, 'exit < 2 prints on stdout';
    like $out, qr{Usage:}, 'contains SYNOPSIS';
    like $out, qr{Arguments:}, 'contains ARGUMENTS';
    like $out, qr{Options:}, 'contains OPTIONS';
};

subtest 'pod2usage( MESSAGE )' => sub {
    my ( $out, $err, $exit ) = capture { pod2usage("ERROR: An error!") };
    is $exit, 2, 'exit with message is 2';
    ok !$out, 'exit >= 2 prints on stderr';
    like $err, qr{Usage:}, 'contains SYNOPSIS';
    like $err, qr{ERROR: An error!}, 'contains the message';
    unlike $err, qr{Arguments:}, 'does not contains ARGUMENTS';
    unlike $err, qr{Options:}, 'does not contains OPTIONS';
};

subtest 'pod2usage( KEY => VALUE )' => sub {
    my ( $out, $err, $exit ) = capture { pod2usage( -verbose => 0, -exitval => 2 ) };
    is $exit, 2, 'exit with message is 2';
    ok !$out, 'exit >= 2 prints on stderr';
    like $err, qr{Usage:}, 'contains SYNOPSIS';
    unlike $err, qr{Arguments:}, 'does not contains ARGUMENTS';
    unlike $err, qr{Options:}, 'does not contains OPTIONS';
};

subtest 'pod2usage( HASHREF )' => sub {
    my ( $out, $err, $exit ) = capture { pod2usage({ -verbose => 0, -exitval => 2 }) };
    is $exit, 2, 'exit with message is 2';
    ok !$out, 'exit >= 2 prints on stderr';
    like $err, qr{Usage:}, 'contains SYNOPSIS';
    unlike $err, qr{Arguments:}, 'does not contains ARGUMENTS';
    unlike $err, qr{Options:}, 'does not contains OPTIONS';
};

done_testing;

__END__

=head1 NAME

Test - Some test POD matching the standard format

=head1 SYNOPSIS

    test [-o <option>] <argument> [<optionalarg>}
    test -h

=head1 DESCRIPTION

This is some test POD with a description.

=head1 ARGUMENTS

=head2 argument

A required argument

=head2 optionalarg

An optional argument

=head1 OPTIONS

=head2 -o <option>

An option that takes an argument

=head1 AUTHOR

Copyright 2014 - Doug Bell <preaction@cpan.org>

=head1 LICENSE

This fake POD document may be redistributed under the same terms as Perl 5 itself.

